#pragma once
#include <mavsdk/mavsdk.hpp>
#include <string>
#include <iostream>

namespace artun {
  bool connection(mavsdk::Mavsdk &sdk, std::string adress);
}
