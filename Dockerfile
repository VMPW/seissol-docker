FROM ubuntu:bionic
# todo: update GCC?
# todo is parmetis using correct index type?
RUN apt-get update -qq && apt-get install wget software-properties-common -y --no-install-recommends && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update -qq && apt-get install -y -qq g++ g++-5 gfortran python3 python3-pip libmetis-dev libparmetis-dev m4 unzip git python pkg-config cxxtest libparmetis4.0 libparmetis-dev --no-install-recommends # && rm -rf /var/lib/apt/lists/*
# CMake, todo: replace by version below...
#RUN apt-get update -qq && apt-get install -y --no-install-recommends cmake

#RUN useradd -ms /bin/bash seissol
#USER seissol
RUN pip3 install -- numpy 

RUN wget -qO- https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.tar.gz | tar -xvz -C "/" && mv "/cmake-3.16.4-Linux-x86_64" "/cmake"

RUN mkdir "src"
ENV PATH="/seissol/cmake/bin:/seissol/bin:${PATH}"
#WORKDIR /home/seissol/src
# todo cleanup step missing here
RUN wget -qO- https://github.com/hfp/libxsmm/archive/master.tar.gz | tar -xvz -C "/src" && (cd "/src/libxsmm-master" && make -j "$(nproc)" generator && cp bin/libxsmm_gemm_generator /bin && rm -rf $(pwd))

# todo env use mpi compilers
RUN wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16120/l_mpi_2019.6.166.tgz && tar xf l_mpi_2019.6.166.tgz && cd l_mpi_2019.6.166 && apt-get install cpio && ./install.sh --silent silent.cfg --accept_eula
#source /opt/intel/bin/compilervars.sh -arch intel64 -platform linux

RUN git clone --depth=1 -- https://github.com/SeisSol/SeisSol.git "/src/SeisSol" && (cd "/src/SeisSol" && git submodule update --init)
#WORKDIR /src/SeisSol
ENV PATH="/cmake/bin:/bin:${PATH}"
#WORKDIR /
WORKDIR /src/SeisSol

# Install SeisSol/dependencies.
# Note that OCI containers don't support SHELL command, so we need to use source manually
RUN mkdir submodules/ImpalaJIT/build && mkdir submodules/yaml-cpp/build && mkdir build_cmake
# Install ImpalaJIT
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cd submodules/ImpalaJIT/build && cmake -DCMAKE_INSTALL_PREFIX=/ .. && make -j $(nproc) && make install"]
# Install yaml-cpp
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cd submodules/yaml-cpp/build && cmake -DCMAKE_INSTALL_PREFIX=/ .. && make -j $(nproc) && make install"]

# Build seissol
WORKDIR /src/SeisSol/build_cmake
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cd / && wget -qO- https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.bz2 | tar -xvj -C / && cd hdf5-1.8.21 && CPPFLAGS=\"-fPIC ${CPPFLAGS}\" CC=mpicc FC=mpif90 ./configure --enable-parallel --prefix=/ --with-zlib --disable-shared --enable-fortran && make -j $(nproc) && make install -j $(nproc)"]
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cmake -DCMAKE_PREFIX_PATH=/ -DMPI=ON -DOPENMP=ON -DNETCDF=OFF -DHDF5=ON -DCOMMTHREAD=ON -DMETIS=ON -DASAGI=OFF -DTESTING=OFF -DARCH=hsw -DPRECISION=double -DGEMM_TOOLS_LIST=LIBXSMM -- .."]
# TODO Merge with configuration above
RUN cmake --build .  -j "$(nproc)"

SHELL ["/bin/bash", ""]
