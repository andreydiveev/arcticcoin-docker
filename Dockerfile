# Build stage for BerkeleyDB
FROM alpine:3.7 as berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add openssl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Bitcoin Core
FROM alpine:3.7

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost-dev
RUN apk --no-cache add build-base
RUN apk --no-cache add chrpath
RUN apk --no-cache add git
RUN apk --no-cache add file
RUN apk --no-cache add gnupg
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add openssl
RUN apk --no-cache add openssl-dev
RUN apk --no-cache add libtool
RUN apk --no-cache add linux-headers
RUN apk --no-cache add protobuf-dev
#RUN apk --no-cache add zeromq-dev
RUN apk --no-cache add libzmq
RUN apk --no-cache add db-dev
RUN set -ex \
  && for key in \
    90C8019E36C2E964 \
  ; do \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done

ARG COIND
ARG REPO
ARG PORTP2P

WORKDIR /usr/src
RUN git clone ${REPO} coin

WORKDIR /usr/src/coin
RUN ./autogen.sh
RUN ./configure --with-incompatible-bdb
RUN make -j4
RUN strip src/${COIND}d
RUN strip src/${COIND}-cli
RUN strip src/${COIND}-tx

ENV VAR_COIND=${COIND}

WORKDIR /root

RUN cp /usr/src/coin/src/${COIND}d /root/
RUN cp /usr/src/coin/src/${COIND}-cli /root/
RUN cp /usr/src/coin/src/${COIND}-tx /root/

EXPOSE ${PORTP2P}

CMD ./${VAR_COIND}d
