#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <atomic>
#include <deque>
#include <cstring>
#include "AppConfig.h"
#include "CommandProtocol.h"
#include "OpticalProtocol.h"
#include "RobotWriter.h"

struct CommandLine { char text[256]; };
struct OpticalEvent { Optical::Result result; bool sent; };
QueueHandle_t commands, txPackets, opticalEvents;
std::atomic<bool> connected{false}, txBusy{false};
std::atomic<int> adcValue{0}, thresholdValue{Config::threshold};
std::atomic<bool> lightValue{false};
std::atomic<uint32_t> framingErrors{0}, droppedEvents{0};
BLECharacteristic* notifications;
RobotWriter robot;
String lastMessage;
String drawingText;
uint32_t lastMessageId = 0, drawingMessageId = 0, canvasId = 0, canvasSequence = 0;
uint32_t packets = 0, crcFailures = 0;
std::deque<String> outgoing;
size_t outgoingOffset = 0;

void emit(const String& json) {
  Serial.println(json);
  if (!connected) return;
  if (outgoing.size() >= 16) { ++droppedEvents; return; }
  outgoing.push_back(json+"\n");
}
void error(const char* message, uint32_t id = 0) {
  emit(String("{\"type\":\"error\",\"id\":")+id+",\"message\":\""+message+"\"}");
}
// Reports commanded plot positions, not camera observations or servo feedback.
// Called only by RobotWriter from the main loop, never from the optical task.
void reportRobotTrace(const char* event, float x, float y, bool complete) {
  const bool start = std::strcmp(event, "start") == 0;
  if (!start) ++canvasSequence;
  String json = String("{\"type\":\"canvas\",\"event\":\"")+event+
    "\",\"id\":"+canvasId+",\"seq\":"+canvasSequence;
  if (start) {
    json += String(",\"source\":\"servo\",\"messageId\":")+drawingMessageId+
      ",\"text\":\""+drawingText+"\"";
  } else if (std::strcmp(event, "point") == 0) {
    json += String(",\"x\":")+String(x, 5)+",\"y\":"+String(y, 5)+",\"down\":true,\"dot\":true";
  } else {
    json += String(",\"complete\":")+(complete ? "true" : "false");
  }
  emit(json+"}");
}
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { connected = true; }
  void onDisconnect(BLEServer*) override { connected = false; }
};
class WriteCallbacks : public BLECharacteristicCallbacks {
  String buffer;
  bool discarding = false;
  void onWrite(BLECharacteristic* characteristic) override {
    auto value = characteristic->getValue();
    for (char c : value) {
      if (c == '\n') {
        if (!discarding && buffer.length()) {
          CommandLine line{};
          buffer.toCharArray(line.text, sizeof(line.text));
          if (xQueueSend(commands, &line, 0) != pdTRUE) ++droppedEvents;
        }
        buffer = ""; discarding = false;
      } else if (!discarding) {
        if (buffer.length() >= 254) { buffer = ""; discarding = true; }
        else buffer += c;
      }
    }
  }
 public:
  void reset() { buffer = ""; discarding = false; }
};
WriteCallbacks* writes;

