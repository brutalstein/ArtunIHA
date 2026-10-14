param(
  [Parameter(Position=0)][string]$Action = "help",
  [Parameter(Position=1)][string]$Name = "",
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$state = Join-Path $root ".artun"
$tools = Join-Path $state "tools"
$build = Join-Path $state "build"
$vcpkg = Join-Path $tools "vcpkg"
$manifest = Join-Path $root "vcpkg.json"
$ci = ($Name -eq "--ci" -or $Rest -contains "--ci")

function File-SHA256([string]$path) {
  $stream = [System.IO.File]::OpenRead($path)
  $hasher = [System.Security.Cryptography.SHA256]::Create()
  try {
    return ([System.BitConverter]::ToString($hasher.ComputeHash($stream))).Replace("-", "")
  } finally {
    $hasher.Dispose()
    $stream.Dispose()
  }
}
function Save-Text([string]$path, [string]$contents) {
  [System.IO.File]::WriteAllText($path, $contents, [System.Text.UTF8Encoding]::new($false))
}
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
}
function Tool([string]$name) {
  $found = Get-Command $name -ErrorAction SilentlyContinue
  if ($found) { return $found.Source }
  $pf = [Environment]::GetEnvironmentVariable("ProgramFiles")
  $pf86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
  $candidates = switch ($name) {
    "git"  { (Join-Path $pf "Git\cmd\git.exe") }
    "cmake" { (Join-Path $pf "CMake\bin\cmake.exe") }
    "code" {
      (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd")
      (Join-Path $pf "Microsoft VS Code\bin\code.cmd")
    }
    "pixi" {
      (Join-Path $tools "pixi\pixi.exe")
      (Join-Path $env:USERPROFILE ".pixi\bin\pixi.exe")
    }
    "vswhere" { (Join-Path $pf86 "Microsoft Visual Studio\Installer\vswhere.exe") }
  }
  foreach ($p in $candidates) { if ($p -and (Test-Path $p)) { return $p } }
  return $null
}
function Exec([string]$file, [string[]]$arguments) {
  if (-not $file) { throw "Required executable not found." }
  & $file @arguments
  if ($LASTEXITCODE -ne 0) { throw "Failed ($LASTEXITCODE): $file $($arguments -join ' ')" }
}
function Winget([string]$id, [string]$override = "") {
  $w = Tool "winget"
  if (-not $w) { throw "winget missing. Install App Installer from Microsoft, then rerun ./dev setup." }
  $a = @("install", "--id", $id, "--exact", "--accept-package-agreements",
         "--accept-source-agreements", "--disable-interactivity")
  if ($override) { $a += @("--override", $override) }
  Exec $w $a
  Refresh-Path
}
function Ensure-BuildTools {
  $vswhere = Tool "vswhere"
  if ($vswhere) {
    $path = & $vswhere -latest -version "[17.0,18.0)" -products "*" -requires "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -property installationPath
    if ($path) { return }
  }
  if ($ci) { throw "MSVC 2022 C++ workload missing on CI runner." }
  Write-Host "Installing Visual Studio 2022 C++ Build Tools (may request UAC)..."
  Winget "Microsoft.VisualStudio.2022.BuildTools" "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --norestart"
  $vswhere = Tool "vswhere"
  $path = if ($vswhere) { & $vswhere -latest -version "[17.0,18.0)" -products "*" -requires "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -property installationPath }
  if (-not $path) { throw "MSVC workload not detected. Complete Desktop development with C++ in Visual Studio Installer." }
}
function Ensure-Core {
  if (-not (Tool "git")) { Winget "Git.Git" }
  if (-not (Tool "cmake")) { Winget "Kitware.CMake" }
  Ensure-BuildTools
  if (-not $ci) {
    if (-not (Tool "code")) { Winget "Microsoft.VisualStudioCode" }
    $code = Tool "code"
    if ($code) {
      foreach ($extension in @("ms-vscode.cpptools","ms-vscode.cmake-tools")) {
        Exec $code @("--install-extension", $extension, "--force")
      }
    } else { throw "VS Code CLI not detected; open VS Code once and rerun ./dev setup." }
  }
}
function Ensure-Vcpkg {
  New-Item -Force -ItemType Directory $tools | Out-Null
  $git = Tool "git"
  if (-not (Test-Path (Join-Path $vcpkg ".git"))) {
    Exec $git @("clone", "https://github.com/microsoft/vcpkg.git", $vcpkg)
  }
  $exe = Join-Path $vcpkg "vcpkg.exe"
  if (-not (Test-Path $exe)) {
    Exec (Join-Path $vcpkg "bootstrap-vcpkg.bat") @("-disableMetrics")
  }
  $obj = Get-Content $manifest -Raw | ConvertFrom-Json
  if (-not ($obj.PSObject.Properties.Name -contains "builtin-baseline")) {
    $sha = (& $git -C $vcpkg rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Cannot determine vcpkg registry revision." }
    $obj | Add-Member -NotePropertyName "builtin-baseline" -NotePropertyValue $sha
    Save-Text $manifest (($obj | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
    Write-Host "Pinned vcpkg baseline $sha; commit vcpkg.json for reproducibility."
  }
}
function Ensure-Pixi {
  if (Tool "pixi") { return }
  # Portable official x64 executable: no winget, admin rights or restart required.
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/prefix-dev/pixi/releases/latest" -Headers @{ "User-Agent" = "ArtunIHA-dev" }
  $asset = $release.assets | Where-Object { $_.name -eq "pixi-x86_64-pc-windows-msvc.exe" } | Select-Object -First 1
  if (-not $asset) { throw "Official Pixi x64 Windows executable not found in latest release." }
  $dest = Join-Path $tools "pixi"
  New-Item -Force -ItemType Directory $dest | Out-Null
  $binary = Join-Path $dest "pixi.exe"
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $binary -Headers @{ "User-Agent" = "ArtunIHA-dev" }
  if ($asset.digest -match "^sha256:([0-9a-fA-F]{64})$") {
    $expected = $Matches[1]
    if ((File-SHA256 $binary) -ne $expected) {
      Remove-Item $binary -Force -ErrorAction SilentlyContinue
      throw "Pixi archive checksum failed."
    }
  }
  if (-not (Tool "pixi")) { throw "Portable Pixi could not be installed." }
  Write-Host "Installed official Pixi $($release.tag_name) locally."
}
function Ensure-Ros {
  Ensure-Pixi
  $pixiManifest = Join-Path $root "pixi.toml"
  if (-not (Test-Path $pixiManifest)) {
    $pixiText = @'
[workspace]
name = "artun-iha-ros2"
channels = ["https://prefix.dev/robostack-jazzy", "https://prefix.dev/conda-forge"]
platforms = ["win-64"]

[dependencies]
ros-jazzy-desktop = "*"
'@
    Save-Text $pixiManifest $pixiText
  }
  Exec (Tool "pixi") @("install", "--manifest-path", $pixiManifest)
}
function Ensure-Mavsdk {
  $dest = Join-Path $state "sdk\mavsdk"
  if (Get-ChildItem $dest -Filter "MAVSDKConfig.cmake" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
    Write-Host "MAVSDK already installed." ; return
  }
  $lock = Join-Path $root "mavsdk.version"
  $api = if (Test-Path $lock) {
    "https://api.github.com/repos/mavlink/MAVSDK/releases/tags/$((Get-Content $lock -Raw).Trim())"
  } else { "https://api.github.com/repos/mavlink/MAVSDK/releases/latest" }
  $release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "ArtunIHA-dev" }
  $asset = $release.assets | Where-Object { $_.name -eq "mavsdk-windows-x64.zip" } | Select-Object -First 1
  if (-not $asset) {
    $asset = $release.assets | Where-Object { $_.name -eq "mavsdk-windows-x64-RelWithDebInfo.zip" } | Select-Object -First 1
  }
  if (-not $asset) { throw "No matching Windows x64 C++ MAVSDK archive in the latest official release." }
  New-Item -Force -ItemType Directory $dest | Out-Null
  $archive = Join-Path $state "mavsdk.zip"
  try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive -Headers @{ "User-Agent" = "ArtunIHA-dev" }
    if ($asset.digest -match "^sha256:([0-9a-fA-F]{64})$") {
      $expected = $Matches[1]
      if ((File-SHA256 $archive) -ne $expected) {
        throw "MAVSDK archive checksum failed."
      }
    }
    Expand-Archive -Path $archive -DestinationPath $dest -Force
  } finally { Remove-Item $archive -ErrorAction SilentlyContinue }
  if (-not (Get-ChildItem $dest -Filter "MAVSDKConfig.cmake" -Recurse | Select-Object -First 1)) {
    throw "MAVSDK archive unpacked but MAVSDKConfig.cmake not found."
  }
  Save-Text $lock ($release.tag_name + [Environment]::NewLine)
  Write-Host "Installed official MAVSDK $($release.tag_name); commit mavsdk.version."
}
function Configure {
  $cmake = Tool "cmake"
  if (-not (Test-Path (Join-Path $vcpkg "scripts\buildsystems\vcpkg.cmake"))) {
    throw "Run ./dev setup first."
  }
  $args = @("-S", $root, "-B", $build, "-G", "Visual Studio 17 2022", "-A", "x64",
            "-DCMAKE_TOOLCHAIN_FILE=$vcpkg\scripts\buildsystems\vcpkg.cmake",
            "-DVCPKG_INSTALLED_DIR=$state\vcpkg_installed")
  $prefix = @()
  $rosPrefix = Join-Path $root ".pixi\envs\default\Library"
  if (Test-Path (Join-Path $root "pixi.toml")) {
    if (-not (Test-Path $rosPrefix)) { Ensure-Ros }
    $prefix += $rosPrefix
  }
  $mavRoot = Join-Path $state "sdk\mavsdk"
  if (Test-Path $mavRoot) {
    $sdkCmake = Get-ChildItem $mavRoot -Filter "MAVSDKConfig.cmake" -Recurse | Select-Object -First 1
    if ($sdkCmake) { $args += "-DMAVSDK_DIR=$($sdkCmake.DirectoryName)" }
  }
  if ($prefix.Count) { $args += "-DCMAKE_PREFIX_PATH=$($prefix -join ';')" }
  if (Test-Path (Join-Path $root "pixi.toml")) {
    Exec (Tool "pixi") (@("run", "--manifest-path", (Join-Path $root "pixi.toml"), "--", $cmake) + $args)
  } else { Exec $cmake $args }
}
function Run-App {
  Configure
  $cmake = Tool "cmake"
  if (Test-Path (Join-Path $root "pixi.toml")) {
    Exec (Tool "pixi") @("run", "--manifest-path", (Join-Path $root "pixi.toml"), "--", $cmake, "--build", $build, "--config", "Release", "--parallel")
  } else { Exec $cmake @("--build", $build, "--config", "Release", "--parallel") }
  $exe = Join-Path $build "Release\ArtunIHA.exe"
  if (-not (Test-Path $exe)) { throw "Executable missing: $exe" }
  $sdk = Join-Path $state "sdk\mavsdk"
  $oldPath = $env:Path
  try {
    if (Test-Path $sdk) {
      $bins = Get-ChildItem $sdk -Directory -Recurse | Where-Object { $_.Name -eq "bin" }
      foreach ($b in $bins) { $env:Path = $b.FullName + ";" + $env:Path }
    }
    if (Test-Path (Join-Path $root "pixi.toml")) {
      Exec (Tool "pixi") @("run", "--manifest-path", (Join-Path $root "pixi.toml"), "--", $exe)
    } else { Exec $exe @() }
  } finally { $env:Path = $oldPath }
}
try {
  switch ($Action.ToLowerInvariant()) {
    "setup" {
      Ensure-Core
      Ensure-Vcpkg
      if (Test-Path (Join-Path $root "pixi.toml")) { Ensure-Ros }
      if (-not $ci) {
        Ensure-Mavsdk
        Ensure-Ros
      } else {
        if (Test-Path (Join-Path $root "mavsdk.version")) { Ensure-Mavsdk }
      }
      Configure
      Write-Host "Setup ready. VS Code CMake Tools provides IntelliSense; use ./dev run."
    }
    "install" {
      if (-not $Name) { throw "Usage: ./dev install <ros2|mavsdk|vcpkg-port>" }
      if (-not (Test-Path (Join-Path $vcpkg "vcpkg.exe"))) { throw "Run ./dev setup first." }
      switch ($Name.ToLowerInvariant()) {
        { $_ -in @("ros","ros2") } { Ensure-Ros; break }
        "mavsdk" { Ensure-Mavsdk; break }
        default {
          if ($Name -notmatch "^[a-z0-9][a-z0-9-]*$") { throw "Invalid vcpkg package name." }
          $obj = Get-Content $manifest -Raw | ConvertFrom-Json
          $names = @($obj.dependencies | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } })
          if ($names -notcontains $Name) {
            $obj.dependencies = @($obj.dependencies) + @($Name)
            Save-Text $manifest (($obj | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
          }
        }
      }
      Configure
      Write-Host "Installed $Name. IntelliSense configuration refreshed."
    }
    "add" {
      if ($Name -notmatch "^[A-Za-z_][A-Za-z0-9_-]*\.cpp$") {
        throw "Usage: ./dev add example.cpp (a file name only; all code lives in src/)"
      }
      $dest = Join-Path $root "src\$Name"
      if (Test-Path $dest) { throw "Already exists: $Name" }
      Save-Text $dest "// $Name`n"
      if (Test-Path (Join-Path $vcpkg "vcpkg.exe")) { Configure }
      Write-Host "Created src/$Name (included automatically by CMake)."
    }
    "run" { Run-App }
    "doctor" {
      Write-Host "Windows: $([Environment]::OSVersion.VersionString)"
      foreach ($name in @("winget","git","cmake","code","pixi","vswhere")) { Write-Host "$name : $(Tool $name)" }
      Write-Host "vcpkg: $(Test-Path (Join-Path $vcpkg 'vcpkg.exe'))"
      Write-Host "ROS 2 environment: $(Test-Path (Join-Path $root '.pixi\envs\default'))"
    }
    default { Write-Host "Commands: ./dev setup | install <ros2|mavsdk|port> | add <name.cpp> | run | doctor" }
  }
} catch {
  Write-Error $_
  exit 1
}
