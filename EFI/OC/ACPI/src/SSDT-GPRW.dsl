/*
 * SSDT-GPRW.dsl - Sleep/Wake Fix for Dell Precision 3630
 *
 * Fixes instant wake (sleep/wake loop) caused by GPRW returning GPE 0x6D
 * for USB and LAN wake events.
 *
 * Usage:
 *   1. In config.plist, add an ACPI rename patch:
 *      Find:    47505257 (GPRW)
 *      Replace: 58505257 (XPRW)
 *      This renames the original GPRW method to XPRW in the DSDT.
 *
 *   2. Compile this SSDT and place SSDT-GPRW.aml in EFI/OC/ACPI/
 *
 *   3. Add SSDT-GPRW.aml to config.plist ACPI -> Add list.
 *
 * How it works:
 *   The original GPRW method is renamed to XPRW via config.plist patch.
 *   This SSDT defines a replacement GPRW method that intercepts calls.
 *   If the second argument (wake type) is 0x6D, it returns 0x00 instead,
 *   effectively disabling that wake source and preventing instant wake.
 *   All other wake events pass through to the original XPRW method.
 */

DefinitionBlock ("", "SSDT", 2, "CORP", "GPRW", 0x00000000)
{
    External (XPRW, MethodObj)

    Method (GPRW, 2, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If (0x6D == Arg1)
            {
                Return (Package (0x02)
                {
                    Arg0,
                    Zero
                })
            }
        }

        Return (XPRW (Arg0, Arg1))
    }
}