// Runs separately from BLE notification and servo work. No String allocation
// or BLE operation is performed in this timing-sensitive task.
void opticalTask(void*) {
  Optical::Parser parser;
  uint32_t lastByte = 0, sampleAt = 0;
  bool rxActive = false, lastLight = false;
  uint8_t rxByte = 0, rxBit = 0;
  uint8_t frame[74] = {};
  size_t frameLength = 0, byteIndex = 0;
  uint8_t txBit = 0;
  uint32_t txAt = 0;
  Optical::Packet transmitting{};
  for (;;) {
    uint32_t now = micros();
    if (Config::transmitter) {
      if (!frameLength && xQueueReceive(txPackets, &transmitting, 0) == pdTRUE) {
        frameLength = Optical::encode(transmitting, frame);
        byteIndex = 0; txBit = 0; txAt = now;
      }
      if (frameLength && int32_t(now-txAt) >= 0) {
        if (uint32_t(now-txAt) > Config::bitUs/3) {
          // Abort on a timing overrun rather than emit an ambiguous frame.
          digitalWrite(Config::linkLaser, LOW); frameLength = 0; txBusy = false;
          ++droppedEvents;
        } else {
          bool high = txBit == 0 || (txBit >= 1 && txBit <= 8 &&
            ((frame[byteIndex] >> (txBit-1)) & 1));
          digitalWrite(Config::linkLaser, high ? HIGH : LOW);
          txAt += Config::bitUs;
          if (++txBit == 11) {
            txBit = 0;
            if (++byteIndex == frameLength) {
              digitalWrite(Config::linkLaser, LOW); frameLength = 0; txBusy = false;
              OpticalEvent event{}; event.sent = true; event.result.packet = transmitting;
              if (xQueueSend(opticalEvents, &event, 0) != pdTRUE) ++droppedEvents;
            }
          }
        }
      }
    } else {
      const int adc = analogRead(Config::photodiode);
      adcValue = adc;
      bool light = lightValue;
      const int level = thresholdValue;
      if (adc > level+Config::hysteresis) light = Config::lightRaisesAdc;
      else if (adc < level-Config::hysteresis) light = !Config::lightRaisesAdc;
      lightValue = light;
      if (millis()-lastByte > 1000) parser.reset();
      if (!rxActive && light && !lastLight) {
        rxActive = true; rxBit = 0; rxByte = 0;
        sampleAt = now+Config::bitUs+Config::bitUs/2;
      } else if (rxActive && int32_t(now-sampleAt) >= 0) {
        if (uint32_t(now-sampleAt) > Config::bitUs/3) {
          rxActive = false; parser.reset(); ++framingErrors;
        } else if (rxBit < 8) {
          if (light) rxByte |= 1 << rxBit;
          ++rxBit; sampleAt += Config::bitUs;
        } else {
          rxActive = false;
          if (light) { parser.reset(); ++framingErrors; }
          else {
            lastByte = millis();
            OpticalEvent event{};
            if (parser.feed(rxByte, event.result) &&
                xQueueSend(opticalEvents, &event, 0) != pdTRUE) ++droppedEvents;
          }
        }
      }
      lastLight = light;
    }
    vTaskDelay(1); // 1 ms in the pinned Arduino core; less than 1/3 of bit time.
  }
}

