FROM resin/rpi-raspbian:stretch
ENV QEMU_RESERVED_VA=0xf700000
RUN apt-get update && apt-get install -y --no-install-recommends git libreadline-dev libstdc++6-4.6-dev build-essential cmake libpq-dev
RUN apt-get install emacs # ::todo remove this line later

RUN set -ex; \
		apt-get update; \
		apt-get install -y --no-install-recommends \
      make \
      cmake \
      wget \
		;
		#rm -rf /var/lib/apt/lists/*;


# explicitly set user/group IDs
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

# add postgres user to sudo-ers to be able to run make install
#USER root
RUN mkdir postgres && chown postgres:postgres postgres && chmod 770 postgres && cd postgres&& pwd
#RUN chown -R postgres:postgres /usr/share/postgresql && chown -R postgres:postgres /usr/lib/postgresql && #echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN apt-get install flex bison
RUN apt-get install openssl libssl-dev
ENV LANG en_US.utf8
#ENV PG_MAJOR 11 # todo:: is this necessary?
ENV PG_VERSION 9.6.6

RUN set -ex \
  && wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" \
       && mkdir -p /usr/src/postgresql \
       && tar \
               --extract \
               --file postgresql.tar.bz2 \
               --directory /usr/src/postgresql \
               --strip-components 1 \
       && rm postgresql.tar.bz2 \
  && cd /usr/src/postgresql \
  && ./configure \
  	   --with-openssl \
	    --without-zlib \
      --enable-cassert \
      --enable-debug \
      CFLAGS=-ggdb \
  && make \
  && make install

#todo:: do not hardcode git tag
RUN git clone --single-branch --branch REL9_6_6 --depth 1 https://github.com/postgres/postgres.git /postgresqlsrc

COPY ./docker-entrypoint.sh /
COPY ./pg9.6_installed.tar.gz /postgres

ENV PATH="/postgres/pg9.6_installed/bin:${PATH}"

