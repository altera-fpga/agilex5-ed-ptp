# Agilex&trade; 5 Precision Time Protocol(IEEE 1588v2) System Example Design

## Description

The Agilex &trade; 5 Precision Time Protocol(IEEE 1588v2) System Example Design includes two Ethernet ports with built-in 2-step hardware PTP timestamping capabilities. The integrated Agilex&trade; 5 Hard Processor System (HPS) operates a PTP software stack that complements the hardware-based timestamping functionality.

The System Example Design (SED) provides the necessary drivers and user applications to support the Linux Network stack, the Linux PTP stack, and network Quality of Service (QoS) through the Linux kernel Traffic Control (TC) system.

The system's primary components include:

- Golden Hardware Reference Design (GHRD)
- Reference HPS software including:
  - Arm Trusted Firmware
  - U-Boot
  - Linux Kernel
  - Linux Drivers
  - User Space Applications

The System Example Design support following design configurations on Altera Development Kits.
  
|SL No| Design configuration                        | Data-rate   | Development Kit Supported        | Device Family |  Device Part | Documentation |
|-----|---------------------------------------------|----------|:------------------------:|:-----------:|:---------------:|:-----:|
|1.   |2-port 10GbE with PTP1588                    | 10GbE    | [DK-A5E065BB32AEA](https://www.altera.com/products/devkit/po-3284/agilex-5-fpga-e-series-065b-premium-development-kit)         | Agilex&trade; 5 E-Series( Group B) | A5ED065BB32AE4S | [10GbE PTP1588 on Agilex 5E](https://altera-fpga.github.io/rel-26.1/embedded-designs/agilex-5/e-series/premium-065b/ptp1588/agx5e-ptp-2p10g/ug-agx5e-ptp-2p10g.md)|
|2.   |2-port 25GbE with PTP1588                    | 25GbE    | [DK-A5E065AB32AEA](https://www.altera.com/products/devkit/po-3285/agilex-5-fpga-e-series-065a-premium-development-kit)         | Agilex&trade; 5 E-Series( Group A) | A5ED065AB32AE1V | [25GbE PTP1588 on Agilex 5E](https://altera-fpga.github.io/rel-26.1/embedded-designs/agilex-5/e-series/premium-065a/ptp1588/agx5e-ptp-2p/ug-agx5e-ptp-2p.md)|

## Repository Structure

Directory Structure Used in This Example Design:

``` bash
agilex5-ed-ptp
|--- a5e065b-prem-devkit-exp-prod/
  |   |--- src
  |   |   |--- hw
  |   |   |--- sw
|--- a5e065a-prem-devkit-exp-prod/
  |   |--- src
  |   |   |--- hw
  |   |   |--- sw
```


## Getting Started

Building the design is easy with the scripts provided in the repo. Clone the repository to get the source files

``` bash
git clone https://github.com/altera-fpga/agilex5-ed-ptp.git
cd agilex5-ed-ptp
git checkout main
```

Follow the below links to compile, build and test the Design solution for intended speeds.

- [Building 10GbE Design on DK-A5E065BB32AEA](./a5e065b-prem-devkit-exp-prod)
- [Building 25GbE Design on DK-A5E065AB32AEA](./a5e065a-prem-devkit-exp-prod)


## Previous Releases
Kindly refer to below repository branch for 2-Port 10GbE PTP1588 Design targetted to ES version of Agilex™ 5 FPGA E-Series 065B Premium Development Kit ([DK-A5E065BB32AES1](https://www.altera.com/products/devkit/po-3002/agilex-5-fpga-and-soc-e-series-premium-development-kit-es))
- [2-Port 10G PTP1588 Design](https://github.com/altera-fpga/agilex5-ed-ptp/tree/rel/25.3)
