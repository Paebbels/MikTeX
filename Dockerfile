ARG IMAGE
ARG OS_VERSION
ARG PY_VERSION

FROM ${IMAGE}
ARG OS_VERSION
ARG PY_VERSION

# Meta information
LABEL maintainer="Patrick Lehmann <Paebbels@gmail.com>"
LABEL version="0.1"
LABEL description="MikTeX based on Debian ${OS_VERSION} and Python ${PY_VERSION}."

# Install Debian packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Install MikTeX
RUN curl -fsSL https://miktex.org/download/key | tee /usr/share/keyrings/miktex-keyring.asc > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/miktex-keyring.asc] https://miktex.org/download/debian ${OS_VERSION} universe" | tee /etc/apt/sources.list.d/miktex.list
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ghostscript \
    make \
    perl \
    miktex \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Install executables like lualatex into /usr/local/bin
RUN miktexsetup --shared=yes finish

# Enable automatic package installations
RUN initexmf --admin --set-config-value [MPM]AutoInstall=1

# Install LaTeX packages
RUN --mount=type=bind,target=/context \
     miktex --admin --verbose packages update-package-database \
 && (miktex --admin --verbose packages install --package-id-file /context/Packages.list || (cat /var/log/miktex/mpmcli_admin.log && exit 1)) \
 && initexmf --admin --update-fndb

ENV MIKTEX_USERCONFIG=/miktex/.miktex/texmfs/config
ENV MIKTEX_USERDATA=/miktex/.miktex/texmfs/data
ENV MIKTEX_USERINSTALL=/miktex/.miktex/texmfs/install

ENTRYPOINT /bin/bash -l
