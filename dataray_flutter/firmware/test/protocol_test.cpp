// Host-side tests of the exact production optical packet implementation.
// Build with a C++11+ compiler, include path ../include. No ESP32 needed.
#include "OpticalProtocol.h"
#include <assert.h>
#include <stdio.h>

bool parse(const uint8_t* data, size_t count, Optical::Result& result) {
  Optical::Parser parser;
  bool complete = false;
  for (size_t i = 0; i < count; ++i) complete = parser.feed(data[i], result) || complete;
  return complete;
}
int main() {
  const uint8_t known[] = {'1','2','3','4','5','6','7','8','9'};
  assert(Optical::crc16(known, 9) == 0x29b1);
  Optical::Packet packet{};
  packet.kind = Optical::message; packet.id = 0x12345678; packet.length = 64;
  memset(packet.text, 'A', 64);
  uint8_t wire[74];
  assert(Optical::encode(packet, wire) == 74);
  Optical::Result result{};
  assert(parse(wire, 74, result));
  assert(result.crcOk && result.packet.id == packet.id && result.packet.length == 64);
  assert(memcmp(result.packet.text, packet.text, 64) == 0);
  wire[20] ^= 1;
  assert(parse(wire, 74, result) && !result.crcOk);
  wire[7] = 65;
  assert(!parse(wire, 74, result));
  packet.kind = Optical::test;
  packet.length = sizeof(Optical::testPattern)-1;
  memcpy(packet.text, Optical::testPattern, packet.length);
  size_t count = Optical::encode(packet, wire);
  assert(parse(wire, count, result) && result.bits == 184 && result.errors == 0 && result.crcOk);
  wire[8] ^= 0x05;
  assert(parse(wire, count, result) && result.errors == 2 && !result.crcOk);
  Optical::Parser parser;
  for (int i = 0; i < 5; ++i) parser.feed(wire[i], result);
  parser.reset();
  bool completed = false;
  for (size_t i = 0; i < count; ++i) completed = parser.feed(wire[i], result) || completed;
  assert(completed && result.errors == 2);
  assert(!Optical::validText("bad", 3));
  assert(Optical::validText("HOLA 123!?.,-", 12));
  puts("PASS: CRC reference, 64-byte frame, corruption, bounds, measured bit errors, resynchronization, alphabet");
}

