FROM ubuntu:bionic
# todo: update gcc?

# TODO Compile with mpicc etc
RUN apt-get update -qq && apt-get install wget software-properties-common -y --no-install-recommends && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt-get update -qq && apt-get install -y -qq g++ g++-5 gfortran openmpi-bin openmpi-common libopenmpi-dev hdf5-tools libhdf5-openmpi-100 libhdf5-openmpi-dev python3 python3-pip libmetis-dev libparmetis-dev m4 unzip git python pkg-config cxxtest libparmetis4.0 libparmetis-dev --no-install-recommends # && rm -rf /var/lib/apt/lists/*
# CMake, todo: replace by version below...
#RUN apt-get update -qq && apt-get install -y --no-install-recommends cmake

RUN useradd -ms /bin/bash seissol
USER seissol

RUN wget -qO- https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.tar.gz | tar -xvz -C "${HOME}" && mv "${HOME}/cmake-3.16.4-Linux-x86_64" "${HOME}/cmake"

RUN mkdir "$HOME/src" && mkdir "${HOME}/bin"
ENV PATH="/home/seissol/cmake/bin:/home/seissol/bin:${PATH}"
#WORKDIR /home/seissol/src
# todo cleanup step missing here
RUN wget -qO- https://github.com/hfp/libxsmm/archive/master.tar.gz | tar -xvz -C "${HOME}/src" && (cd "$HOME/src/libxsmm-master" && make -j "$(nproc)" generator && cp bin/libxsmm_gemm_generator ~/bin && rm -rf $(pwd))

# todo env use mpi compilers

RUN git clone --depth=1 -- https://github.com/SeisSol/SeisSol.git "${HOME}/src/SeisSol" && (cd "${HOME}/src/SeisSol" && git submodule update --init)
WORKDIR /home/seissol/src/SeisSol

RUN mkdir submodules/ImpalaJIT/build && mkdir submodules/yaml-cpp/build && mkdir build_cmake
# Install ImpalaJIT
RUN cd submodules/ImpalaJIT/build && cmake -DCMAKE_INSTALL_PREFIX=$HOME .. && make -j "$(nproc)" && make install
# Install yaml-cpp
RUN cd submodules/yaml-cpp/build && cmake -DCMAKE_INSTALL_PREFIX=$HOME .. && make -j "$(nproc)" && make install

# Build seissol
RUN pip3 install --user -- numpy 

WORKDIR /home/seissol/src/SeisSol/build_cmake
RUN cmake -DCMAKE_PREFIX_PATH=$HOME -DNETCDF=OFF -DHDF5=ON -DCOMMTHREAD=OFF -DMETIS=ON -DASAGI=OFF -DTESTING=OFF -DARCH=hsw -DPRECISION=double -DGEMM_TOOLS_LIST=LIBXSMM -- ..
RUN cmake --build .  -j "$(nproc)"

#RUN PATH=$HOME/bin:$PATH make -j4

#RUN wget https://syncandshare.lrz.de/dl/fiJNAokgbe2vNU66Ru17DAjT/netcdf-4.6.1.tar.gz && tar -xaf netcdf-4.6.1.tar.gz && cd netcdf-4.6.1 && CC=h5pcc ./configure --prefix=/usr --enable-shared=no --disable-dap && make && make install && cd ..
