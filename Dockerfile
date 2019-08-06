FROM ubuntu:xenial
MAINTAINER Lukas Krenz (lukas.krenz@in.tum.de)
RUN apt-get update -qq && apt-get install wget software-properties-common -y --no-install-recommends && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update -qq && apt-get install -y -qq g++ g++-5 gfortran openmpi-bin openmpi-common libopenmpi-dev hdf5-tools libhdf5-openmpi-10 libhdf5-openmpi-dev python3 python3-pip libmetis-dev libparmetis-dev m4 unzip git python cmake pkg-config --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN pip3 install 'numpy>=1.12.0' lxml
RUN wget http://prdownloads.sourceforge.net/scons/scons-3.0.5.tar.gz && tar -xaf scons-3.0.5.tar.gz && cd scons-3.0.5 && python3 setup.py install --prefix=/usr && cd ..
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.6.1.tar.gz && tar -xaf netcdf-4.6.1.tar.gz && cd netcdf-4.6.1 && CC=h5pcc ./configure --prefix=/usr --enable-shared=no --disable-dap && make && make install && cd ..
RUN wget https://github.com/hfp/libxsmm/archive/master.zip && unzip master.zip && cd libxsmm-master && make generator && cp bin/libxsmm_gemm_generator /usr/bin && cd ..
RUN useradd -ms /bin/bash seissol