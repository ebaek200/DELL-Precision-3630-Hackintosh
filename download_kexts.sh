#!/bin/bash
#
# download_kexts.sh
# Downloads all required OpenCore components for Dell Precision 3630 Hackintosh (macOS Sequoia 15)
# Run on macOS or any system with curl, unzip, and jq available.
#
# To create Sequoia installer USB:
# sudo /Applications/Install\ macOS\ Sequoia.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume
#
# Minimum versions for Sequoia 15:
# Lilu 1.7.0+, VirtualSMC 1.3.4+, WhateverGreen 1.6.8+, AppleALC 1.9.2+
#

set -e

##############################################################################
# Configuration
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EFI_DIR="${SCRIPT_DIR}/EFI"
OC_DIR="${EFI_DIR}/OC"
KEXTS_DIR="${OC_DIR}/Kexts"
DRIVERS_DIR="${OC_DIR}/Drivers"
BOOT_DIR="${EFI_DIR}/BOOT"
TEMP_DIR="${SCRIPT_DIR}/.dl_temp_$$"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
DOWNLOADED=0
FAILED=0
SUMMARY=""

##############################################################################
# Helper functions
##############################################################################

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_err()   { echo -e "${RED}[FAIL]${NC}  $1"; }

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# get_latest_release_url <owner/repo> [asset_pattern]
# Fetches the browser_download_url for the first asset matching the pattern
# from the latest GitHub release.
get_latest_release_url() {
    local repo="$1"
    local pattern="$2"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"

    log_info "Querying latest release for ${repo}..."

    local release_json
    release_json=$(curl -sL -H "Accept: application/vnd.github+json" "$api_url")

    if echo "$release_json" | grep -q '"message"' 2>/dev/null; then
        local msg
        msg=$(echo "$release_json" | grep '"message"' | head -1)
        log_err "GitHub API error for ${repo}: ${msg}"
        return 1
    fi

    local url
    # Use grep + sed to avoid jq dependency
    url=$(echo "$release_json" \
        | grep -o '"browser_download_url": *"[^"]*"' \
        | sed 's/"browser_download_url": *"//;s/"$//' \
        | grep -i "$pattern" \
        | head -1)

    if [ -z "$url" ]; then
        log_err "No asset matching '${pattern}' found for ${repo}"
        return 1
    fi

    echo "$url"
}

# download_and_extract <url> <subdir_name>
# Downloads a zip to TEMP_DIR and extracts it into TEMP_DIR/<subdir_name>/
download_and_extract() {
    local url="$1"
    local name="$2"
    local zip_file="${TEMP_DIR}/${name}.zip"
    local extract_dir="${TEMP_DIR}/${name}"

    log_info "Downloading ${name} from ${url}..."

    if ! curl -sL -o "$zip_file" "$url"; then
        log_err "Failed to download ${name}"
        FAILED=$((FAILED + 1))
        return 1
    fi

    if [ ! -s "$zip_file" ]; then
        log_err "Downloaded file is empty: ${name}"
        FAILED=$((FAILED + 1))
        return 1
    fi

    mkdir -p "$extract_dir"

    if ! unzip -q -o "$zip_file" -d "$extract_dir"; then
        log_err "Failed to unzip ${name}"
        FAILED=$((FAILED + 1))
        return 1
    fi

    log_ok "Extracted ${name}"
    DOWNLOADED=$((DOWNLOADED + 1))
    return 0
}

# copy_kext <source_kext_path> <kext_name>
copy_kext() {
    local src="$1"
    local name="$2"

    if [ -d "$src" ]; then
        cp -R "$src" "${KEXTS_DIR}/"
        log_ok "Installed ${name} -> Kexts/"
        SUMMARY="${SUMMARY}\n  ${GREEN}[OK]${NC} ${name} -> EFI/OC/Kexts/"
    else
        log_err "Could not find ${name} at ${src}"
        SUMMARY="${SUMMARY}\n  ${RED}[FAIL]${NC} ${name} not found"
        FAILED=$((FAILED + 1))
    fi
}

