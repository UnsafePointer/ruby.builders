FROM ubuntu:18.04

# Update

RUN apt-get update

# SDL2

RUN apt-get -y install libsdl2-dev

# CMake

RUN apt-get -y install cmake

# GCC 9

RUN apt-get -y install software-properties-common &&\
    add-apt-repository -y ppa:ubuntu-toolchain-r/test &&\
    apt-get update &&\
    apt-get -y install gcc-9 g++-9 &&\
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 --slave /usr/bin/g++ g++ /usr/bin/g++-9 --slave /usr/bin/gcov gcov /usr/bin/gcov-9

# Other tools

RUN apt-get -y install curl

# pip

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&\
    python3 get-pip.py &&\
    rm -rf get-pip.py

# Buildbot

RUN pip install buildbot-worker

# User

RUN groupadd --gid 1000 buildbot \
    && useradd --uid 1000 --gid buildbot --shell /bin/bash --create-home buildbot

USER buildbot

WORKDIR /home/buildbot
