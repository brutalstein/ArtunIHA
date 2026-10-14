cmake_minimum_required(VERSION 3.21)
project(ArtunIHA LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# main.cpp is the only entry point; all additional source files live in src/.
file(GLOB_RECURSE ARTUN_SOURCES CONFIGURE_DEPENDS "src/*.cpp")
add_executable(ArtunIHA main.cpp ${ARTUN_SOURCES})
target_include_directories(ArtunIHA PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Package hints are safely generated from vcpkg usage metadata.
if(DEFINED VCPKG_INSTALLED_DIR AND EXISTS "${VCPKG_INSTALLED_DIR}/x64-windows/include")
  target_include_directories(ArtunIHA PRIVATE "${VCPKG_INSTALLED_DIR}/x64-windows/include")
endif()
include("${CMAKE_CURRENT_SOURCE_DIR}/.artun/autolink.cmake" OPTIONAL)

find_package(MAVSDK CONFIG QUIET)
if(MAVSDK_FOUND)
  target_link_libraries(ArtunIHA PRIVATE MAVSDK::mavsdk)
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/pixi.toml")
  list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/.pixi/envs/default/Library")
  find_package(ament_cmake REQUIRED)
  find_package(rclcpp REQUIRED)
  find_package(std_msgs REQUIRED)
  find_package(std_srvs REQUIRED)
  ament_target_dependencies(ArtunIHA rclcpp std_msgs std_srvs)
endif()
