# Dell Precision 3630 Hackintosh

**OpenCore EFI for Dell Precision 3630 Workstation**

[![macOS](https://img.shields.io/badge/macOS-Ventura%2013.x-blueviolet)](https://www.apple.com/macos/ventura/)
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.2+-blue)](https://github.com/acidanthera/OpenCorePkg)
[![Version](https://img.shields.io/badge/Version-1.0.1-green)](https://github.com/ebaek200/DELL-Precision-3630-Hackintosh/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Hardware Specs

| Component | Model |
|-----------|-------|
| **CPU** | Intel Xeon E-2136 (Coffee Lake, 6C/12T, 3.3GHz) |
| **Chipset** | Intel C246 |
| **GPU** | AMD Radeon RX 5700 XT (Navi 10, 8GB GDDR6) |
| **Audio** | Realtek ALC255 (ALC3234) |
| **Ethernet** | Intel I219-LM |
| **WiFi** | Broadcom 802.11ac (native) |
| **NVMe** | Samsung MZFLV256 + WD SN530 256GB |
| **RAM** | 32GB DDR4-2666 (4x8GB Samsung) |
| **SMBIOS** | iMacPro1,1 |

## What's Working

| Feature | Status | Notes |
|---------|--------|-------|
| macOS Boot | OK | OpenCore GUI (GoldenGate theme) |
| GPU Acceleration | OK | RX 5700 XT native + WhateverGreen |
| Audio | OK | ALC255 layout-id 12 via AppleALC |
| Ethernet | OK | Intel I219-LM via IntelMausi |
| WiFi | OK | Broadcom native |
| NVMe | OK | Both drives detected |
| USB Ports | OK | 15 ports custom mapped (USBMap.kext) |
| Sleep / Wake | OK | SSDT-GPRW instant wake fix |
| CPU Power Management | OK | XCPM via SSDT-PLUG |
| NVRAM | OK | Native via SSDT-PMC (C246) |
| iServices | OK | iMessage / FaceTime (with valid SMBIOS) |

## EFI Structure

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── ACPI/
    │   ├── SSDT-PLUG.aml          # CPU power management (XCPM)
    │   ├── SSDT-EC-USBX.aml       # Fake EC + USB power properties
    │   ├── SSDT-PMC.aml           # Native NVRAM (300-series)
    │   ├── SSDT-AWAC.aml          # AWAC → RTC fix
    │   ├── SSDT-GPRW.aml          # Sleep instant wake fix
    │   ├── SSDT-SBUS-MCHC.aml     # SMBus + Memory Controller
    │   └── src/                   # .dsl source files
    ├── Drivers/
    │   ├── OpenRuntime.efi
    │   ├── HfsPlus.efi
    │   ├── OpenCanopy.efi
    │   └── ResetNvramEntry.efi
    ├── Kexts/
    │   ├── Lilu.kext              # Kernel patching engine
    │   ├── VirtualSMC.kext        # SMC emulator
    │   ├── WhateverGreen.kext     # GPU patching
    │   ├── AppleALC.kext          # Audio codec
    │   ├── IntelMausi.kext        # Intel I219-LM ethernet
    │   ├── NVMeFix.kext           # NVMe power management
    │   ├── SMCProcessor.kext      # CPU temperature
    │   ├── SMCSuperIO.kext        # Fan speed monitoring
    │   ├── RestrictEvents.kext    # Block unwanted processes
    │   └── USBMap.kext            # Dell 3630 custom 15-port map
    ├── Resources/                 # OpenCanopy theme (GoldenGate)
    ├── Tools/
    └── config.plist               # OpenCore configuration
```

## ACPI SSDTs

| SSDT | Purpose |
|------|---------|
| **SSDT-PLUG** | Injects plugin-type=1 for native CPU power management (XCPM/SpeedStep/Turbo) |
| **SSDT-EC-USBX** | Creates fake Embedded Controller + sets USB power properties for high-power devices |
| **SSDT-PMC** | Enables native NVRAM on Intel 300-series (C246) chipsets |
| **SSDT-AWAC** | Disables AWAC clock and enables legacy RTC for macOS compatibility |
| **SSDT-GPRW** | Patches GPE 0x6D to prevent instant wake from sleep (critical for Dell 3630) |
| **SSDT-SBUS-MCHC** | Fixes SMBus and Memory Controller Host reporting |

## Installation

### 1. Download Kexts & Drivers

```bash
chmod +x download_kexts.sh
./download_kexts.sh
```

This script automatically downloads the latest versions of all required kexts and drivers from GitHub.

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

**Critical Settings:**

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

1. Create macOS Ventura USB installer
2. Copy `EFI` folder to USB EFI partition
3. Boot from USB (F12 at Dell logo)
4. Install macOS
5. Post-install: copy EFI to internal drive's EFI partition

### 6. Post-Install Verification

```bash
# Sleep optimization
sudo pmset -a hibernatemode 0
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
sudo pmset -a womp 0
sudo pmset -a proximitywake 0
sudo pmset -a tcpkeepalive 0
sudo pmset -a powernap 0

# Verify settings
pmset -g
```

> See [docs/BOOT-TEST-GUIDE.txt](docs/BOOT-TEST-GUIDE.txt) for the full verification checklist.

## Boot Arguments

```
agdpmod=pikera alcid=12 keepsyms=1 debug=0x100
```

| Arg | Purpose |
|-----|---------|
| `agdpmod=pikera` | Fixes black screen on Navi GPUs (RX 5700 XT) |
| `alcid=12` | Audio layout-id for ALC255 |
| `keepsyms=1` | Preserves kernel symbols for panic logs |
| `debug=0x100` | Prevents auto-reboot on kernel panic |

## USB Port Mapping

Custom `USBMap.kext` with 15 ports mapped for Dell Precision 3630:

- **HS01-HS04** : Front panel USB 2.0/3.0
- **HS07-HS10** : Rear panel USB 2.0/3.0
- **SS01-SS07** : USB 3.0 SuperSpeed ports

## Documentation

| File | Description |
|------|-------------|
| [docs/CHECKLIST.txt](docs/CHECKLIST.txt) | Complete BIOS + install + verification checklist (919 lines) |
| [docs/BOOT-TEST-GUIDE.txt](docs/BOOT-TEST-GUIDE.txt) | Step-by-step boot test & troubleshooting guide |
| [docs/CHANGELOG.txt](docs/CHANGELOG.txt) | Version history and update log |
| [docs/README.txt](docs/README.txt) | Original setup notes and folder structure |
| [download_kexts.sh](download_kexts.sh) | Automated kext/driver download script |

## Changelog

### v1.0.1 (2026-03-24)
- Initial public release
- OpenCore 1.0.2+ with iMacPro1,1 SMBIOS
- 6 custom SSDTs for Dell Precision 3630 + C246 chipset
- Custom USBMap.kext (15 ports)
- Full documentation: BIOS checklist, boot test guide, troubleshooting
- Automated kext download script

### v1.0.0 (2026-03-24)
- Internal build, Ventura 13.x baseline

## Credits

- [Acidanthera](https://github.com/acidanthera) - OpenCore, Lilu, WhateverGreen, VirtualSMC, AppleALC
- [Dortania](https://dortania.github.io/OpenCore-Install-Guide/) - OpenCore Install Guide
- [corpnewt](https://github.com/corpnewt) - GenSMBIOS, ProperTree

## Disclaimer

This EFI is configured specifically for **Dell Precision 3630** with the hardware listed above. Using it on different hardware may cause issues. Always generate your own SMBIOS serial numbers.

## License

MIT License - See [LICENSE](LICENSE) for details.
