
# Quirks
- kubler is not flexible for image tags, custom tagging and pushing to registry is treated outside kubler itself based on images.yaml
- build.conf is generated from images.yaml requirement definitions
- having an image with a single python version turned out to be harder than expected, but with some package.provieded entries, newuse and depclean it was finally successful




