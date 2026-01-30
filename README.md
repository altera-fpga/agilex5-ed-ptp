# Agilex&trade; 5 Precision Time Protocol(IEEE 1588v2) System Example Design

## Description

The Agilex &trade; 5 10GbE Precision Time Protocol(IEEE 1588v2) System Example Design includes two Ethernet ports with built-in 2-step hardware PTP timestamping capabilities. The integrated Agilex&trade; 5 Hard Processor System (HPS) operates a PTP software stack that complements the hardware-based timestamping functionality.

The System Example Design (SED) provides the necessary drivers and user applications to support the Linux Network stack, the Linux PTP stack, and network Quality of Service (QoS) through the Linux kernel Traffic Control (TC) system.

The system's primary components include:

- Golden Hardware Reference Design (GHRD)
- Reference HPS software including:
  - Arm Trusted Firmware
  - U-Boot
  - Linux Kernel
  - Linux Drivers
  - User Space Applications

![](./sm_ptp_bd.png)

## Repository Structure

Directory Structure Used in This Example Design:

``` bash
|--- a5e065b-prem-devkit-exp-es/
  |   |--- src
  |   |   |--- hw
  |   |   |--- sw

```

## Project Details

- **Family**: Agilex&trade; 5 E-Series( Group B)
- **Quartus Version**: 25.3
- **Development Kit**: Agilex&trade; 5 FPGA E-Series 065B Premium Development Kit([DK-A5E065BB32AES1](https://www.altera.com/products/devkit/a1jui0000061qifmaa/agilex-5-fpga-and-soc-e-series-premium-development-kit-es))
- **Device Part**: A5ED065BB32AE6SR0

## Getting Started

Building the design is easy with the scripts provided in the repo. Clone the repository to get the source files

``` bash
git clone https://github.com/altera-fpga/agilex5-ed-ptp.git
cd agilex5-ed-ptp
git checkout SED-2X10GE_PTP-agilex5_dk_a5e065bb32aes1-Q25.3-Rel1.1
```

Follow the below procedure to build the HW and the Software artifacts.

- [Building the hardware](https://github.com/altera-fpga/agilex5-ed-ptp/tree/main/a5e065b-prem-devkit-exp-es/src/hw)
- [Building the software](https://github.com/altera-fpga/agilex5-ed-ptp/tree/main/a5e065b-prem-devkit-exp-es/src/sw)
