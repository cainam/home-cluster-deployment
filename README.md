# k8s_at_home
Kubernetes cluster with oauth, keycloak, local repository management used for home.assistant

What I like to do
* play with Kubernetes, Raspberry and Hardware
* keep all data local, no data on the "cloud"
* use data only in a way which allows my to inspect at any time
* run an compact and robust setup

to use for 
* Home Automation with Home Assistent
* Zigbee Gateway zur Einbinung von Zigbee Geräten
* Tor (SOCKS5 proxy, Entry-/Middle-/Exit-Node at least to test)
* Internet proxy (Privoxy)
* analyze internet traffic(z.B. ntop)

What I learnt among other
* ICE connectors (see C14 on parts list) are  are designed for 10A (at least I had to think about the consequences)
* Instead of torturing the sheet metal with pliers, an electric all-rounder ala Dremel would have been better, not only visually, but I would also have saved myself a bloody finger
* Be careful when measuring voltage! If you touch the housing of the power supply unit, the FI will fly out. As far as that is known. I have learned that this can lead to the family not being allowed to continue tinkering that day, because of course the television sets will also go out.

Incomplete list of problems:
* Linux Kernel update leads to Kernel Oops => Cause unclear, but could be traced to a kernel module in kernel/drivers that does not start with the letter m (knowing this was sufficient for me to continue)
* Gluster crashed after kernel update with SIGILL (Illegal instruction) => Cause unclear, solved by using ARM v8+ Kernel instead of v7l Kernel 
* impossible to update app-crypt/gpgme after emerge sync, gpgme-1.16.0-glibc-2.34.patch, which was removed by Gentoo had to be applied at  /etc/portage/patches
* impossible to update sys-libs/liburing after emerge-sync, syscall patch https://github.com/axboe/liburing/commit/cb350a8989adbd65db574325d9a86d5437d800da solved the issue, this happened more than once so I had to redo including self-written patches
* DNS stopped working after an update. Gentoo had removed busybox from the system set and used it as a DHCP client. The simple solution is to add busybox to the local world set (trivial in the end, but it took a while to discover)
* The devices were no longer in the WLAN and could only be used again after a restart. First assumption was power-safe of the WLAN driver, but deactivation brought no improvement. Therefore the bootloader firmware was flashed.
* why? Everything works, no cross-compiler used and still illegal instruction. How much time that takes, see this side note!
* with quickpkg you shouldn't just be quick, otherwise you'll have file contents that lead to unnecessary errors and troubleshooting: # empty file because --include-config=n when `quickpkg` was used
