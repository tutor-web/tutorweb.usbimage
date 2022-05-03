# EIAS on a APU2

## Bill of Materials

* APU2:
  * https://linitx.com/product/pc-engines-apu2-e4-system-board-with-4gb-ram/16194
  * https://linitx.com/product/pc-engines-12v-uk-(3-pin)-adapter-for-the-apu-system-board-and-edgerouter-er-x/14167
  * https://linitx.com/product/pc-engines-anodised-apu-enclosure-(3-lan-+-usb-+-6-sma)---red/15569
  * https://linitx.com/product/pc-engines-12v-uk-(3-pin)-adapter-for-the-apu-system-board-and-edgerouter-er-x/14167
  * "256GB mSATA SSD"
* Wifi hardware:
  * https://linitx.com/product/compex-wle600vx-minipci-express-802.11-a-b-g-n-ac/14939
  * 2x https://linitx.com/product/pc-engines-ipex-to-sma-female-pigtail-cable/14978
  * 2x https://linitx.com/product/pc-engines-omni-antenna-2.4ghz-5ghz-dualband---5dbi/11589
  * 1x https://uk.farnell.com/abl-heatsinks/bga-std-025/heat-sink-bga-standard-22-c-w/dp/2084427
* 3g hardware:
  * "Huawei ME906s" or "Sierra Wireless mc7455" or "Sierra Wireless em7565"
  * "M.2 Key B to Mini PCIE PCI-E Adapter Converter for 3G/4G/5G"
  * 2x "Sma Female Bulkhead To U.Fl (Ipex/Ipx) MHF-4"
  * 2x https://linitx.com/product/sequoia-delta-6a-3g-sma-antenna/14435
  * 1x https://uk.farnell.com/abl-heatsinks/bga-std-025/heat-sink-bga-standard-22-c-w/dp/2084427
* APU2 power button:
  * "6mm momentary push button switch" (to add external power button)
  * 2 pin 0.1" header cable
* APU2 debug cable:
  * https://linitx.com/product/pc-engines-usb-to-db9f-serial-adapter/15469

## Assembly

* APU2:
  * [Follow the PCEngines instructions for the APU2](https://www.pcengines.ch/apucool.htm)
  * Put the SSD into the "mSATA" PCIe slot
* Wifi Hardware:
  * Put the PCIe card into "mPCIe 1" slot
  * Mount the cables in the holes on the rear of the case, next to the ports, plug into wifi card (do not press connector at an angle)
  * Once transported, attach the heatsinks and antennae [as per commissioning guide](commission-apu2.md)
* 3G Hardware:
  * Put the M.2 3G card into the adapter
  * Put the PCIe adapter into "mPCIe 2" slot
  * Mount the cables in the holes on the lid of the case, next to the ports, plug into wifi card (do not press connector at an angle)
  * Once transported, attach the heatsinks and antennae [as per commissioning guide](commission-apu2.md)
* APU2 power button:
  * File a flat edge of the push button switch screwthread, so it fits into one of the case's antennae holes
  * Solder header cable ends to the power button
  * Attach to PWR header, pins 2-3 (pin 1 nearest SD card slot)

    <img src="images/apu2-internal-overview.jpg" width="100%">
* APU2 debug cable:
  * Attach to the APU2 serial port, and a separate computer
  * [Install drivers if necessary](https://pcengines.ch/usbcom1a.htm)
  * Configure a serial communication program (e.g. [picocom](https://linux.die.net/man/8/picocom)) e.g. ``picocom -b115200 /dev/ttyUSB0``.