# copy_efi <source_efi_path> <dest_dir> <file_name>
copy_efi() {
    local src="$1"
    local dest_dir="$2"
    local name="$3"

    if [ -f "$src" ]; then
        cp "$src" "${dest_dir}/"
        log_ok "Installed ${name} -> $(basename "$dest_dir")/"
        SUMMARY="${SUMMARY}\n  ${GREEN}[OK]${NC} ${name} -> ${dest_dir#${SCRIPT_DIR}/}"
    else
        log_err "Could not find ${name} at ${src}"
        SUMMARY="${SUMMARY}\n  ${RED}[FAIL]${NC} ${name} not found"
        FAILED=$((FAILED + 1))
    fi
}

# find_file <base_dir> <filename>
# Recursively finds a file and prints its path
find_file() {
    find "$1" -name "$2" -type f 2>/dev/null | head -1
}

# find_dir <base_dir> <dirname>
# Recursively finds a directory and prints its path
find_dir() {
    find "$1" -name "$2" -type d 2>/dev/null | head -1
}

##############################################################################
# Main
##############################################################################

echo ""
echo "============================================================"
echo "  OpenCore Kext & EFI Downloader"
echo "  Target: Dell Precision 3630 - macOS Sequoia 15"
echo "============================================================"
echo ""

# Check dependencies
for cmd in curl unzip; do
    if ! command -v "$cmd" &>/dev/null; then
        log_err "Required command '${cmd}' not found. Please install it."
        exit 1
    fi
done

# Create directory structure
log_info "Creating EFI directory structure..."
mkdir -p "$KEXTS_DIR" "$DRIVERS_DIR" "$BOOT_DIR" "$TEMP_DIR"
log_ok "Directories created"
echo ""

##############################################################################
# 1. OpenCorePkg
##############################################################################

log_info "=== OpenCorePkg ==="
OC_URL=$(get_latest_release_url "acidanthera/OpenCorePkg" "RELEASE.zip") || true

if [ -n "$OC_URL" ]; then
    if download_and_extract "$OC_URL" "OpenCorePkg"; then
        OC_BASE="${TEMP_DIR}/OpenCorePkg"

        # BOOTx64.efi -> EFI/BOOT/
        src=$(find_file "$OC_BASE" "BOOTx64.efi")
        copy_efi "$src" "$BOOT_DIR" "BOOTx64.efi"

        # OpenCore.efi -> EFI/OC/
        src=$(find_file "$OC_BASE" "OpenCore.efi")
        copy_efi "$src" "$OC_DIR" "OpenCore.efi"

        # OpenRuntime.efi -> EFI/OC/Drivers/
        src=$(find_file "$OC_BASE" "OpenRuntime.efi")
        copy_efi "$src" "$DRIVERS_DIR" "OpenRuntime.efi"

        # OpenCanopy.efi -> EFI/OC/Drivers/
        src=$(find_file "$OC_BASE" "OpenCanopy.efi")
        copy_efi "$src" "$DRIVERS_DIR" "OpenCanopy.efi"

        # ResetNvramEntry.efi -> EFI/OC/Drivers/
        src=$(find_file "$OC_BASE" "ResetNvramEntry.efi")
        copy_efi "$src" "$DRIVERS_DIR" "ResetNvramEntry.efi"
    fi
else
    log_err "Skipping OpenCorePkg (could not resolve URL)"
fi
echo ""

##############################################################################
# 2. Lilu.kext
##############################################################################

log_info "=== Lilu ==="
LILU_URL=$(get_latest_release_url "acidanthera/Lilu" "RELEASE.zip") || true

if [ -n "$LILU_URL" ]; then
    if download_and_extract "$LILU_URL" "Lilu"; then
        src=$(find_dir "${TEMP_DIR}/Lilu" "Lilu.kext")
        copy_kext "$src" "Lilu.kext"
    fi
else
    log_err "Skipping Lilu (could not resolve URL)"
fi
echo ""

