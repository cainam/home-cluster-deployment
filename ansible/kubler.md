
# Quirks
- kubler is not flexible for image tags, custom tagging and pushing to registry is treated outside kubler itself based on images.yaml
- build.conf is generated from images.yaml requirement definitions
- having an image with a single python version turned out to be harder than expected, but with some package.provieded entries, newuse and depclean it was finally successful
- since I like to avoid using ":latest" which is hard-coded and since I want to tag images with the version of the software but IMAGE_TAG is used for the parent-builder as well I decided to implement parts of kubler in ansible keeping the init phase (portage, stage) and using kubler-build-root script

```mermaid
flowchart TD; 
 subgraph kubler init
  portage-->stage;
  stage-->builder-core;
  builder-core-->builder-image1;
  builder-image1-->builder-image2
  builder-image1-->image1;
  end
  builder-image2-->builder-image3
  subgraph kubler-build-root-2
  builder-image2-->image2
  end
  builder-image3-->builder-image4
  subgraph kubler-build-root-3
  builder-image3-->image3
  end

```


