<div align="center">

# ✈️ ARTUN İHA

### C++ geliştirmeye odaklan. Kurulumu, dosyaları ve derlemeyi `dev` yönetsin.

**Windows 10 / 11 · x64 · VS Code**

![Geliştirme Ortamı](https://img.shields.io/badge/Geliştirme-Ortamı%20Hazır-167D67?style=for-the-badge)
![Bağımlılıklar](https://img.shields.io/badge/Paketler-Otomatik%20Yönetim-2563EB?style=for-the-badge)
![Derleme](https://img.shields.io/badge/Derleme-Tek%20Komut-7C3AED?style=for-the-badge)

</div>

---

## 🚀 Başlamak için tek komut

VS Code'da proje klasörünü aç, terminale şunu yaz:

```powershell
./dev setup
```

Bu komut, C++ geliştirme araçlarını ve gerekli kütüphaneleri kurar; **ROS 2, MAVSDK, CMake ve VS Code IntelliSense** yapılandırmasını hazırlar. Eksik araçları tamamlar, önceden kurulanları yeniden indirmemeye çalışır.

> **İlk kurulum için** internet bağlantısı gerekir. Bazı Windows geliştirme araçlarının kurulumu yönetici izni isteyebilir.

## 🧰 Komutlar

| Komut | Ne yapar? |
|:--|:--|
| `./dev setup` | Bilgisayarı projede C++ geliştirmeye hazırlar. |
| `./dev install ros2` | ROS 2 ortamını kurar veya hazırlar. |
| `./dev install mavsdk` | MAVSDK C++ kütüphanesini kurar. |
| `./dev install fmt` | İstediğin C++ paketini kurar ve uygun olduğunda derlemeye bağlar. `fmt` yerine başka bir paket adı yazabilirsin. |
| `./dev add ornek.cpp` | `src/` içinde `ornek.cpp` ve `ornek.hpp` dosyalarını birlikte oluşturur. |
| `./dev add ornek.cpp --no-header` | Yalnızca `ornek.cpp` oluşturur. |
| `./dev sync` | Eklediğin veya sildiğin dosyalara göre CMake yapılandırmasını yeniler. |
| `./dev run` | Projeyi güncel dosyalarla derler ve kökteki `main.cpp` programını çalıştırır. |
| `./dev doctor` | Geliştirme ortamındaki kurulu araçların durumunu gösterir. |

<details>
<summary><strong>💡 Dosya yönetimi nasıl çalışıyor?</strong></summary>

- `main.cpp`, programın başlangıç dosyasıdır.
- Yeni C++ kodlarını `src/` klasörüne yazarsın.
- Bir `.cpp` dosyasını VS Code'dan elle oluşturabilir veya silebilirsin. `./dev run`, kaynak listesini yeniden kontrol eder; yalnızca yapılandırmayı yenilemek için `./dev sync` kullanabilirsin.
- Başka dosyalardan kullanılacak bir işlev yazıyorsan `.hpp` dosyası işine yarar. `add` komutu bunu senin için oluşturur.

</details>

## ⚡ Tek örnek: Yeni bir modül oluştur ve çalıştır

```powershell
./dev setup
./dev add navigation.cpp
./dev run
```

**Sonuç:** `navigation.cpp` ve `navigation.hpp` otomatik oluşturulur, proje bunları derlemeye dahil eder ve `main.cpp` çalıştırılır.

```text
ArtunIHA/
├── main.cpp
└── src/
    ├── navigation.cpp
    └── navigation.hpp
```

`navigation.hpp` içindeki işlevleri başka bir C++ dosyasında kullanmak için `#include "navigation.hpp"` yazabilirsin.

---

<div align="center">

**Sen kodunu yaz, gerisini `./dev` halletsin.**

<sub>Komutlar proje ana klasöründe çalıştırılır. `./dev` açılmazsa `.\dev.cmd` kullanabilirsin.</sub>

</div>
