
#pragma once

// C++ Standard Library
#include <iostream>
#include <string>
#include <vector>
#include <array>
#include <memory>
#include <optional>
#include <functional>
#include <algorithm>
#include <cmath>
#include <chrono>
#include <thread>
#include <cstdint>
#include <cstdlib>
#include <mutex>
#include <atomic>
#include <unordered_map>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <limits>

// MAVSDK Core
#include <mavsdk/mavsdk.hpp>

// MAVSDK Flight & Mission
#include <mavsdk/plugins/telemetry/telemetry.hpp>
#include <mavsdk/plugins/action/action.hpp>
#include <mavsdk/plugins/mission_raw/mission_raw.hpp>
#include <mavsdk/plugins/mission/mission.hpp>
#include <mavsdk/plugins/param/param.hpp>

// ROS 2 Core
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>
#include <std_msgs/msg/bool.hpp>
#include <std_msgs/msg/float64_multi_array.hpp>
#include <std_srvs/srv/trigger.hpp>

// Additional MAVSDK plugins (enable when needed)
// #include <mavsdk/plugins/offboard/offboard.hpp>
// #include <mavsdk/plugins/geofence/geofence.hpp>
// #include <mavsdk/plugins/info/info.hpp>
// #include <mavsdk/plugins/calibration/calibration.hpp>
// #include <mavsdk/plugins/mavlink_direct/mavlink_direct.hpp>

// Additional ROS 2 messages (require CMake dependencies)
// #include <sensor_msgs/msg/imu.hpp>
// #include <sensor_msgs/msg/nav_sat_fix.hpp>
// #include <geometry_msgs/msg/pose_stamped.hpp>
// #include <geometry_msgs/msg/twist.hpp>
// #include <nav_msgs/msg/odometry.hpp>
