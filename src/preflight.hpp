#pragma once
#include <mavsdk/plugins/telemetry/telemetry.hpp>
#include <iostream>
#include <cmath>
#include <chrono>
#include <thread>


namespace artun {
  bool preflight(mavsdk::Telemetry &telemetry);
}
