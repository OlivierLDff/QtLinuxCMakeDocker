# MIT License
#
# Copyright (c) 2020 Olivier Le Doeuff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Install Qt
ARG QT=6.8.2
ARG QT_MODULES=''
ARG QT_HOST=linux
ARG QT_TARGET=desktop
ARG QT_ARCH=

FROM ubuntu:24.04 AS qt

ARG QT
ARG QT_MODULES
ARG QT_HOST
ARG QT_TARGET
ARG QT_ARCH

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update                                                               && \
    apt upgrade -y                                                           && \
    apt -y install python3 python3-venv

RUN python3 -m venv /venv && \
    . /venv/bin/activate && \
    apt -y install python3-pip && \
    pip install --upgrade pip

RUN . /venv/bin/activate && \
    pip install aqtinstall

RUN . /venv/bin/activate && \
    aqt install-qt -m ${QT_MODULES} -O /opt/qt ${QT_HOST} ${QT_TARGET} ${QT} ${QT_ARCH} \
    && rm -rf /opt/qt/${QT}/gcc_64/plugins/sqldrivers/libqsqlmimer.so

# Should be run:
# docker run -it --rm -v $(pwd):/src/ -u $(id -u):$(id -g) --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined
# linuxdeployqt require for the application to be built with the oldest still supported glibc version
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Dependencies
RUN apt update                                                               && \
    apt upgrade -y                                                           && \
    apt -y install software-properties-common wget build-essential autoconf     \
    git fuse libgl1-mesa-dev psmisc libpq-dev libssl-dev openssl libffi-dev \
    zlib1g-dev libdbus-1-3 libpulse-mainloop-glib0 python3 python3-pip      \
    desktop-file-utils libxcb-icccm4 libxcb-image0 libxcb-keysyms1          \
    libxcb-render-util0 libxcb-xinerama0 libxcb-composite0 libxcb-cursor0   \
    libxcb-damage0 libxcb-dpms0 libxcb-dri2-0 libxcb-dri3-0 libxcb-ewmh2    \
    libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-record0 libxcb-render0 \
    libxcb-res0 libxcb-screensaver0 libxcb-shape0 libxcb-shm0 libxcb-sync1  \
    libxcb-util1 libfontconfig libxcb-xkb1 libxkbcommon-x11-0               \
    libxkbfile-dev                                                          \
    libegl1-mesa-dev unixodbc-dev curl unzip tar pkg-config                 \
    libnss3                                                                 \
    libxcomposite1                                                          \
    libxrender-dev                                                          \
    libxcursor-dev                                                          \
    libxi-dev                                                               \
    libxtst-dev                                                             \
    libxrandr-dev                                                           \
    libasound-dev                                                           \
    libgstreamer1.0-dev                                                     \
    libgstreamer-plugins-base1.0-dev                                        \
    libgtk3.0-cil-dev                                                       \
    libcurl4-openssl-dev                                                    \
    libgomp1                                                                \
    libomp-dev                                                              \
    ninja-build                                                             \
    libmysqlclient-dev

# Build cool cmake version (ubuntu 16.04 comes with cmake 3.5)
ARG CMAKE=3.30.3

RUN wget -c -nv https://github.com/Kitware/CMake/releases/download/v${CMAKE}/cmake-${CMAKE}-Linux-x86_64.sh && \
    sh cmake-${CMAKE}-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir && \
    rm cmake-${CMAKE}-Linux-x86_64.sh

RUN add-apt-repository ppa:git-core/ppa && \
    apt install -y git && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt install -y git-lfs && git lfs install

# Copy qt from previous stage
COPY --from=qt /opt/qt /opt/qt

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN apt install -y libstdc++6

# Install Qt
ARG QT

ENV PATH /opt/qt/${QT}/gcc_64/bin:$PATH
ENV QT_PLUGIN_PATH /opt/qt/${QT}/gcc_64/plugins/
ENV QML_IMPORT_PATH /opt/qt/${QT}/gcc_64/qml/
ENV QML2_IMPORT_PATH /opt/qt/${QT}/gcc_64/qml/
ENV Qt5_DIR /opt/qt/${QT}/gcc_64/
ENV Qt5_Dir /opt/qt/${QT}/gcc_64/
ENV Qt6_DIR /opt/qt/${QT}/gcc_64/
ENV Qt_DIR /opt/qt/${QT}/gcc_64/

# Install linuxdeployqt
RUN wget -c -nv "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -O /usr/bin/linuxdeployqt && \
    chmod a+x /usr/bin/linuxdeployqt

ARG VCPKG=False
ARG VCPKG_PACKAGES='openssl:x64-linux zlib:x64-linux spdlog:x64-linux aws-sdk-cpp[core,ec2,ecr]:x64-linux libssh:x64-linux ms-gsl:x64-linux'

# Install vcpkg
RUN if [ "$VCPKG" = "True" ]; then \
    cd /opt && \
    git clone https://github.com/microsoft/vcpkg/ && \
    cd vcpkg && \
    ./bootstrap-vcpkg.sh --disableMetrics && \
    ./vcpkg install ${VCPKG_PACKAGES}; \
    fi

# Dependencies to support video capture (uvc, genicam)
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libv4l-dev \
    clang lldb lld \
    libudev-dev \
    zlib1g-dev \
    libfontconfig1-dev

# Install latest libusb
RUN git clone -b v1.0.26 https://github.com/libusb/libusb \
    && cd libusb \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && make install

# Add libusb dans library path
ENV LD_LIBRARY_PATH=/usr/local/lib

# Install eigen
RUN wget -O Eigen.zip https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip \
    && unzip Eigen.zip \
    && cmake -B eigen-3.4.0/build -S eigen-3.4.0 \
    && cmake --build eigen-3.4.0/build --target install

WORKDIR /src