##############################################################################
# 3. VirtualSMC (VirtualSMC.kext, SMCProcessor.kext, SMCSuperIO.kext)
##############################################################################

log_info "=== VirtualSMC ==="
VSMC_URL=$(get_latest_release_url "acidanthera/VirtualSMC" "RELEASE.zip") || true

if [ -n "$VSMC_URL" ]; then
    if download_and_extract "$VSMC_URL" "VirtualSMC"; then
        BASE="${TEMP_DIR}/VirtualSMC"

        src=$(find_dir "$BASE" "VirtualSMC.kext")
        copy_kext "$src" "VirtualSMC.kext"

        src=$(find_dir "$BASE" "SMCProcessor.kext")
        copy_kext "$src" "SMCProcessor.kext"

        src=$(find_dir "$BASE" "SMCSuperIO.kext")
        copy_kext "$src" "SMCSuperIO.kext"
    fi
else
    log_err "Skipping VirtualSMC (could not resolve URL)"
fi
echo ""

##############################################################################
# 4. WhateverGreen.kext
##############################################################################

log_info "=== WhateverGreen ==="
WEG_URL=$(get_latest_release_url "acidanthera/WhateverGreen" "RELEASE.zip") || true

if [ -n "$WEG_URL" ]; then
    if download_and_extract "$WEG_URL" "WhateverGreen"; then
        src=$(find_dir "${TEMP_DIR}/WhateverGreen" "WhateverGreen.kext")
        copy_kext "$src" "WhateverGreen.kext"
    fi
else
    log_err "Skipping WhateverGreen (could not resolve URL)"
fi
echo ""

##############################################################################
# 5. AppleALC.kext
##############################################################################

log_info "=== AppleALC ==="
ALC_URL=$(get_latest_release_url "acidanthera/AppleALC" "RELEASE.zip") || true

if [ -n "$ALC_URL" ]; then
    if download_and_extract "$ALC_URL" "AppleALC"; then
        src=$(find_dir "${TEMP_DIR}/AppleALC" "AppleALC.kext")
        copy_kext "$src" "AppleALC.kext"
    fi
else
    log_err "Skipping AppleALC (could not resolve URL)"
fi
echo ""

##############################################################################
# 6. IntelMausi.kext
##############################################################################

log_info "=== IntelMausi ==="
MAUSI_URL=$(get_latest_release_url "acidanthera/IntelMausi" "RELEASE.zip") || true

if [ -n "$MAUSI_URL" ]; then
    if download_and_extract "$MAUSI_URL" "IntelMausi"; then
        src=$(find_dir "${TEMP_DIR}/IntelMausi" "IntelMausi.kext")
        copy_kext "$src" "IntelMausi.kext"
    fi
else
    log_err "Skipping IntelMausi (could not resolve URL)"
fi
echo ""

##############################################################################
# 7. NVMeFix.kext
##############################################################################

log_info "=== NVMeFix ==="
NVME_URL=$(get_latest_release_url "acidanthera/NVMeFix" "RELEASE.zip") || true

if [ -n "$NVME_URL" ]; then
    if download_and_extract "$NVME_URL" "NVMeFix"; then
        src=$(find_dir "${TEMP_DIR}/NVMeFix" "NVMeFix.kext")
        copy_kext "$src" "NVMeFix.kext"
    fi
else
    log_err "Skipping NVMeFix (could not resolve URL)"
fi
echo ""

##############################################################################
# 8. RestrictEvents.kext
##############################################################################

log_info "=== RestrictEvents ==="
RE_URL=$(get_latest_release_url "acidanthera/RestrictEvents" "RELEASE.zip") || true

if [ -n "$RE_URL" ]; then
    if download_and_extract "$RE_URL" "RestrictEvents"; then
        src=$(find_dir "${TEMP_DIR}/RestrictEvents" "RestrictEvents.kext")
        copy_kext "$src" "RestrictEvents.kext"
    fi
else
    log_err "Skipping RestrictEvents (could not resolve URL)"
