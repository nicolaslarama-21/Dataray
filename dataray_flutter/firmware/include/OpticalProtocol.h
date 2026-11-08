#pragma once
#include <stdint.h>
#include <stddef.h>
#include <string.h>
namespace Optical {
constexpr size_t maxText = 64;
constexpr char testPattern[] = "DATARAY TEST 0123456789";
constexpr uint8_t message = 1, test = 2;
struct Packet { uint8_t kind; uint32_t id; uint8_t length; char text[65]; };
inline uint16_t crc16(const uint8_t* data, size_t length) {
  uint16_t crc = 0xffff;
  for (size_t i = 0; i < length; ++i) {
    crc ^= uint16_t(data[i]) << 8;
    for (int bit = 0; bit < 8; ++bit)
      crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : crc << 1;
  }
  return crc;
}
inline bool validText(const char* text, size_t n) {
  if (!n || n > maxText) return false;
  for (size_t i = 0; i < n; ++i) {
    char c = text[i];
    if (!((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
        c == ' ' || c == '.' || c == ',' || c == '!' || c == '?' || c == '-')) return false;
  }
  return true;
}
inline size_t encode(const Packet& p, uint8_t* out) {
  out[0] = 0xd3; out[1] = 0x91; out[2] = p.kind;
  for (int i = 0; i < 4; ++i) out[3+i] = (p.id >> (i*8)) & 0xff;
  out[7] = p.length;
  memcpy(out+8, p.text, p.length);
  const uint16_t crc = crc16(out+2, 6+p.length);
  out[8+p.length] = crc & 0xff; out[9+p.length] = crc >> 8;
  return 10+p.length;
}
struct Result { Packet packet; bool crcOk; uint16_t bits; uint16_t errors; };
class Parser {
  uint8_t buffer[74] = {};
  size_t used = 0;
 public:
  void reset() { used = 0; }
  bool feed(uint8_t byte, Result& result) {
    if (used == 0 && byte != 0xd3) return false;
    if (used == 1 && byte != 0x91) { used = byte == 0xd3 ? 1 : 0; return false; }
    buffer[used++] = byte;
    if (used == 8 && (buffer[7] == 0 || buffer[7] > maxText ||
        (buffer[2] != message && buffer[2] != test))) { reset(); return false; }
    if (used < 8 || used != size_t(10+buffer[7])) return false;
    const size_t n = buffer[7];
    auto& p = result.packet;
    p.kind = buffer[2]; p.length = static_cast<uint8_t>(n); p.id = 0;
    for (int i = 0; i < 4; ++i) p.id |= uint32_t(buffer[3+i]) << (8*i);
    memcpy(p.text, buffer+8, n); p.text[n] = 0;
    result.crcOk = crc16(buffer+2, 6+n) == uint16_t(buffer[8+n] | (uint16_t(buffer[9+n]) << 8));
    result.bits = 0; result.errors = 0;
    if (p.kind == test && n == sizeof(testPattern)-1) {
      result.bits = static_cast<uint16_t>(n*8);
      for (size_t i = 0; i < n; ++i) {
        uint8_t diff = uint8_t(p.text[i]) ^ uint8_t(testPattern[i]);
        for (; diff; diff >>= 1) result.errors += diff & 1;
      }
    }
    reset(); return true;
  }
};
}

