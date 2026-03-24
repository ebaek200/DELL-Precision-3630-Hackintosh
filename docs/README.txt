================================================================================
  Hackintosh EFI - Dell Precision 3630
================================================================================

  Target Hardware:
    CPU ......... Intel Xeon E-2136 (Coffee Lake 6C/12T 3.3GHz)
    Chipset ..... Intel C246
    GPU ......... AMD Radeon RX 5700 XT (Navi 10, 8GB)
    Audio ....... Realtek ALC255 (ALC3234)
    Ethernet .... Intel I219-LM
    WiFi ........ Broadcom 802.11ac (native)
    NVMe ........ Samsung MZFLV256 + WD SN530 256GB
    RAM ......... 32GB DDR4-2666 (4x8GB Samsung)

  Target OS: macOS Sequoia 15.x
  SMBIOS: iMacPro1,1
  OpenCore: 1.0.2+

================================================================================
  Folder Structure
================================================================================

  E:\Hackintosh-EFI\
  |
  +-- EFI\                        <-- USB EFI 파티션에 복사할 폴더
  |   +-- BOOT\                   <-- BOOTx64.efi (download_kexts.sh가 설치)
  |   +-- OC\
  |       +-- ACPI\               <-- SSDT .dsl 소스 (컴파일 후 .aml 사용)
  |       +-- Drivers\            <-- OpenRuntime.efi, HfsPlus.efi 등
  |       +-- Kexts\              <-- USBMap.kext + 다운로드된 kext들
  |       +-- Resources\          <-- OpenCanopy 테마 리소스
  |       +-- Tools\              <-- 디버그 도구 (VerifyMsrE2 등)
  |       +-- config.plist        <-- OpenCore 메인 설정
  |
  +-- backup\                     <-- 버전별 백업 스냅샷
  |   +-- v1.0_initial_20260324\  <-- 최초 생성 백업
  |
  +-- updates\                    <-- 변경 이력
  |   +-- CHANGELOG.txt           <-- 버전별 변경사항 기록
  |
  +-- docs\                       <-- 문서
  |   +-- README.txt              <-- 이 파일
  |   +-- CHECKLIST.txt           <-- BIOS + 설치 + 검증 체크리스트
  |
  +-- download_kexts.sh           <-- macOS에서 실행: kext/driver 자동 다운로드

================================================================================
  Quick Start
================================================================================

  1. macOS 터미널에서:
     cd /Volumes/dw_key/Hackintosh-EFI
     chmod +x download_kexts.sh
     ./download_kexts.sh

  2. SSDT 컴파일:
     cd EFI/OC/ACPI
     for f in *.dsl; do iasl "$f"; done

  3. GenSMBIOS 실행 → iMacPro1,1 → config.plist PLACEHOLDER 교체

  4. EFI 폴더를 USB EFI 파티션에 복사

  5. Dell BIOS 설정 (CHECKLIST.txt Part 1 참조)

  6. USB로 부팅 → macOS Sequoia 설치

================================================================================
