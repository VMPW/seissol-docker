# https://blog.jetbrains.com/clion/2020/01/using-docker-with-clion/
FROM seissol:v0

RUN apt-get update \
  && apt-get install -y ssh \
      build-essential \
      gcc \
      g++ \
      gdb \
      clang \
      cmake \
      rsync \
      tar \
      python \
  && apt-get clean

RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PermitRootLogin yes'; \
    echo 'PasswordAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_test_clion \
  && mkdir /run/sshd && chmod 744 /run/sshd

# Save environment in /etc/environment s.t. clion is able to use it
RUN ["/bin/bash", "-c", "source /opt/intel/bin/compilervars.sh -arch intel64 && echo \"$(env)\" > /etc/environment"]

RUN useradd -m user \
    && yes password | passwd user \
	&& usermod -s /bin/bash user

#RUN echo 'source /opt/intel/bin/compilervars.sh -arch intel64' >> /home/user/.bashrc

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config_test_clion"]
