FROM alpine:3.7

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

FROM alpine:3.7

RUN apk --no-cache add boost-system
RUN apk --no-cache add boost-filesystem
RUN apk --no-cache add boost-program_options
RUN apk --no-cache add boost-thread
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add openssl
RUN apk --no-cache add db-dev

COPY --from=0 /usr/lib/libboost_chrono-mt.so.1.62.0 /usr/lib/

ARG COIND
ARG PORTP2P

ENV VAR_COIND=${COIND}

WORKDIR /root

COPY --from=0 /usr/src/coin/src/${COIND}d /root/
COPY --from=0 /usr/src/coin/src/${COIND}-cli /root/
COPY --from=0 /usr/src/coin/src/${COIND}-tx /root/

EXPOSE ${PORTP2P}

CMD ./${VAR_COIND}d
