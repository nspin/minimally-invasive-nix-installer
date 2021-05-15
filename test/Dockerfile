FROM debian:stretch

RUN apt-get update && apt-get -y upgrade && apt-get install -y sudo man curl python3

RUN useradd -m x && echo 'x ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /home/x
USER x

ARG install_location

COPY nix.conf /etc/nix/
COPY test-expressions/ test-expressions
COPY scripts/install.${install_location}.sh install.sh
COPY scripts/env.sh .
COPY scripts/test.sh .

CMD bash install.sh && bash test.sh
