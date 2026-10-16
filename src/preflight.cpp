#include "preflight.hpp"

namespace artun {
  bool preflight(mavsdk::Telemetry &telemetry) {
    using Result = mavsdk::Telemetry::Result;

    if(telemetry.set_rate_gps_info(2) != Result::Success ||
      telemetry.set_rate_position(5) != Result::Success ||
      telemetry.set_rate_battery(1) != Result::Success ||
      telemetry.set_rate_in_air(2) != Result::Success){
        std::cerr << "Telemetry setup failed.\n";
        return false;
      }

      for(int i = 0; i < 60; ++i){
        auto gps = telemetry.gps_info();
        auto position = telemetry.position();
        auto home = telemetry.home();
        auto battery = telemetry.battery().remaining_percent;

        if(!telemetry.armed() && 
           !telemetry.in_air() &&
           static_cast<int>(gps.fix_type) >= 3 &&
           std::isfinite(position.latitude_deg) &&
           std::isfinite(position.longitude_deg) &&
           std::isfinite(position.relative_altitude_m) &&
           std::isfinite(home.latitude_deg) &&
           std::isfinite(home.longitude_deg) &&
           std::isfinite(home.absolute_altitude_m) &&
           std::isfinite(battery) &&
           battery >= 70.0f
        ){
          std::cout << "Prefligt Passed" << "\n";
          return true;
        }

        if (i % 5 == 0) {
            std::cout << "Waiting for preflight..."
                      << " GPS: " << static_cast<int>(gps.fix_type)
                      << " | Battery: " << battery << "%\n";
        }
        
        std::this_thread::sleep_for(std::chrono::seconds(1));
      }
      std::cerr << "Preflight failed\n";
      return false;
  }
}
