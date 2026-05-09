# DockNest

DockNest is a small macOS Dock launcher for developer tools. It keeps your Dock clean while still giving you fast access to IDEs, editors, terminals, and developer utilities.

DockNest opens as a lightweight popover anchored around the Dock. It automatically discovers supported applications installed on the system, groups them, and lets you open files or folders by dropping them onto an app tile.

---

## English

### Features

- Dock-friendly launcher popover
- Automatic discovery of developer tools from:
  - `/Applications`
  - `/Applications/Utilities`
  - `/System/Applications`
  - `/System/Applications/Utilities`
  - `~/Applications`
- Automatic grouping:
  - IDE
  - Terminal
- Drag and drop:
  - Open the DockNest popover
  - Drag a file or folder from Finder
  - Drop it onto an app tile
  - DockNest opens that item with the selected app
- In-popover settings page
  - Hide or show discovered applications
  - Preferences are stored locally with `UserDefaults`
- Minimal native macOS UI
- Custom hover tooltip for the settings button
- No telemetry
- No network access
- No background service

### How discovery works

DockNest does not rely on a hardcoded list of applications.

It scans installed `.app` bundles and reads their metadata:

- IDE and developer tools are detected through `LSApplicationCategoryType == public.app-category.developer-tools`
- Terminal apps are detected through shell-related document support metadata, such as:
  - `CFBundleTypeRole == Shell`
  - `com.apple.terminal.shell-script`

This allows DockNest to work with different developer setups without manually maintaining a fixed application list.

### Usage

1. Build and run DockNest.
2. Keep DockNest in the Dock.
3. Click the DockNest icon to open the popover.
4. Click an app tile to launch it.
5. Drag a file or folder onto an app tile to open it with that app.
6. Use the settings button near the section header to hide or show applications.

### Development

Open the project in Xcode:

```bash
open DockNest.xcodeproj
```

Build from the command line:

```bash
xcodebuild -project DockNest.xcodeproj -scheme DockNest -configuration Debug -destination 'platform=macOS' build
```

### Project structure

```text
DockNest/
├── AppDelegate.swift
├── AppLauncher.swift
├── ApplicationDiscovery.swift
├── ContentView.swift
├── InstalledApplication.swift
├── LauncherApplicationViews.swift
├── LauncherPanelController.swift
├── LauncherPanelPlacement.swift
├── LauncherSettingsView.swift
├── LauncherViewModel.swift
└── TooltipSupport.swift
```

### Privacy

DockNest only scans local application bundles to build the launcher list.

It does not:

- Send analytics
- Contact external servers
- Read file contents
- Store sensitive data

Hidden app preferences are stored locally in `UserDefaults`.

### Known limitations

- macOS does not expose a public API for detecting drag-hover over a Dock icon.
- DockNest supports dropping files or folders onto app tiles while the popover is already open.
- Dock tile geometry is not exposed through public APIs, so popover placement is approximated around the active Dock edge.

### License

License information has not been added yet.

---

## Türkçe

DockNest, geliştirici araçları için küçük bir macOS Dock launcher uygulamasıdır. Dock’u sade tutarken IDE, editor, terminal ve geliştirici araçlarına hızlı erişim sağlar.

DockNest, Dock çevresinde hafif bir popover olarak açılır. Sistemde kurulu desteklenen uygulamaları otomatik bulur, gruplar ve dosya/klasörleri seçilen uygulama ile açmak için sürükle-bırak desteği sunar.

### Özellikler

- Dock odaklı launcher popover
- Geliştirici araçlarını otomatik keşfeder:
  - `/Applications`
  - `/Applications/Utilities`
  - `/System/Applications`
  - `/System/Applications/Utilities`
  - `~/Applications`
- Otomatik gruplama:
  - IDE
  - Terminal
- Sürükle-bırak:
  - DockNest popover’ını aç
  - Finder’dan dosya veya klasör sürükle
  - İstediğin uygulama tile’ının üstüne bırak
  - DockNest o öğeyi seçilen uygulama ile açar
- Popover içinde ayarlar sayfası
  - Bulunan uygulamaları gizle veya göster
  - Tercihler `UserDefaults` ile lokal saklanır
- Minimal native macOS arayüzü
- Ayarlar butonu için özel hover tooltip
- Telemetry yok
- Network erişimi yok
- Arka plan servisi yok

### Uygulama keşfi nasıl çalışıyor?

DockNest sabit, hardcoded bir uygulama listesine bağlı değildir.

Sistemdeki `.app` bundle’larını tarar ve metadata okur:

- IDE ve geliştirici araçları `LSApplicationCategoryType == public.app-category.developer-tools` ile algılanır
- Terminal uygulamaları shell destek metadata’sı üzerinden algılanır:
  - `CFBundleTypeRole == Shell`
  - `com.apple.terminal.shell-script`

Bu sayede DockNest farklı kullanıcıların farklı IDE ve terminal kurulumlarında manuel liste gerektirmeden çalışır.

### Kullanım

1. DockNest’i build edip çalıştır.
2. DockNest’i Dock’ta tut.
3. DockNest ikonuna basarak popover’ı aç.
4. Bir uygulama tile’ına basarak uygulamayı başlat.
5. Finder’dan dosya veya klasörü uygulama tile’ının üstüne bırakarak o uygulama ile aç.
6. Section başlığının yanındaki ayarlar butonu ile uygulamaları gizle veya göster.

### Geliştirme

Projeyi Xcode ile aç:

```bash
open DockNest.xcodeproj
```

Komut satırından build al:

```bash
xcodebuild -project DockNest.xcodeproj -scheme DockNest -configuration Debug -destination 'platform=macOS' build
```

### Proje yapısı

```text
DockNest/
├── AppDelegate.swift
├── AppLauncher.swift
├── ApplicationDiscovery.swift
├── ContentView.swift
├── InstalledApplication.swift
├── LauncherApplicationViews.swift
├── LauncherPanelController.swift
├── LauncherPanelPlacement.swift
├── LauncherSettingsView.swift
├── LauncherViewModel.swift
└── TooltipSupport.swift
```

### Gizlilik

DockNest yalnızca launcher listesini oluşturmak için lokal uygulama bundle’larını tarar.

Şunları yapmaz:

- Analytics göndermez
- Harici sunucularla iletişim kurmaz
- Dosya içeriklerini okumaz
- Hassas veri saklamaz

Gizlenen uygulama tercihleri lokal olarak `UserDefaults` içinde saklanır.

### Bilinen sınırlar

- macOS, Dock ikonunun üstünde drag-hover algılamak için public API sunmaz.
- DockNest, popover açıkken dosya veya klasörleri uygulama tile’larının üstüne bırakmayı destekler.
- Dock tile koordinatları public API ile alınamadığı için popover konumu aktif Dock kenarına göre yaklaşık hesaplanır.

### Lisans

Lisans bilgisi henüz eklenmedi.
