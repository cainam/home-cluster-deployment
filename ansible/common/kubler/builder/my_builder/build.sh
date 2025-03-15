#
# Build config, sourced by build-root.sh in the build container
#

#
# This hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_builder() {
    ### example for a stage3 builder setup that should work out of the box on x86_64 and glibc stage3
    fix_portage_profile_symlink
    # install basics used by helper functions
    eselect news read new 1> /dev/null
    . /etc/profile.d/portage-defaults.sh
    emerge app-portage/flaggie app-portage/eix app-portage/gentoolkit # sys-apps/locale-gen
    eix-update
    mkdir -p /etc/portage/package.{accept_keywords,unmask,mask,use}
    touch /etc/portage/package.accept_keywords/flaggie
    # set locale of build container
    # incompatible with musl: echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    # incompatible with musl: locale-gen
    # incompatible with musl: echo 'LANG="en_US.utf8"' > /etc/env.d/02locale
    env-update
    source /etc/profile
    # install default packages
    # when using overlay1 docker storage the created hard link will trigger an error during openssh uninstall
    [[ -f /usr/"${_LIB}"/misc/ssh-keysign ]] && rm /usr/"${_LIB}"/misc/ssh-keysign
    update_use 'dev-vcs/git' '-perl'
    update_use 'app-crypt/pinentry' '+ncurses'
    # update_keywords 'dev-python/ssl-fetch' '+~amd64'
    # update_keywords 'app-admin/su-exec' '+~amd64'
    echo "*/* -su" >> /etc/portage/package.use/98su.conf
    echo "*/* -seccomp" >> /etc/portage/package.use/98seccomp.conf
    echo "*/* -udev" >> /etc/portage/package.use/98udev.conf
    echo "*/* -systemd" >> /etc/portage/package.use/98systemd.conf
    echo -e "*/* PYTHON_TARGETS: -* python3_12\n*/* PYTHON_SINGLE_TARGET: -* python3_12" >> /etc/portage/package.use/98py.conf
    update_use 'sys-devel/binutils' '+gold'
    emerge --unmerge $(qlist -Iv | grep dev-lang/python-3.13) virtual/service-manager
    emerge --depclean
    emerge --update --newuse --deep @world --quiet --tree
    emerge --depclean

    emerge dev-vcs/git app-eselect/eselect-repository app-misc/jq app-shells/bash-completion
    #install_git_postsync_hooks
    [[ "${BOB_UPDATE_WORLD}" == true ]] && emerge -vuND world
    true
    #add_overlay kubler https://github.com/edannenberg/kubler-overlay.git
    export GOARCH=arm64
    emerge dev-lang/go
    ##emerge sys-devel/gcc
}

finish_rootfs_build() {
    eix-update
}
