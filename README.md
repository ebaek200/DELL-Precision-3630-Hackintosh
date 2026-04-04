# Dell Precision 3630 Hackintosh

**OpenCore EFI for Dell Precision 3630 Workstation**

[![macOS Sequoia](https://img.shields.io/badge/macOS-Sequoia%2015.x-blue)](https://www.apple.com/macos/sequoia/)
[![macOS Ventura](https://img.shields.io/badge/macOS-Ventura%2013.x-blueviolet)](https://www.apple.com/macos/ventura/)
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.7-blue)](https://github.com/acidanthera/OpenCorePkg)
[![Version](https://img.shields.io/badge/Version-2.0.0-green)](https://github.com/ebaek200/DELL-Precision-3630-Hackintosh/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Versions

| Tag | macOS | OpenCore | WiFi | Status |
|-----|-------|----------|------|--------|
| **[sequoia-v2.0.0](https://github.com/ebaek200/DELL-Precision-3630-Hackintosh/releases/tag/sequoia-v2.0.0)** | Sequoia 15.x | 1.0.7 | OC kext injection | **Current** |
| [ventura-v1.0.1](https://github.com/ebaek200/DELL-Precision-3630-Hackintosh/releases/tag/ventura-v1.0.1) | Ventura 13.x | 1.0.2+ | Native (no patches) | Archived |

> **Sequoia** (main branch) requires additional WiFi kexts and config changes compared to Ventura.
> See [Ventura → Sequoia Changes](#ventura--sequoia-changes) below.

---

## Hardware Specs

| Component | Model |
|-----------|-------|
| **CPU** | Intel Xeon E-2136 (Coffee Lake, 6C/12T, 3.3GHz) |
| **Chipset** | Intel C246 |
| **GPU** | AMD Radeon RX 5700 XT (Navi 10, 8GB GDDR6) |
| **Audio** | Realtek ALC255 (ALC3234) |
| **Ethernet** | Intel I219-LM |
| **WiFi** | Broadcom BCM94360 |
| **NVMe** | Samsung MZFLV256 + WD SN530 256GB |
| **RAM** | 32GB DDR4-2666 (4x8GB Samsung) |
| **SMBIOS** | iMacPro1,1 |

## What's Working

| Feature | Ventura 13.x | Sequoia 15.x | Notes |
|---------|:------------:|:------------:|-------|
| macOS Boot | ✅ | ✅ | OpenCore GUI (GoldenGate theme) |
| GPU Acceleration | ✅ | ✅ | RX 5700 XT native + WhateverGreen |
| Audio | ✅ | ✅ | ALC255 layout-id 12 via AppleALC |
| Ethernet | ✅ | ✅ | Intel I219-LM via IntelMausi |
| WiFi | ✅ Native | ✅ OC kext | BCM94360 — Sequoia needs kext injection |
| NVMe | ✅ | ✅ | Both drives detected |
| USB Ports | ✅ | ✅ | 15 ports custom mapped (USBMap.kext) |
| Sleep / Wake | ✅ | ✅ | SSDT-GPRW instant wake fix |
| CPU Power Mgmt | ✅ | ✅ | XCPM via SSDT-PLUG |
| NVRAM | ✅ | ✅ | Native via SSDT-PMC (C246) |
| iServices | ✅ | ✅ | iMessage / FaceTime (with valid SMBIOS) |

---

## EFI Structure

### Sequoia (v2.0.0) — 14 kexts + IOSkywalkFamily block

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── ACPI/
    │   ├── SSDT-PLUG.aml
    │   ├── SSDT-EC-USBX.aml
    │   ├── SSDT-PMC.aml
    │   ├── SSDT-AWAC.aml
    │   ├── SSDT-GPRW.aml
    │   ├── SSDT-SBUS-MCHC.aml
    │   └── src/                        # .dsl source files
    ├── Drivers/
    │   ├── OpenRuntime.efi
    │   ├── HfsPlus.efi
    │   ├── OpenCanopy.efi
    │   └── ResetNvramEntry.efi
    ├── Kexts/
    │   ├── Lilu.kext                   # Kernel patching engine
    │   ├── VirtualSMC.kext             # SMC emulator
    │   ├── SMCProcessor.kext           # CPU temperature
    │   ├── SMCSuperIO.kext             # Fan speed monitoring
    │   ├── WhateverGreen.kext          # GPU patching
    │   ├── AppleALC.kext               # Audio codec (v1.9.7)
    │   ├── IntelMausi.kext             # Intel I219-LM ethernet
    │   ├── NVMeFix.kext                # NVMe power management
    │   ├── USBMap.kext                 # Dell 3630 custom 15-port map
    │   ├── RestrictEvents.kext         # Block unwanted processes
    │   ├── AMFIPass.kext               # ★ Allow unsigned kext loading
    │   ├── IOSkywalkFamily.kext        # ★ OCLP legacy WiFi framework
    │   ├── IO80211FamilyLegacy.kext    # ★ Legacy WiFi stack (AirPortBrcmNIC)
    │   └── AirportBrcmFixup.kext       # ★ Broadcom WiFi patches
    ├── Resources/                      # OpenCanopy theme (GoldenGate)
    ├── Tools/
    └── config.plist
```

### Ventura (v1.0.1) — 10 kexts, no WiFi patches needed

Same structure minus the 4 WiFi kexts (`AMFIPass`, `IOSkywalkFamily`, `IO80211FamilyLegacy`, `AirportBrcmFixup`) and without the IOSkywalkFamily kernel block.

---

## Ventura → Sequoia Changes

### config.plist Differences

| Setting | Ventura (v1.0.1) | Sequoia (v2.0.0) | Reason |
|---------|-----------------|-------------------|--------|
| `SecureBootModel` | Default | **Disabled** | Required for unsigned kext loading |
| `csr-active-config` | 0x00000000 | **0x0803** | SIP partial disable for kext injection |
| `boot-args` | `agdpmod=pikera alcid=12 keepsyms=1 debug=0x100` | + **`amfi=0x80`** | AMFI bypass for WiFi kexts |
| `Kernel > Block` | (none) | **IOSkywalkFamily** (Exclude, MinKernel 23.0.0) | Block native Skywalk to load legacy WiFi |
| `Kernel > Add` | 10 entries | **17 entries** (+7 WiFi) | BCM94360 WiFi support |
| OpenCore | 1.0.2+ | **1.0.7** | Latest stable |
| AppleALC | 1.9.6 | **1.9.7** | Latest stable |

### Added Kexts (Sequoia only)

| Kext | Version | Source | Purpose |
|------|---------|--------|---------|
| AMFIPass | 1.4.1 | [dortania/AMFIPass](https://github.com/dortania/AMFIPass) | Allow unsigned kext loading |
| IOSkywalkFamily | 1.2.0 | OCLP payload | Legacy WiFi compatibility framework |
| IO80211FamilyLegacy | 1.0.0 | OCLP payload | Legacy WiFi stack (contains AirPortBrcmNIC) |
| AirportBrcmFixup | 2.1.9 | [acidanthera/AirportBrcmFixup](https://github.com/acidanthera/AirportBrcmFixup) | Broadcom WiFi device-id patching |

### Why OCLP Root Patch Won't Work on Hackintosh

OCLP 2.4.x detects non-Apple firmware (`firmware-vendor != "Apple"`) and skips root patching entirely (`"Skipping due to hackintosh"`). The solution is **OpenCore kext injection** — placing the legacy WiFi kexts directly in `EFI/OC/Kexts/` so they load at boot time via `config.plist`.

---

## ACPI SSDTs

| SSDT | Purpose |
|------|---------|
| **SSDT-PLUG** | Injects plugin-type=1 for native CPU power management (XCPM/SpeedStep/Turbo) |
| **SSDT-EC-USBX** | Creates fake Embedded Controller + sets USB power properties |
| **SSDT-PMC** | Enables native NVRAM on Intel 300-series (C246) chipsets |
| **SSDT-AWAC** | Disables AWAC clock and enables legacy RTC for macOS |
| **SSDT-GPRW** | Patches GPE 0x6D to prevent instant wake from sleep (Dell 3630) |
| **SSDT-SBUS-MCHC** | Fixes SMBus and Memory Controller Host reporting |

## Boot Arguments

### Sequoia
```
agdpmod=pikera alcid=12 keepsyms=1 debug=0x100 amfi=0x80
```

### Ventura
```
agdpmod=pikera alcid=12 keepsyms=1 debug=0x100
```

| Arg | Purpose |
|-----|---------|
| `agdpmod=pikera` | Fixes black screen on Navi GPUs (RX 5700 XT) |
| `alcid=12` | Audio layout-id for ALC255 |
| `keepsyms=1` | Preserves kernel symbols for panic logs |
| `debug=0x100` | Prevents auto-reboot on kernel panic |
| `amfi=0x80` | **(Sequoia only)** AMFI bypass for unsigned WiFi kexts |

---

## Installation

### 1. Download Kexts & Drivers

```bash
chmod +x download_kexts.sh
./download_kexts.sh
```

Downloads all kexts from GitHub releases. **Note:** `IO80211FamilyLegacy.kext` and `IOSkywalkFamily.kext` must be extracted manually from the OCLP payload (see script output for instructions).

### 2. Compile SSDTs

```bash
cd EFI/OC/ACPI/src
for f in *.dsl; do iasl "$f"; done
mv *.aml ../
```

### 3. Generate SMBIOS

Use [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) to generate unique serial numbers:

```
Model: iMacPro1,1
```

Replace `PLACEHOLDER-CHANGE-ME` values in `config.plist`:
- `SystemSerialNumber`
- `MLB`
- `SystemUUID`

### 4. Dell BIOS Settings

> See [docs/CHECKLIST.txt](docs/CHECKLIST.txt) for the complete BIOS configuration guide.

| Setting | Value |
|---------|-------|
| Boot Mode | UEFI |
| SATA Operation | AHCI |
| Secure Boot | **Disabled** |
| VT-d | Disabled (or use DisableIoMapper quirk) |
| SGX | Disabled |
| Above 4G Decoding | **Enabled** (critical for RX 5700 XT) |
| CFG Lock | Disabled (or use AppleXcpmCfgLock quirk) |

### 5. Install macOS

1. Create macOS installer USB (`createinstallmedia`)
2. Copy `EFI` folder to USB EFI partition
3. Boot from USB (F12 at Dell logo)
4. Install macOS
5. Post-install: copy EFI to internal drive's EFI partition

### 6. Post-Install (Sequoia WiFi)

WiFi should work immediately after boot — kexts are injected by OpenCore at boot time. No OCLP root patching needed.

If WiFi doesn't appear:
1. Verify IOSkywalkFamily is blocked: `kextstat | grep -i skywalk` → should return nothing
2. Verify legacy kexts loaded: `kextstat | grep -i "80211\|brcm"` → should show entries
3. Check amfi boot-arg: `nvram -p | grep boot-args`

### 7. Post-Install Optimization

```bash
sudo pmset -a hibernatemode 0
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
sudo pmset -a womp 0
sudo pmset -a proximitywake 0
sudo pmset -a tcpkeepalive 0
sudo pmset -a powernap 0
```

> See [docs/BOOT-TEST-GUIDE.txt](docs/BOOT-TEST-GUIDE.txt) for the full verification checklist.

---

## USB Port Mapping

Custom `USBMap.kext` with 15 ports mapped for Dell Precision 3630:

- **HS01-HS04** : Front panel USB 2.0/3.0
- **HS07-HS10** : Rear panel USB 2.0/3.0
- **SS01-SS07** : USB 3.0 SuperSpeed ports

## Documentation

| File | Description |
|------|-------------|
| [docs/CHECKLIST.txt](docs/CHECKLIST.txt) | Complete BIOS + install + verification checklist |
| [docs/BOOT-TEST-GUIDE.txt](docs/BOOT-TEST-GUIDE.txt) | Step-by-step boot test & troubleshooting guide |
| [docs/CHANGELOG.txt](docs/CHANGELOG.txt) | Version history and update log |
| [docs/README.txt](docs/README.txt) | Original setup notes and folder structure |
| [download_kexts.sh](download_kexts.sh) | Automated kext/driver download script |

---

## Changelog

### v2.0.0 / sequoia-v2.0.0 (2026-04-05)
- **macOS Sequoia 15.x support**
- OpenCore 1.0.6 → **1.0.7**, AppleALC 1.9.6 → **1.9.7**
- BCM94360 WiFi via OpenCore kext injection (OCLP root patch bypassed on hackintosh)
- Added 4 WiFi kexts: AMFIPass, IOSkywalkFamily, IO80211FamilyLegacy, AirportBrcmFixup
- IOSkywalkFamily kernel block (MinKernel 23.0.0)
- SecureBootModel → Disabled, csr-active-config → 0x0803, amfi=0x80
- Updated download_kexts.sh with WiFi kext sections

### v1.0.1 / ventura-v1.0.1 (2026-03-24)
- Initial public release for **macOS Ventura 13.x**
- OpenCore 1.0.2+ with iMacPro1,1 SMBIOS
- 6 custom SSDTs for Dell Precision 3630 + C246 chipset
- Custom USBMap.kext (15 ports)
- BCM94360 WiFi native (no patches needed)
- Full documentation: BIOS checklist, boot test guide, troubleshooting
- Automated kext download script

### v1.0.0 (2026-03-24)
- Internal build, Ventura 13.x baseline

---

## Credits

- [Acidanthera](https://github.com/acidanthera) — OpenCore, Lilu, WhateverGreen, VirtualSMC, AppleALC, AirportBrcmFixup
- [Dortania](https://dortania.github.io/OpenCore-Install-Guide/) — OpenCore Install Guide, OCLP, AMFIPass
- [corpnewt](https://github.com/corpnewt) — GenSMBIOS, ProperTree

## Disclaimer

This EFI is configured specifically for **Dell Precision 3630** with the hardware listed above. Using it on different hardware may cause issues. Always generate your own SMBIOS serial numbers.

## License

MIT License — See [LICENSE](LICENSE) for details.
