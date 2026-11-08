#include "RobotWriter.h"
#include <cassert>
#include <cstring>
#include <cstdio>
#include <vector>
uint32_t testMillis=0;
int testLaserState=0;
struct Event {String kind;float x,y;bool complete;};
std::vector<Event> events;
void trace(const char* kind,float x,float y,bool complete){events.push_back({kind,x,y,complete});}
int main(){
  RobotWriter robot;
  robot.setTraceCallback(trace);robot.begin();robot.start("A");
  assert(events.size()==1 && events[0].kind=="start");
  for(int i=0;i<10000 && robot.busy();++i){testMillis+=10;robot.keepAlive();robot.tick();}
  assert(!robot.busy() && testLaserState==LOW);
  assert(events.back().kind=="end" && events.back().complete);
  int points=0;
  for(const auto& e:events){if(e.kind=="point"){
    assert(e.x>=0 && e.x<=1 && e.y>=0 && e.y<=1);++points;
  }}
  assert(points==18); // Exact A bitmap in RobotWriter.h.
  events.clear();robot.start("HOLA");testMillis+=110;robot.tick();testMillis+=110;robot.tick();robot.stop();
  assert(events.back().kind=="end" && !events.back().complete && !robot.busy());
  events.clear();robot.start("HOLA");testMillis+=Config::robotWatchdogMs+1;robot.tick();
  assert(events.back().kind=="end" && !events.back().complete && testLaserState==LOW);
  puts("PASS: production RobotWriter emits start/18 A dots/complete, stop and watchdog interrupt; normalized coordinates");
}
