/*
 * SSDT-EC-USBX for Dell Precision 3630 (Coffee Lake, C246 chipset)
 *
 * Creates a fake Embedded Controller (EC) device at _SB.PCI0.LPCB
 * because Dell uses H_EC/ECDV instead of "EC" which macOS expects.
 *
 * Also provides USBX device with USB power properties for
 * high-power USB charging support.
 *
 * Only activates under macOS (_OSI("Darwin")).
 */

DefinitionBlock ("", "SSDT", 2, "DRTNIA", "EcUsbx", 0x00001000)
{
    External (_SB_.PCI0.LPCB, DeviceObj)

    Scope (\_SB.PCI0.LPCB)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")  // Fake EC identifier

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)  // Enable on macOS
                }
                Else
                {
                    Return (Zero)  // Disable on all other OSes
                }
            }
        }
    }

    Scope (\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)

            Method (_DEP, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (Package (0x00) {})
                }
                Else
                {
                    Return (Package (0x00) {})
                }
            }

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)  // Enable on macOS
                }
                Else
                {
                    Return (Zero)  // Disable on all other OSes
                }
            }

            Method (_DSM, 4, NotSerialized)
            {
                If ((Arg2 == Zero))
                {
                    Return (Buffer (One) { 0x03 })
                }

                Return (Package ()
                {
                    "kUSBSleepPortCurrentLimit", 2100,
                    "kUSBSleepPowerSupply",      2600,
                    "kUSBWakePortCurrentLimit",   2100,
                    "kUSBWakePowerSupply",        3200
                })
            }
        }
    }
}
