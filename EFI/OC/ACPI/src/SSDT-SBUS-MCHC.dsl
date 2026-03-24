/*
 * SSDT-SBUS-MCHC.dsl - SMBus and Memory Controller Host Fix
 *                       for Dell Precision 3630
 *
 * Provides:
 *   1. MCHC (Memory Controller Host Controller) device at _SB.PCI0
 *      - Needed for proper memory and chipset reporting in macOS
 *      - PCI device 00:00.0 (Host Bridge / DRAM Controller)
 *
 *   2. BUS0 and BUS1 devices under _SB.PCI0.SBUS
 *      - Required for AppleSMBus and AppleSMBusController kexts
 *      - Enables proper SMBus communication for sensor data,
 *        fan control, and other system management functions
 *
 * Usage:
 *   1. Compile this SSDT and place SSDT-SBUS-MCHC.aml in EFI/OC/ACPI/
 *   2. Add SSDT-SBUS-MCHC.aml to config.plist ACPI -> Add list.
 *
 * Note: The _STA methods check for Darwin (macOS) to avoid
 *       interfering with other operating systems.
 */

DefinitionBlock ("", "SSDT", 2, "CORP", "SMBU", 0x00000000)
{
    External (_SB_.PCI0, DeviceObj)
    External (_SB_.PCI0.SBUS, DeviceObj)

    Scope (_SB.PCI0)
    {
        /*
         * MCHC - Memory Controller Host Controller
         * PCI Device 00:00.0 (Host Bridge)
         * Often missing from Dell DSDTs; required by macOS
         * for proper memory controller and chipset reporting.
         */
        Device (MCHC)
        {
            Name (_ADR, Zero)

            Method (_STA, 0, NotSerialized)
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

    Scope (_SB.PCI0.SBUS)
    {
        /*
         * BUS0 - SMBus Host Controller Compatibility Device
         * Required for AppleSMBusController to load properly.
         */
        Device (BUS0)
        {
            Name (_CID, "smbus")
            Name (_ADR, Zero)

            Device (DVL0)
            {
                Name (_ADR, 0x57)
                Name (_CID, "diagsvault")

                Method (_DSM, 4, NotSerialized)
                {
                    If (!Arg2)
                    {
                        Return (Buffer (One)
                        {
                            0x03
                        })
                    }

                    Return (Package (0x02)
                    {
                        "address",
                        0x57
                    })
                }
            }
        }

        /*
         * BUS1 - SMBus Auxiliary Controller
         * Provides additional SMBus functionality for AppleSMBus.
         */
        Device (BUS1)
        {
            Name (_CID, "smbus")
            Name (_ADR, One)
        }
    }
}
