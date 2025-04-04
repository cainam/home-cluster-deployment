#
# Build config, sourced by build-root.sh in the build container
#

#
# This hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_builder() {
    fix_portage_profile_symlink
    export emerge_opt="-b -k --binpkg-respect-use=y"
cat >> /etc/portage/package.use/builder.conf <<EOF
sys-devel/binutils gold
dev-vcs/git -perl
app-crypt/pinentry ncurses
*/* PYTHON_TARGETS: -* python3_13
*/* PYTHON_SINGLE_TARGET: -* python3_13
EOF
    for remove_me in debug doc kerberos ldap pam perl systemd tcl test su seccomp udev systemd; do 
      echo "*/* -${remove_me}" >> /etc/portage/package.use/builder.conf
    done

    mkdir -p /etc/portage/package.{accept_keywords,unmask,mask,use}
    source /etc/profile
    emerge ${emerge_opt} --newuse sys-apps/portage app-portage/flaggie app-portage/eix app-portage/gentoolkit

    # candidates for removal: net-misc/iputils (ping) sys-apps/openrc sys-apps/net-tools app-editors/nano
    remove="virtual/service-manager sys-apps/elfix sys-libs/libseccomp dev-python/pypax virtual/udev sys-apps/systemd-utils virtual/dev-manager net-misc/dhcpcd net-misc/iputils sys-apps/openrc sys-apps/net-tools app-editors/nano"
    for p in ${remove}; do
      qlist -Iv "${p}" >> /etc/portage/profile/package.provided
    done
    emerge --unmerge ${remove}
    emerge ${emerge_opt} @preserved-rebuild

    emerge ${emerge_opt} --newuse --deep @installed --tree
    emerge ${emerge_opt} --depclean
    set +x
}
finish_rootfs_build() {
    eix-update
}
