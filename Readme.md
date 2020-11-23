# 🐳 Qt Linux docker

[![🐳 Publish Docker image](https://github.com/OlivierLDff/QtLinuxCMakeDocker/workflows/%F0%9F%90%B3%20Publish%20Docker%20image/badge.svg)](https://github.com/OlivierLDff/QtLinuxCMakeDocker/actions?query=workflow%3A%22%F0%9F%90%B3+Publish+Docker+image%22)

Ready to use environment to compile application using Qt/CMake and deploy [AppImage](https://github.com/probonopd/linuxdeployqt).

* Qt 5.15.1
* CMake 3.18.4
* GCC 9
* linuxdeployqt

## How to use

This image is made to build cmake qt project for linux, but it can also build qmake based.

### ⌨️ Interactive bash

You can run an interactive bash to build whatever you need. Execute this command from you source folder, to map it to `/src` folder in the container.

```bash
# This folder will be mounted in the container as /src
cd /path/to/my/project
# Start bash in the container
docker run -it --rm -v $(pwd):/src/ --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined reivilo1234/qt-linux-cmake:qt5.15.1 bash
# Then regular cmake workflow
mkdir -p build && cd build
cmake ..
make -j
# Build target will be available in /path/to/my/project/build
```

### 🚀 Run only commands inside container

```bash
# Everything need to be executed in the same folder as CMakeLists.txt
# This folder will be mounted in the container as /src
cd /path/to/my/project

# Customize here your build folder name
export BUILD_DIR=build
# Create alias to run a command in the container
alias docker-run='docker run --rm -v $(pwd):/src/ --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined reivilo1234/qt-linux-cmake:qt5.15.1'

# Create build directory in host
mkdir -p $BUILD_DIR
# Execute cmake in container
docker-run cmake -B ./$BUILD_DIR/ -S . ..
# Execute make in container
docker-run make -C $BUILD_DIR -j
```

## 🔨 How to build Docker Image

Run in the same directory as the `Dockerfile`

```bash
export DOCKER_TAG=qt5.15.1
docker build --tag qt-linux-cmake:$DOCKER_TAG .
docker tag qt-linux-cmake:$DOCKER_TAG reivilo1234/qt-linux-cmake:$DOCKER_TAG
docker push reivilo1234/qt-linux-cmake:$DOCKER_TAG
```

**qt5.15.1-gcc7**


```bash
export DOCKER_TAG=qt5.15.1-gcc7
docker build --tag qt-linux-cmake:$DOCKER_TAG --build-arg GCC=7 --build-arg QT=5.15.1 .
docker tag qt-linux-cmake:$DOCKER_TAG reivilo1234/qt-linux-cmake:$DOCKER_TAG
docker push reivilo1234/qt-linux-cmake:$DOCKER_TAG
```