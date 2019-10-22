FROM debian:stretch

RUN apt-get update && apt-get -y upgrade && apt-get install -y sudo man curl python3

RUN useradd x && echo 'x ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER x

COPY . ./www

RUN sudo install -d -m 0755 -o 1000 /nix
RUN (cd /www && python3 -m http.server --bind localhost) & sleep 3 && curl http://localhost:8000/install.sh | bash

ENV PATH "/nix/env/bin:${PATH}"
ENV MANPATH "/nix/env/share/man:${MANPATH}"
ENV NIX_SSL_CERT_FILE /nix/env/etc/ssl/certs/ca-bundle.crt

CMD nix --version && nix-store -q --tree $(realpath $(which nix)) | cat && nix-store --gc --print-roots
