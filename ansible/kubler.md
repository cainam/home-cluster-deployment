
# Quirks
- kubler is not flexible for image tags, custom tagging and pushing to registry is treated outside kubler itself based on images.yaml
- build.conf is generate from images.yaml definitions


ToDo:
- python version: using python 3.12 builder to build python-3.13 fails (multiple slots issue), probably better to build python 3.13 images with a python 3.13 builder (tried with emptytree root-deps=rdeps sysroot) or to use same my_builder in each build .... but also this fails because
!!! The ebuild selected to satisfy "~dev-python/pypax-0.9.5[ptpax=,xtpax=]" has unmet requirements.
- dev-python/pypax-0.9.5-r2::gentoo USE="xtpax -debug -ptpax" PYTHON_TARGETS="-python3_10 -python3_11 -python3_12"

  The following REQUIRED_USE flag constraints are unsatisfied:
    any-of ( python_targets_python3_10 python_targets_python3_11 python_targets_python3_12 )

  The above constraints are a subset of the following complete expression:
    any-of ( ptpax xtpax ) any-of ( python_targets_python3_10 python_targets_python3_11 python_targets_python3_12 )

... and elfix is a required system package => nogo to pure python 3.13 builder.
builder with python 3.12 and creating python 3.13 works until gpep517 is required for a build in python 3.13 site-packages


