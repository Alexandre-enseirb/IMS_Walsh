# IMS_Walsh

This repository contains the scripts related to a proof of concept for communications using a Walsh modulation, called OSDM (Orthogonal Sequency Divided Modulation), using USRP-B210 radios.

## Overview

The repository is split into four "subprojects" and a library folder.

- **OSDM**: The scripts in this folder are related to the modulation setup. These are mostly test scripts of different attempts to create modulated signals.
- **Pseudosemantics** is an attempt to communicate english sentences via OSDM modulated signals. It uses the text analytics toolbox from MatLab to represent words as vectors. With this representation, it can communicate the 16384 most used words in the english language.
- **Radios** is the proof of concept. The scripts in this folder are meant to be used on one computer with two USRP-B210 radios plugged-in.
- **UDPVersion** expands on the proof of concept. It allows for the same scripts to be run on two different computers as long as are in the same network.

## Dependencies

### Matlab Toolboxes

- Signal Processing Toolbox
- Communications Toolbox
- Communications Toolbox Support Package for USRP Radio
- Text Analytics Toolbox 

### UHD

In order to use the USRP radios, the UHD driver is required. Please refer Ettus' [installation manual](https://files.ettus.com/manual/page_install.html) for more informations on how to install it.

## How to Use

### With One Computer

1. Clone this repository
2. Open the `Radios/` directory
3. Open `parallelReceiver.m` and `OSDMTransmitter.m`
4. Replace the "SerialNum" field of each radio with your own radios' serial numbers.

#### On Windows
5. Open `rxLauncher.bat` and `txLauncher.bat`
6. In both files, replace the path in line 3 with your MatLab install path
7. Run `rxLauncher.bat`, then `txLauncher.bat`

#### On Linux
5. Open `matlabScript.sh`
6. Replace the path in line 3 with your Matlab install path
7. Run the receiver with the following command
```bash
$ bash matlabScript.sh parallel_receiver rx_logs.txt
```
8. Run the transmitter with the following command
```bash
$ bash matlabScript.sh OSDMTransmitter rx_logs.txt
```

9. Check that a new file named `OSDM_img_rx_clock_pps_rrc_Complex_preamble_QPSK.mat` appeared
10. Run `OSDMReceptionChainV2.m` directly in MatLab

### With Two Computers

1. Clone this repository
2. Open the `UDPVersion/` directory
3. Open `OSDMTransmissionOverUDP.m` and `parallelReceiverOverUDP.m`
4. Replace the "SerialNum" field of each radio with your own radios' serial numbers.
5. Open `getCommParamsForWalshOverUDP.m`
6. Replace fields `params.UDP.TxInetAddr` and `params.UDP.TxInetAddr` with both computers' IP addresses. In `OSDMTransmissionOverUDP.m`, also replace variables `myIP` and `targetIP` with your IP addresses.
7. Run both scripts directly in MatLab

## Common Issues

WIP
