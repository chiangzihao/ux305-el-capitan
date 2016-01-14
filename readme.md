# UX305LA and UX305FA El Capitan 10.11.2



## Supported Models
* UX305LA i3/i5/i7
* UX305FA Core M

## Current Status
Component | Status | Notes
--------- | ------ |------
Intel Graphics|Working|
USB2/USB3|Working|FakePCIID_XHCIMux and DSDT edits
Intel Wireless|Unsupported|**UX305LA:** Wireless card is soldered. USB wifi required. **UX305FA:** Can be replaced with BCM94352Z. (Dell part number 06XRYC)
SDXC Card Reader|Working|
Audio (CX20752)|Partial|**AppleHDA:** Internal microphone and line in aren't working. **VoodooHDA:** Mic/line in work, but no jack sense when plugging in headphones. **HDMI Audio:** Work in progress.
Ambient Light Sensor|Working|
Trackpad|Working|ELAN Touchpad. Using ApplePS2SmartTouchPad

## BIOS Settings

### Advanced

VT-D: Disabled

**Graphics Configuration**

DVMT Pre-Allocated: 64M

**USB Configuration**

Legacy USB Support: Auto

XHCI Pre-Boot Mode: Smart Auto

USB Mass Storage Driver Support: Enabled

### Security

Secure Boot Control: Disabled


### Boot

Launch CSM: Enabled