#!/bin/bash

ALPINE_VERSION="3.21"
# PYTHON_VERSION="3.13" 
HA_VERSION="2024.12.3"

git clone -b master https://github.com/home-assistant/docker-base.git
 
cd docker-base/alpine
podman build -f Dockerfile -t "${registry}"/my-ha-base:"${HA_VERSION}"  --build-arg BUILD_FROM=docker.io/alpine:"${ALPINE_VERSION}" --build-arg BUILD_ARCH=aarch64 $(cat build.yaml | yq -ry .args | sed -e 's/^/--build-arg /g' | sed -e 's/: /=/g' | xargs)
cd -

echo '
ARG BUILD_FROM
FROM $BUILD_FROM

#    && apk add --no-cache --virtual .fetch-deps \
RUN set -ex \
    && apk add --no-cache  \
        gnupg \
        openssl \
        tar \
        xz binutils \
	python3 py3-pip py3-psycopg2 libturbojpeg ffmpeg

RUN python -m venv --system-site-packages /py_env && . /py_env/bin/activate
' > Dockerfile.python

podman build -f Dockerfile.python -t "${registry}"/my-ha-base-python:"${HA_VERSION}"  --build-arg BUILD_FROM=my-ha-base:"${HA_VERSION}"


git clone  --depth=1 -b "${HA_VERSION}" https://github.com/home-assistant/core.git
cd core
#sed -e 's/UV_SYSTEM_PYTHON=true/UV_SYSTEM_PYTHON=false/g' -e 's/0\.5\.4/0.5.13/g' -e 's#^RUN pip3 install uv==#RUN source /py_env/bin/activate \&\& pip3 install uv==#g' -e 's#uv pip install#source /py_env/bin/activate \&\& export UV_HTTP_TIMEOUT=120 \&\& uv pip install#g' Dockerfile > Dockerfile.ha
#sed -e 's/0\.5\.4/0.5.7/g' -e 's#^RUN pip3 install uv==#RUN source /py_env/bin/activate \&\& pip3 install uv==#g' -e 's#uv pip install#source /py_env/bin/activate \&\& UV_HTTP_TIMEOUT=120 uv pip install#g' Dockerfile > Dockerfile.ha
sed -e 's/0\.5\.4/0.5.13/g' -e 's/UV_SYSTEM_PYTHON=true/UV_SYSTEM_PYTHON=false/g' -e 's#^ENV#ENV UV_HTTP_TIMEOUT=120 VIRTUAL_ENV=/py_env PATH="/py_env/bin:$PATH" \\\n  #' Dockerfile > Dockerfile.ha
from=$(grep ^FROM Dockerfile.ha)
sed -i -e '/^FROM /s/$/ AS build/' Dockerfile.ha
sed -i -e "s#^COPY rootfs#RUN find /py_env -name '*.so*' -exec strip {} \\\; \&\& source /py_env/bin/activate \&\& pip uninstall --yes uv\n\n${from}\nCOPY rootfs#" Dockerfile.ha
#echo "${from}" >> Dockerfile.ha
echo "COPY --from=build /py_env /py_env" >> Dockerfile.ha
echo "COPY --from=build /usr/src /usr/src" >> Dockerfile.ha
awk -v RS= -v ORS='\n\n' '!/requirements_all/' Dockerfile.ha > Dockerfile.${HA_VERSION}

for package in home-assistant-frontend pyotp PyQRCode paho-mqtt pyudev; do
  grep -q "${package}==" requirements.txt  || grep "^${package}==" requirements_all.txt >> requirements.txt
done
grep -q "huawei-solar==2.3.0" requirements.txt || echo "huawei-solar==2.3.0" >> requirements.txt

sed -i -e "/hass-nabucasa/d" requirements.txt
sed -i -e "/hass-nabucasa/d" homeassistant/package_constraints.txt
sed -i -e "/hass-nabucasa/d" pyproject.toml
sed -i -e "/hass_nabucasa/d" homeassistant/helpers/network.py
sed -i -e "/hass_nabucasa/d" -e 's#remote.is_cloud_request.get()#False#' homeassistant/components/http/forwarded.py

mkdir ../components
mv homeassistant/components/* ../components
for component in mqtt update panel_custom hassio sun homeassistant system_health switch number input_number notify media_player fan event cover button climate lock vacuum water_heater alarm_control_panel binary_sensor script api auth config default_config device_automation diagnostics file_upload group history http image_upload logbook lovelace onboarding recorder repairs search sensor system_log webhook network websocket_api http persistent_notification person device_tracker zone frontend automation blueprint scene light logger trace ; do 
  mv ../components/$component homeassistant/components/
done

grep -q "source /py_env/bin/activate" rootfs/etc/services.d/home-assistant/run || sed -i -e 's#^exec#source /py_env/bin/activate\nexec#g' rootfs/etc/services.d/home-assistant/run
podman build -f Dockerfile.${HA_VERSION} -t "${registry}"/my-ha-min:"${HA_VERSION}" --build-arg BUILD_ARCH=aarch64 --build-arg QEMU_CPU= --build-arg BUILD_FROM=my-ha-base-python:"${HA_VERSION}"
podman push "${registry}"/my-ha-min:"${HA_VERSION}"
