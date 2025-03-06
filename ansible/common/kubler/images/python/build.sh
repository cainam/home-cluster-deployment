#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-lang/python" # dev-python/pip"
#_keep_headers=true

configure_builder()
{
    echo "configure_builder()"

    # limit python to one version only, set in /etc/portage/package.use/99local.conf
    #sed -e '/PYTHON_TARGETS:/d' -e '/PYTHON_SINGLE_TARGET:/d' -i /etc/portage/package.use/99local.conf
    #echo -e "*/* PYTHON_SINGLE_TARGET: -* python3_13\n*/* PYTHON_TARGETS: -* python3_13" >> /etc/portage/package.use/99local.conf
    #echo "*/* -su" >> /etc/portage/package.use/99local.conf

    export USE="-su"
    #emerge --depclean
    #emerge --update --changed-use @world
    emerge -v --changed-use dev-python/pip
    eix-update
    #emerge -v dev-python/pip
    echo "configure_builder() => done"
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    echo "configure_rootfs_build => start"
    update_use '+sqlite'
        # update_use '*/*' '-use::su'
    #    update_use '-use::su'
    export USE="-su"

    provide_package sys-devel/gcc

    # add user/group for unprivileged container usage
    groupadd -g 404 python
    useradd -u 4004 -g python -d /home/python python
    mkdir -p "${_EMERGE_ROOT}"/home/python
    #sed -e '/PYTHON_TARGETS:/d' -e '/PYTHON_SINGLE_TARGET:/d' -i /etc/portage/package.use/99local.conf
    #echo -e "*/* PYTHON_TARGETS: -* python3_12\n*/* PYTHON_SINGLE_TARGET: -* python3_12" >> /etc/portage/package.use/99local.conf
    emerge --depclean

    ln -s usr/lib "${_EMERGE_ROOT}/lib"
    echo "configure_rootfs_build => done"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    echo "finish_rootfs_build => start"
    # required for internal modules
    copy_gcc_libs
    echo "finish_rootfs_build => done"
}
