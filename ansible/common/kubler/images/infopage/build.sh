#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-python/uvicorn net-misc/curl dev-python/jinja2 dev-python/requests dev-python/typing-extensions dev-python/pyyaml dev-python/packaging"
#_keep_headers=true

configure_builder()
{
    echo "configure_builder()"
    cat /etc/portage/package.use/*
#    export USE="-su"
#
#    sed -e '/PYTHON_TARGETS:/d' -e '/PYTHON_SINGLE_TARGET:/d' -i /etc/portage/package.use/99local.conf
#    echo -e "*/* PYTHON_TARGETS: -* python3_12\n*/* PYTHON_SINGLE_TARGET: -* python3_12" >> /etc/portage/package.use/99local.conf

    emerge -v dev-python/pip
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
true
    echo "*/* -su" >> /etc/portage/package.use/99local.conf

#    update_use '*/*' '-su'
#    update_use '+sqlite'
    provide_package sys-devel/gcc

    # add user/group for unprivileged container usage
#    groupadd -g 404 python
#    useradd -u 4004 -g python -d /home/python python
#    mkdir -p "${_EMERGE_ROOT}"/home/python
    sed -e '/PYTHON_TARGETS:/d' -e '/PYTHON_SINGLE_TARGET:/d' -i /etc/portage/package.use/99local.conf
    echo -e "*/* PYTHON_TARGETS: -* python3_12\n*/* PYTHON_SINGLE_TARGET: -* python3_12" >> /etc/portage/package.use/99local.conf

}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
  VIRTUAL_ENV=/py_env
  export PYTHONPATH=/py_env/lib/python3.12/site-packages/

  python -m venv --system-site-packages "$VIRTUAL_ENV" && . "$VIRTUAL_ENV"/bin/activate && pip install fastapi
  mv  "${VIRTUAL_ENV}" "${_EMERGE_ROOT}/${VIRTUAL_ENV}"

  # remove this again when python has been rebuild masking PYTHON_TARGETS
  #rm "${_EMERGE_ROOT}/${VIRTUAL_ENV}"/bin/python
  #ln -s /usr/lib/python-exec/python3.13/python "${_EMERGE_ROOT}/${VIRTUAL_ENV}"/bin/python
}
