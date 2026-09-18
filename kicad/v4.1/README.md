# Revision 4.1

4.1 Revision shrinks revision 4.0 by removing the external voltage regulator, which is not necessary anymore. This revision also adds 100nF decoupling capacitors for buffers/latches ICs and places pull-up resistors for data bus wires.

![V4.1_SMD](../../pics/V4_1.jpg)

## BOM

Check our [Interactive BOM](https://html-preview.github.io/?url=https://github.com/Chandler-Kluser/MSXgoauld_tn20k_ga/raw/refs/heads/main/kicad/v4.1/bom/ibom.html) to have better details.                                                       

| Reference | Chip | Value |
|:-----:|:-----:|:-----:|
| U1~U2 | 74HCT373 (TSSOP-20) | - |
| U3~U4 | 74LVC245 (TSSOP-20) | - |
| U5 | 74HC245 (TSSOP-20) | - |
| U6 | Tang Nano 20k | - |
| D1* | DSS32 (SOD123FL) | - |
| C4~C8 | 0603 SMD Capacitor | $\mathsf{100\ nF}$ |
| R1 | Resistor (0603) | $\mathsf{10\ k\Omega}$ |
| R2~R3 | 4xResistor Array (0603) | $\mathsf{16\ k\Omega}$ |

## Assembly

Production files (gerbers, assembly, placement...) can be found in `production` folder