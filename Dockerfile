FROM ubuntu:xenial
MAINTAINER Lukas Krenz (lukas.krenz@in.tum.de)
RUN apt update -qq 
RUN apt install wget software-properties-common -y
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt update -qq
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.6.1.tar.gz
RUN wget http://prdownloads.sourceforge.net/scons/scons-3.0.5.tar.gz
RUN wget https://github.com/hfp/libxsmm/archive/master.zip

RUN apt install -y -qq g++-5 gfortran openmpi-bin openmpi-common libopenmpi-dev hdf5-tools libhdf5-openmpi-10 libhdf5-openmpi-dev python3 python3-pip libmetis-dev libparmetis-dev m4 unzip git python cmake
RUN pip3 install --upgrade pip
RUN pip3 install 'numpy>=1.12.0' lxml
RUN tar -xaf scons-3.0.5.tar.gz
RUN cd scons-3.0.5 && python3 setup.py install --prefix=/usr && cd ..
RUN tar -xaf netcdf-4.6.1.tar.gz
RUN cd netcdf-4.6.1 && CC=h5pcc ./configure --prefix=/usr --enable-shared=no --disable-dap && make && make install && cd ..
RUN unzip master.zip
RUN cd libxsmm-master && make generator && cp bin/libxsmm_gemm_generator /usr/bin && cd ..

