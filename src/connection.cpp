#include "connection.hpp"

namespace artun {
  bool connection(mavsdk::Mavsdk &sdk, const std::string &address) {
    auto res = sdk.add_any_connection(address);
    if(res != mavsdk::ConnectionResult::Success){
      std::cerr << "Connection failed: " << res << '\n';
      return false;
    }
    return true;
  }
}
