#pragma once
// Host test shim: no physical GPIO, PWM or clock is accessed.
#include <algorithm>
#include <cstdint>
#include <string>
using String=std::string;
using std::min;
using std::max;
constexpr int OUTPUT=1,HIGH=1,LOW=0;
extern uint32_t testMillis;
extern int testLaserState;
inline uint32_t millis(){return testMillis;}
inline void pinMode(int,int){}
inline void digitalWrite(int,int value){testLaserState=value;}
inline void ledcWrite(int,uint32_t){}
inline void ledcSetup(int,int,int){}
inline void ledcAttachPin(int,int){}
template<class T> T constrain(T value,T lo,T hi){return std::min(hi,std::max(lo,value));}
