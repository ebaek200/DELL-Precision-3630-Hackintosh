/*
 * SSDT-PMC.dsl
 *
 * Power Management Controller (PMC) for Intel 300-series chipsets.
 * Required for native NVRAM support on chipsets (e.g., C246, Z390, B360, H370)
 * where the PMC device is missing from the OEM ACPI tables.
 *
 * Target: Dell Precision 3630 (C246 chipset)
 *
 * The PMC device exposes a memory-mapped region at 0xFE000000 (64KB) that
 * macOS uses to access native NVRAM. Without this SSDT, macOS falls back
 * to emulated NVRAM which can cause instability.
 */

DefinitionBlock ("", "SSDT", 2, "CORP", "PMCR", 0x00001000)
{
    External (_SB_.PCI0.LPCB, DeviceObj)

    Scope (_SB.PCI0.LPCB)
    {
        Device (PMCR)
        {
            Name (_HID, EisaId ("APP9876"))

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite,
                    0xFE000000,
                    0x00010000,
                    )
            })
        }
    }
}