fi
echo ""

##############################################################################
# 9. CryptexFixup.kext (Sequoia - fixes cryptex loading process)
##############################################################################

log_info "=== CryptexFixup ==="
CF_URL=$(get_latest_release_url "acidanthera/CryptexFixup" "RELEASE.zip") || true

if [ -n "$CF_URL" ]; then
    if download_and_extract "$CF_URL" "CryptexFixup"; then
        src=$(find_dir "${TEMP_DIR}/CryptexFixup" "CryptexFixup.kext")
        copy_kext "$src" "CryptexFixup.kext"
    fi
else
    log_err "Skipping CryptexFixup (could not resolve URL)"
fi
echo ""

##############################################################################
# 10. FeatureUnlock.kext (enables Sidecar, AirPlay, Continuity on Hackintosh)
##############################################################################

log_info "=== FeatureUnlock ==="
FU_URL=$(get_latest_release_url "acidanthera/FeatureUnlock" "RELEASE.zip") || true

if [ -n "$FU_URL" ]; then
    if download_and_extract "$FU_URL" "FeatureUnlock"; then
        src=$(find_dir "${TEMP_DIR}/FeatureUnlock" "FeatureUnlock.kext")
        copy_kext "$src" "FeatureUnlock.kext"
    fi
else
    log_err "Skipping FeatureUnlock (could not resolve URL)"
fi
echo ""

##############################################################################
# 11. HfsPlus.efi (from OcBinaryData)
##############################################################################

log_info "=== HfsPlus.efi (OcBinaryData) ==="
# HfsPlus.efi is not in a release zip; it lives in the repo directly.
# Download the raw file from the main branch.
HFSPLUS_URL="https://raw.githubusercontent.com/acidanthera/OcBinaryData/master/Drivers/HfsPlus.efi"
HFSPLUS_DEST="${DRIVERS_DIR}/HfsPlus.efi"

log_info "Downloading HfsPlus.efi from OcBinaryData..."
if curl -sL -o "$HFSPLUS_DEST" "$HFSPLUS_URL" && [ -s "$HFSPLUS_DEST" ]; then
    log_ok "Installed HfsPlus.efi -> Drivers/"
    SUMMARY="${SUMMARY}\n  ${GREEN}[OK]${NC} HfsPlus.efi -> EFI/OC/Drivers/"
    DOWNLOADED=$((DOWNLOADED + 1))
else
    log_err "Failed to download HfsPlus.efi"
    SUMMARY="${SUMMARY}\n  ${RED}[FAIL]${NC} HfsPlus.efi download failed"
    FAILED=$((FAILED + 1))
fi
echo ""

##############################################################################
# Summary
##############################################################################

echo "============================================================"
echo "  DOWNLOAD SUMMARY"
echo "============================================================"
echo ""
echo -e "  Components downloaded: ${GREEN}${DOWNLOADED}${NC}"
if [ "$FAILED" -gt 0 ]; then
    echo -e "  Components failed:    ${RED}${FAILED}${NC}"
fi
echo ""
echo "  File placement:"
echo -e "$SUMMARY"
echo ""
echo "  Directory structure:"
echo "  EFI/"
echo "  +-- BOOT/"
ls -1 "$BOOT_DIR" 2>/dev/null | sed 's/^/  |   /'
echo "  +-- OC/"
ls -1 "$OC_DIR"/*.efi 2>/dev/null | xargs -I{} basename {} | sed 's/^/  |   /'
echo "  |   +-- Drivers/"
ls -1 "$DRIVERS_DIR" 2>/dev/null | sed 's/^/  |   |   /'
echo "  |   +-- Kexts/"
ls -1 "$KEXTS_DIR" 2>/dev/null | sed 's/^/  |       /'
echo ""

if [ "$FAILED" -gt 0 ]; then
    log_warn "Some components failed to download. Check errors above."
    echo "  You may need to download them manually or re-run the script."
    echo ""
    exit 1
else
    log_ok "All components downloaded successfully!"
    echo ""
fi
