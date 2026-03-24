/*
 * SSDT-PLUG.dsl
 *
 * Intel XCPM (XNU CPU Power Management) plugin-type injection
 * Target: Dell Precision 3630 Tower
 * CPU: Intel Xeon E-2136 (Coffee Lake, 6C/12T)
 * Chipset: Intel C246
 * CPU ACPI Path: \_SB.PR00
 *
 * Purpose:
 *   Enables native XCPM by setting plugin-type = 1 on the first
 *   logical CPU core (PR00). This activates SpeedStep (P-States)
 *   and Turbo Boost under macOS without additional kexts.
 *
 *   Only the first processor object requires this property;
 *   all other cores/threads inherit the power management mode.
 *
 * Compile: iasl SSDT-PLUG.dsl
 * Output:  SSDT-PLUG.aml -> EFI/OC/ACPI/
 */

DefinitionBlock ("SSDT-PLUG.aml", "SSDT", 2, "DRTNIA", "CpuPlug", 0x00003000)
{
    External (\_SB.PR00, ProcessorObj)

    Scope (\_SB.PR00)
    {
        If (_OSI ("Darwin"))
        {
            Method (_DSM, 4, NotSerialized)
            {
                If (LNot (Arg2))
                {
                    Return (Buffer (One)
                    {
                        0x03
                    })
                }

                Return (Package (0x02)
                {
                    "plugin-type",
                    One
                })
            }
        }
    }
}
