FROM ubuntu:bionic
MAINTAINER Lukas Krenz (lukas.krenz@in.tum.de)
# todo: update gcc?

# TODO Compile with mpicc etc
RUN apt-get update -qq && apt-get install wget software-properties-common -y --no-install-recommends && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update -qq && apt-get install -y -qq g++ g++-5 gfortran openmpi-bin openmpi-common libopenmpi-dev hdf5-tools libhdf5-openmpi-100 libhdf5-openmpi-dev python3 python3-pip libmetis-dev libparmetis-dev m4 unzip git python pkg-config cxxtest libparmetis4.0 libparmetis-dev --no-install-recommends # && rm -rf /var/lib/apt/lists/*
# CMake, todo: replace by version below...
RUN apt-get update -qq && apt-get install -y --no-install-recommends cmake

RUN useradd -ms /bin/bash seissol
USER seissol

RUN mkdir $HOME/src
WORKDIR /home/seissol/src
RUN mkdir /home/seissol/bin
# todo cleanup step missing here
RUN wget https://github.com/hfp/libxsmm/archive/master.zip && unzip master.zip && cd libxsmm-master && make generator && cp bin/libxsmm_gemm_generator ~/bin && cd ..

RUN git clone https://github.com/SeisSol/SeisSol.git && cd SeisSol && git submodule update --init

# todo env use mpi compilers
WORKDIR /home/seissol/src/SeisSol

RUN mkdir submodules/ImpalaJIT/build && mkdir submodules/yaml-cpp/build && mkdir build_cmake
# Install ImpalaJIT
RUN ls && cd submodules/ImpalaJIT/build && cmake -DCMAKE_INSTALL_PREFIX=$HOME .. && make -j 4 && make install
# Install yaml-cpp
RUN cd submodules/yaml-cpp/build && cmake -DCMAKE_INSTALL_PREFIX=$HOME .. && make -j4 && make install

# Build seissol

# cmake
RUN cd $HOME && wget https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.tar.gz && tar xf cmake-3.16.4-Linux-x86_64.tar.gz
RUN pip3 install --user -- numpy 

WORKDIR /home/seissol/src/SeisSol/build_cmake
RUN /home/seissol/cmake-3.16.4-Linux-x86_64/bin/cmake -DCMAKE_PREFIX_PATH=$HOME -DNETCDF=OFF -DHDF5=ON -DCOMMTHREAD=OFF -DMETIS=ON -DASAGI=OFF -DTESTING=OFF -DARCH=hsw -DPRECISION=double -DGEMM_TOOLS_LIST=LIBXSMM -- ..
RUN PATH=$HOME/bin:$PATH make -j4




#RUN wget https://syncandshare.lrz.de/dl/fiJNAokgbe2vNU66Ru17DAjT/netcdf-4.6.1.tar.gz && tar -xaf netcdf-4.6.1.tar.gz && cd netcdf-4.6.1 && CC=h5pcc ./configure --prefix=/usr --enable-shared=no --disable-dap && make && make install && cd ..