void handleCommand(const char* source) {
  Command c;
  if (!parseCommand(String(source), c)) { error("Invalid command JSON"); return; }
  if (c.cmd == "ping") { robot.keepAlive(); return; }
  if (c.cmd == "stop") { robot.stop(); return; }
  if (c.cmd == "threshold" && !Config::transmitter) {
    if (c.value < 100 || c.value > 3995) { error("Threshold must be 100..3995"); return; }
    thresholdValue = c.value; return;
  }
  if (c.cmd == "draw" && !Config::transmitter) {
    if (!lastMessage.length()) { error("No optical message received yet"); return; }
    if (robot.busy()) { error("Robot is busy"); return; }
    drawingText = lastMessage; drawingMessageId = lastMessageId;
    ++canvasId; canvasSequence = 0;
    robot.start(drawingText); return;
  }
  if ((c.cmd != "send" && c.cmd != "test") || !Config::transmitter || !c.hasId) {
    error("Command not available for this profile", c.id); return;
  }
  if (txBusy) { error("Optical transmitter busy", c.id); return; }
  Optical::Packet packet{};
  packet.kind = c.cmd == "test" ? Optical::test : Optical::message;
  const String text = c.cmd == "test" ? Optical::testPattern : c.text;
  if (!Optical::validText(text.c_str(), text.length())) {
    error("Use 1..64 uppercase ASCII characters", c.id); return;
  }
  packet.id = c.id; packet.length = text.length();
  text.toCharArray(packet.text, sizeof(packet.text));
  txBusy = true;
  if (xQueueSend(txPackets, &packet, 0) != pdTRUE) {
    txBusy = false; error("Optical queue full", c.id);
  }
}
void setup() {
  Serial.begin(115200);
  pinMode(Config::linkLaser, OUTPUT); digitalWrite(Config::linkLaser, LOW);
  pinMode(Config::drawingLaser, OUTPUT); digitalWrite(Config::drawingLaser, LOW);
  if (!Config::transmitter) {
    analogReadResolution(12); analogSetPinAttenuation(Config::photodiode, ADC_11db);
    robot.setTraceCallback(reportRobotTrace);
    robot.begin();
  }
  commands = xQueueCreate(8, sizeof(CommandLine));
  txPackets = xQueueCreate(1, sizeof(Optical::Packet));
  opticalEvents = xQueueCreate(8, sizeof(OpticalEvent));
  configASSERT(commands && txPackets && opticalEvents);
  BLEDevice::init(Config::transmitter ? "DATARAY_TX" : "DATARAY_RX");
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(Config::service);
  notifications = service->createCharacteristic(Config::events, BLECharacteristic::PROPERTY_NOTIFY);
  notifications->addDescriptor(new BLE2902());
  auto command = service->createCharacteristic(Config::command, BLECharacteristic::PROPERTY_WRITE);
  writes = new WriteCallbacks(); command->setCallbacks(writes);
  auto info = service->createCharacteristic(Config::info, BLECharacteristic::PROPERTY_READ);
  info->setValue(Config::transmitter ? "{\"protocol\":1,\"role\":\"tx\"}" : "{\"protocol\":1,\"role\":\"rx\"}");
  service->start();
  auto advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(Config::service);
  advertising->setScanResponse(true); advertising->start();
  const auto task = xTaskCreatePinnedToCore(opticalTask, "optical", 4096, nullptr, 2, nullptr, 1);
  configASSERT(task == pdPASS);
}
void loop() {
  static bool wasConnected = false;
  static uint32_t statusAt = 0, notifyAt = 0;
  const bool online = connected;
  if (wasConnected && !online) {
    robot.stop(); outgoing.clear(); outgoingOffset = 0;
    // onDisconnect already ran in the BLE host task before this cleanup.
    writes->reset(); xQueueReset(commands);
    BLEDevice::startAdvertising();
  }
  wasConnected = online;
  CommandLine command;
  if (xQueueReceive(commands, &command, 0) == pdTRUE) handleCommand(command.text);
  if (!Config::transmitter) robot.tick();
  OpticalEvent event;
  if (xQueueReceive(opticalEvents, &event, 0) == pdTRUE) {
    auto& p = event.result.packet;
    if (event.sent) emit(String("{\"type\":\"tx\",\"id\":")+p.id+"}");
    else {
      if (event.result.crcOk) ++packets; else ++crcFailures;
      if (p.kind == Optical::message && event.result.crcOk && Optical::validText(p.text, p.length)) {
        lastMessage = p.text;
        lastMessageId = p.id;
        emit(String("{\"type\":\"message\",\"id\":")+p.id+",\"text\":\""+p.text+"\"}");
      } else if (p.kind == Optical::test && event.result.bits) {
        emit(String("{\"type\":\"test\",\"id\":")+p.id+",\"bits\":"+event.result.bits+
          ",\"errors\":"+event.result.errors+",\"crcOk\":"+(event.result.crcOk ? "true" : "false")+"}");
      }
    }
  }
  if (online && millis()-statusAt >= 1500) {
    statusAt = millis();
    emit(String("{\"type\":\"status\",\"adc\":")+adcValue.load()+",\"threshold\":"+thresholdValue.load()+
      ",\"light\":"+(lightValue ? "true" : "false")+",\"txBusy\":"+(txBusy ? "true" : "false")+
      ",\"robotBusy\":"+(robot.busy() ? "true" : "false")+",\"packets\":"+packets+
      ",\"crcFailures\":"+crcFailures+",\"framingErrors\":"+framingErrors.load()+
      ",\"droppedEvents\":"+droppedEvents.load()+"}");
  }
  if (online && !outgoing.empty() && millis()-notifyAt >= 8) {
    notifyAt = millis();
    const String& line = outgoing.front();
    const size_t length = min(size_t(20), line.length()-outgoingOffset);
    notifications->setValue(reinterpret_cast<uint8_t*>(const_cast<char*>(line.c_str()+outgoingOffset)), length);
    notifications->notify(); outgoingOffset += length;
    if (outgoingOffset >= line.length()) { outgoing.pop_front(); outgoingOffset = 0; }
  }
  delay(1);
}
