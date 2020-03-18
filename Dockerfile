FROM ubuntu:bionic
# todo: update GCC?
# todo is parmetis using correct index type?
RUN apt-get update -qq && apt-get install wget software-properties-common -y --no-install-recommends && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update -qq && apt-get install -y -qq g++ gfortran python3 python3-pip m4 unzip git python pkg-config cxxtest cpio --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN pip3 install -- numpy 

# Need newer cmake version than provided in ubuntu repository 
RUN wget -qO- https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.tar.gz | tar -xvz -C "/" && mv "/cmake-3.16.4-Linux-x86_64" "/cmake"

RUN mkdir "src"
ENV PATH="/cmake/bin:/bin:${PATH}"
# todo cleanup step missing here
RUN wget -qO- https://github.com/hfp/libxsmm/archive/master.tar.gz | tar -xvz -C "/src" && (cd "/src/libxsmm-master" && make -j "$(nproc)" generator && cp bin/libxsmm_gemm_generator /bin && rm -rf $(pwd))

RUN wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16120/l_mpi_2019.6.166.tgz && tar xf l_mpi_2019.6.166.tgz && cd l_mpi_2019.6.166 && ./install.sh --silent silent.cfg --accept_eula
#source /opt/intel/bin/compilervars.sh -arch intel64 -platform linux
ENV cc=mpicc cxx=mpicxx f90=mpif90

# Install hdf5
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && wget -qO- https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.bz2 | tar -xvj -C / && cd hdf5-1.8.21 && CPPFLAGS=\"-fPIC ${CPPFLAGS}\" CC=mpicc FC=mpif90 ./configure --enable-parallel --prefix=/ --with-zlib --disable-shared --enable-fortran && make -j $(nproc) && make install -j $(nproc)"]

# Install parmetis
# Note idxtype needs to 64 for large simulations!
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && wget -qO- http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz | tar -xvz -C / && cd /parmetis-4.0.3/ && sed -i -e 's/#define IDXTYPEWIDTH 32/#define IDXTYPEWIDTH 64/' metis/include/metis.h && cat metis/include/metis.h | grep 'IDXTYPEWIDTH' && make config cc=mpicc cxx=mpicxx prefix=/ && make install -j $(nproc) && cp build/Linux-x86_64/libmetis/libmetis.a /lib/ && cp metis/include/metis.h /include/"]

# Install SeisSol and submodules
RUN git clone --depth=1 -- https://github.com/SeisSol/SeisSol.git "/src/SeisSol" && (cd "/src/SeisSol" && git submodule update --init)
WORKDIR /src/SeisSol
RUN mkdir submodules/ImpalaJIT/build && mkdir submodules/yaml-cpp/build && mkdir build_cmake
# Install ImpalaJIT
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cd submodules/ImpalaJIT/build && cmake -DCMAKE_INSTALL_PREFIX=/ .. && make -j $(nproc) && make install"]
# Install yaml-cpp
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cd submodules/yaml-cpp/build && cmake -DCMAKE_INSTALL_PREFIX=/ .. && make -j $(nproc) && make install"]
# Actually build & seissol
WORKDIR /src/SeisSol/build_cmake
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cmake -DCMAKE_PREFIX_PATH=/ -DMPI=ON -DOPENMP=ON -DNETCDF=OFF -DHDF5=ON -DCOMMTHREAD=ON -DMETIS=ON -DASAGI=OFF -DTESTING=OFF -DARCH=hsw -DPRECISION=double -DGEMM_TOOLS_LIST=LIBXSMM -- .."]
# TODO Merge with configuration above
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && cmake --build .  -j $(nproc)"]


#RUN useradd -ms /bin/bash seissol
#USER seissol
