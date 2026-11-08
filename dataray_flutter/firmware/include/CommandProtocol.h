#pragma once
#include <Arduino.h>
// Deliberately small, bounded, flat JSON command parser. Strings are ASCII and
// may not contain escape sequences; the app normalizes text to this alphabet.
struct Command {
  String cmd, text;
  uint32_t id = 0;
  int value = -1;
  bool hasId = false;
};
inline bool parseCommand(const String& source, Command& result) {
  size_t pos = 0;
  auto spaces = [&]() { while (pos < source.length() && isspace(source[pos])) ++pos; };
  auto take = [&](char c) { spaces(); if (source[pos] != c) return false; ++pos; return true; };
  auto stringValue = [&](String& out) {
    if (!take('"')) return false;
    out = "";
    while (pos < source.length() && source[pos] != '"') {
      const char c = source[pos++];
      if (c < 32 || c > 126 || c == '\\') return false;
      out += c;
    }
    return take('"');
  };
  if (!take('{')) return false;
  uint8_t seen = 0;
  while (true) {
    String key;
    if (!stringValue(key) || !take(':')) return false;
    const uint8_t flag = key == "cmd" ? 1 : key == "text" ? 2 : key == "id" ? 4 : key == "value" ? 8 : 0;
    if (!flag || (seen & flag)) return false;
    seen |= flag;
    if (flag <= 2) {
      if (!stringValue(flag == 1 ? result.cmd : result.text)) return false;
    } else {
      spaces();
      uint64_t number = 0;
      size_t start = pos;
      while (pos < source.length() && isdigit(source[pos])) {
        number = number*10 + (source[pos++]-'0');
        if (number > 0xffffffffULL) return false;
      }
      if (pos == start) return false;
      if (flag == 4) { result.id = number; result.hasId = true; }
      else { if (number > 4095) return false; result.value = number; }
    }
    spaces();
    if (source[pos] == '}') { ++pos; break; }
    if (!take(',')) return false;
  }
  spaces();
  return (seen & 1) && pos == source.length();
}
