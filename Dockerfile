FROM gcc as builder
ENV OPENSSL_VERSION=1.1.1t
RUN wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz && \
    tar zxvf openssl-$OPENSSL_VERSION.tar.gz && \
    cd openssl-$OPENSSL_VERSION && \
    ./config shared enable-ssl3-method enable-ssl3 enable-weak-ssl-ciphers enable-ssl-trace && \
    make depend && \
    make -j8 && \
    make install

FROM library/debian:bullseye
COPY --from=builder /usr/local/bin/openssl /usr/local/bin
COPY --from=builder /usr/local/lib64 /usr/local/lib64
RUN echo "/usr/local/lib64" > /etc/ld.so.conf.d/openssl.conf && \
    ldconfig

RUN mkdir -p /opt/project
WORKDIR /opt/project

# Installing debian packages
COPY debian_packages.txt    /opt/project/debian_packages.txt
RUN apt-get update --allow-insecure-repositories && \
    DEBIAN_FRONTEND=noninteractive xargs -a /opt/project/debian_packages.txt \
    apt-get install -y --allow-unauthenticated && \
    apt-get clean && \
    rm -rf /opt/project/debian_packages.txt

# Ignore warnings during requests calls
ENV PYTHONWARNINGS="ignore:Unverified HTTPS request"
# Installing python packags
RUN pip3 install poetry toml mock


