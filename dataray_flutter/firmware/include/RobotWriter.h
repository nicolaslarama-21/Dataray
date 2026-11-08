#pragma once
#include <Arduino.h>
#include "AppConfig.h"

class RobotWriter {
  // 5x7 column bitmap font, ASCII A-Z and 0-9.
  const uint8_t font[36][5] = {
    {0x7e,0x11,0x11,0x11,0x7e},{0x7f,0x49,0x49,0x49,0x36},
    {0x3e,0x41,0x41,0x41,0x22},{0x7f,0x41,0x41,0x22,0x1c},
    {0x7f,0x49,0x49,0x49,0x41},{0x7f,0x09,0x09,0x09,0x01},
    {0x3e,0x41,0x49,0x49,0x7a},{0x7f,0x08,0x08,0x08,0x7f},
    {0x00,0x41,0x7f,0x41,0x00},{0x20,0x40,0x41,0x3f,0x01},
    {0x7f,0x08,0x14,0x22,0x41},{0x7f,0x40,0x40,0x40,0x40},
    {0x7f,0x02,0x0c,0x02,0x7f},{0x7f,0x04,0x08,0x10,0x7f},
    {0x3e,0x41,0x41,0x41,0x3e},{0x7f,0x09,0x09,0x09,0x06},
    {0x3e,0x41,0x51,0x21,0x5e},{0x7f,0x09,0x19,0x29,0x46},
    {0x46,0x49,0x49,0x49,0x31},{0x01,0x01,0x7f,0x01,0x01},
    {0x3f,0x40,0x40,0x40,0x3f},{0x1f,0x20,0x40,0x20,0x1f},
    {0x3f,0x40,0x38,0x40,0x3f},{0x63,0x14,0x08,0x14,0x63},
    {0x07,0x08,0x70,0x08,0x07},{0x61,0x51,0x49,0x45,0x43},
    {0x3e,0x51,0x49,0x45,0x3e},{0x00,0x42,0x7f,0x40,0x00},
    {0x42,0x61,0x51,0x49,0x46},{0x21,0x41,0x45,0x4b,0x31},
    {0x18,0x14,0x12,0x7f,0x10},{0x27,0x45,0x45,0x45,0x39},
    {0x3c,0x4a,0x49,0x49,0x30},{0x01,0x71,0x09,0x05,0x03},
    {0x36,0x49,0x49,0x49,0x36},{0x06,0x49,0x49,0x29,0x1e}
  };
  String text;
  size_t cursor = 0;
  int phase = 0;
  uint32_t next = 0, heartbeat = 0;
  bool active = false;
  using TraceCallback = void (*)(const char*, float, float, bool);
  TraceCallback trace = nullptr;
  float pointX = 0, pointY = 0;
  void angle(int channel, float degrees) {
    degrees = constrain(degrees, 0.0f, 180.0f);
    // Conservative servo pulse range 1000..2000 us, 50 Hz, 16-bit resolution.
    const float pulse = 1000.0f + degrees / 180.0f * 1000.0f;
    ledcWrite(channel, uint32_t(pulse * 65535.0f / 20000.0f));
  }
  bool pixel(char c, int x, int y) const {
    const int index = c >= 'A' && c <= 'Z' ? c-'A' : c >= '0' && c <= '9' ? 26+c-'0' : -1;
    if (index >= 0) return font[index][x] & (1 << y);
    if (c == '.') return x == 2 && y == 6;
    if (c == ',') return (x == 2 && y == 5) || (x == 1 && y == 6);
    if (c == '-') return y == 3 && x >= 1 && x <= 3;
    if (c == '!') return x == 2 && (y < 4 || y == 6);
    if (c == '?') { const uint8_t bits[5] = {2,1,0x51,9,6}; return bits[x] & (1 << y); }
    return false;
  }
 public:
  void setTraceCallback(TraceCallback callback) { trace = callback; }
  void begin() {
    pinMode(Config::drawingLaser, OUTPUT); stop();
    ledcSetup(0, 50, 16); ledcSetup(1, 50, 16);
    ledcAttachPin(Config::servoX, 0); ledcAttachPin(Config::servoY, 1);
    angle(0, (Config::xMin+Config::xMax)/2); angle(1, (Config::yMin+Config::yMax)/2);
  }
  bool busy() const { return active; }
  void keepAlive() { heartbeat = millis(); }
  void stop(bool complete = false) {
    const bool wasActive = active;
    digitalWrite(Config::drawingLaser, LOW); active = false; phase = 0;
    if (wasActive && trace) trace("end", pointX, pointY, complete);
  }
  void start(const String& value) {
    stop(); text = value; cursor = 0; next = millis(); keepAlive(); active = text.length() > 0;
    if (active && trace) trace("start", 0, 0, false);
  }
  void tick() {
    if (!active) return;
    if (millis()-heartbeat > Config::robotWatchdogMs) { stop(); return; }
    if (int32_t(millis()-next) < 0) return;
    if (phase == 1) {
      digitalWrite(Config::drawingLaser, HIGH);
      if (trace) trace("point", pointX, pointY, false);
      phase = 2; next = millis()+Config::dotMs; return;
    }
    digitalWrite(Config::drawingLaser, LOW);
    const size_t total = text.length()*35;
    // Skip dark pixels without moving. At most 2240 bounded iterations.
    while (cursor < total) {
      const size_t ch = cursor/35;
      const int x = (cursor%35)/7, y = cursor%7;
      ++cursor;
      if (!pixel(text[ch], x, y)) continue;
      const int rows = static_cast<int>((text.length()+7)/8);
      const float px = float((ch%8)*6+x)/46.0f;
      const float py = float((ch/8)*9+y)/max(6, rows*9-3);
      pointX = px; pointY = py;
      angle(0, Config::xMin+px*(Config::xMax-Config::xMin));
      angle(1, Config::yMin+py*(Config::yMax-Config::yMin));
      phase = 1; next = millis()+Config::settleMs; return;
    }
    stop(true);
  }
};
