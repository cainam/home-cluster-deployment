## howto
* raspberry to use
* force_eeprom tag to force update

## hints
* debugging for WLAN module can be enabled like this:
    # cat /etc/modprobe.d/wlan.conf
    options brcmfmac debug=0x00100004

* check to see which driver the kernel is looking for:
    # dmesg | grep brcmf_fw_alloc_request
    [   11.832946] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac43455-sdio for chip BCM4345/6

