## howto
* raspberry to use
* force_eeprom tag to force update

## hints
* debugging for WLAN module can be enabled like this:
    # cat /etc/modprobe.d/wlan.conf
    options brcmfmac debug=0x00100004

* check to see which driver the kernel is looking for and what is loaded:
    # dmesg | grep -e brcmf_fw_alloc_request -e Firmware:
    [    5.367786] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac43455-sdio for chip BCM4345/6
    [    5.589637] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac43455-sdio for chip BCM4345/6
    [    5.594802] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac43455-sdio for chip BCM4345/6
    [    5.600202] brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4345/6 wl0: Apr 15 2021 03:03:20 version 7.45.234 (4ca95bb CY) FWID 01-996384e2

