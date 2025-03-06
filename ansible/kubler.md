
# Quirks
- kubler is not flexible for image tags, custom tagging and pushing to registry is treated outside kubler itself


ToDo:
- python version: using python 3.12 builder to build python-3.13 fails (multiple slots issue), probably better to build python 3.13 images with a python 3.13 builder (tried with emptytree root-deps=rdeps sysroot) or to use same my_builder in each build .... 
- dependencies in Ansible, filling the templates in kubler (infopage depends on python depends on kubler)

