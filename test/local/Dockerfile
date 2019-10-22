FROM debian:stretch

RUN apt-get update && apt-get -y upgrade && apt-get install -y sudo man curl python3

RUN useradd x && echo 'x ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER x

COPY test.sh .
CMD sh test.sh
