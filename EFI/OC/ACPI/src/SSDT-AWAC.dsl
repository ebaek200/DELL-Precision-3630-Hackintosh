/*
 * SSDT-AWAC: RTC Fix for Dell Precision 3630 (C246 / 300-series)
 *
 * 300-series chipsets may use AWAC (Always-on Wake Alarm Counter) instead
 * of the legacy RTC. macOS requires the legacy RTC device (PNP0B00).
 *
 * Strategy:
 *   1. If STAS variable exists in the firmware, set it to One.
 *      This tells the DSDT to enable the legacy RTC and disable AWAC.
 *   2. If STAS does not exist, define a fake RTC device (RTC0) that is
 *      active only on Darwin (macOS).
 */
DefinitionBlock ("", "SSDT", 2, "CORP", "AWAC", 0x00000000)
{
    External (STAS, IntObj)
    External (_SB_.PCI0.LPCB, DeviceObj)

    Scope (\)
    {
        Method (_INI, 0, NotSerialized)  // _INI: Initialize
        {
            If (CondRefOf (STAS))
            {
                STAS = One
            }
        }
    }

    If (!CondRefOf (STAS))
    {
        Scope (_SB.PCI0.LPCB)
        {
            Device (RTC0)
            {
                Name (_HID, EisaId ("PNP0B00"))  // AT Real-Time Clock

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    IO (Decode16,
                        0x0070,             // Range Minimum
                        0x0070,             // Range Maximum
                        0x01,               // Alignment
                        0x02,               // Length
                    )
                    IRQNoFlags ()
                        {8}
                })

                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
            }
        }
    }
}
