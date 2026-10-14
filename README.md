# ArtunIHA — Windows C++ development

Native **Windows 10/11 x64**, **MSVC 2022**, **CMake**, **vcpkg**, optional **ROS 2 Jazzy (RoboStack/Pixi)** and **MAVSDK C++**. Existing `main.cpp` remains the entry point. All additional C++ files live in `src/`.

## Commands

Open the cloned repository in VS Code and run commands from the project root (PowerShell terminal):

```powershell
./dev setup
./dev install ros2
./dev install mavsdk
./dev install fmt
./dev add navigation.cpp
./dev run
./dev doctor
```

If Windows PowerShell does not resolve `./dev`, use `.\dev.cmd` (same commands). Run `setup` first. It installs missing Git, CMake, VS Code and the Visual Studio **2022 C++ workload** via official winget packages (may need administrator permission), bootstraps vcpkg under `.artun/`, installs VS Code C/C++ and CMake Tools extensions, and configures the project. It **does not** install ROS 2 until you request it; this repo's current source only uses the C++ standard library.

`install ros2` uses **RoboStack Jazzy via Pixi** in project-local `.pixi/`. `install mavsdk` downloads the official newest Windows x64 C++ *release archive* from the MAVSDK GitHub releases and records its version in `mavsdk.version`. A normal `install fmt` adds a vcpkg manifest dependency and reconfigures CMake. Other valid vcpkg port names are accepted; CMake auto-links common packages **fmt, spdlog, nlohmann-json and eigen3**. For other packages, their documented `find_package`/`target_link_libraries` integration may be needed; installing headers alone cannot guarantee linker correctness.

`add name.cpp` only creates `src/name.cpp`. No extra header is generated unless you write one. CMake automatically includes all `src/**/*.cpp` files. `run` performs configure, Release build and executes `main.cpp`'s program. The build will fail normally if C++ code itself has errors.

## VS Code / IntelliSense

Workspace settings use `ms-vscode.cmake-tools` as the C/C++ configuration provider. The included `CMakePresets.json` selects x64 MSVC; toolchain and SDK paths are resolved from the **repository root**, not a developer's username. After installing a package, `dev` triggers CMake reconfiguration; CMake Tools supplies compiler settings and includes. On the **first installation** of VS Code extensions, VS Code may require an extension activation/window reload. No automation can promise that genuinely invalid code or every unsupported third-party package is free of red squiggles.

## Reproducibility / portability

- Commit `vcpkg.json` changes after initial setup: it pins the current vcpkg baseline.
- Commit `pixi.toml` and **`pixi.lock`** after `install ros2` to pin the ROS 2 environment. Do not commit `.pixi/`.
- Commit `mavsdk.version` after `install mavsdk`. Do not commit `.artun/`.
- First setup needs Internet, sufficient disk space, Windows package manager and permission to install build tools; Windows 10/11 differences and third-party compiler ABI constraints may require troubleshooting. The scripts target Windows x64 only, not cross-OS execution.
- ROS 2 is provided by **RoboStack**, not Microsoft's vcpkg, and does not require WSL2. RoboStack has win-64 artifacts, but individual ROS packages may be unavailable or conflict with other prebuilt libraries.
- After adding a new source file, `dev add` reconfigures the build so VS Code picks it up. Re-running `dev setup` is safe.

## Implementation and upstream references

- [vcpkg manifests and version baselines](https://learn.microsoft.com/en-us/vcpkg/users/manifests)
- [VS Code CMake Tools + C/C++ IntelliSense configuration provider](https://code.visualstudio.com/docs/cpp/customize-cpp-settings)
- [RoboStack Pixi installation (Windows)](https://robostack.github.io/GettingStarted.html)
- [Official MAVSDK Windows C++ install](https://mavsdk.mavlink.io/main/en/cpp/quickstart.html)
- [Windows Visual Studio command-line install](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio)

## Scope

These changes provide **development automations only**. No flight-control logic, ROS 2 application code or simulation behavior was changed. Validate the native toolchain on Windows and hardware safety in SITL before operating a drone.
