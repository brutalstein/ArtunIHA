cmake_minimum_required(VERSION 3.21)
project(ArtunIHA LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB_RECURSE ARTUN_SOURCES CONFIGURE_DEPENDS "src/*.cpp")
add_executable(ArtunIHA main.cpp ${ARTUN_SOURCES})
target_include_directories(ArtunIHA PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Keep installed headers available to both the compiler and IntelliSense.
if(DEFINED VCPKG_INSTALLED_DIR AND EXISTS "${VCPKG_INSTALLED_DIR}/x64-windows/include")
  target_include_directories(ArtunIHA PRIVATE "${VCPKG_INSTALLED_DIR}/x64-windows/include")
endif()

# Automatically link the most common supported vcpkg packages.
find_package(fmt CONFIG QUIET)
if(fmt_FOUND)
  target_link_libraries(ArtunIHA PRIVATE fmt::fmt)
endif()
find_package(spdlog CONFIG QUIET)
if(spdlog_FOUND)
  target_link_libraries(ArtunIHA PRIVATE spdlog::spdlog)
endif()
find_package(nlohmann_json CONFIG QUIET)
if(nlohmann_json_FOUND)
  target_link_libraries(ArtunIHA PRIVATE nlohmann_json::nlohmann_json)
endif()
find_package(Eigen3 CONFIG QUIET)
if(Eigen3_FOUND)
  target_link_libraries(ArtunIHA PRIVATE Eigen3::Eigen)
endif()

# MAVSDK is distributed as a prebuilt Windows C++ SDK.
find_package(MAVSDK CONFIG QUIET)
if(MAVSDK_FOUND)
  target_link_libraries(ArtunIHA PRIVATE MAVSDK::mavsdk)
endif()

# ROS 2 is optional. 'dev install ros2' creates the Pixi manifest.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/pixi.toml")
  list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/.pixi/envs/default/Library")
  find_package(ament_cmake REQUIRED)
  find_package(rclcpp REQUIRED)
  find_package(std_msgs REQUIRED)
  find_package(std_srvs REQUIRED)
  ament_target_dependencies(ArtunIHA rclcpp std_msgs std_srvs)
endif()
