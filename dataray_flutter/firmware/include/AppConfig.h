#pragma once
#include <Arduino.h>
#ifndef DATARAY_TRANSMITTER
#define DATARAY_TRANSMITTER 1
#endif
namespace Config {
constexpr bool transmitter = DATARAY_TRANSMITTER == 1;
constexpr char service[] = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char command[] = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char events[] = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char info[] = "6e400005-b5a3-f393-e0a9-e50e24dcca9e";
constexpr uint8_t linkLaser = 25; // Transistor/driver input; never power a laser from GPIO.
constexpr uint8_t photodiode = 34; // ADC1, conditioned BPW34 output, 0..3.3 V.
constexpr uint8_t drawingLaser = 26;
constexpr uint8_t servoX = 18;
constexpr uint8_t servoY = 19;
constexpr int threshold = 121;
constexpr int hysteresis = 10;
constexpr bool lightRaisesAdc = true;
constexpr uint32_t bitUs = 10000; // 100 bit/s; generous timing for a first prototype.
constexpr float xMin = 80, xMax = 100, yMin = 80, yMax = 100;
constexpr uint32_t settleMs = 100, dotMs = 30;
constexpr uint32_t robotWatchdogMs = 10000; // Renewed by app heartbeat while drawing.
}
