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
#ENV PG_MAJOR 11 # todo:: is this necessary?
ENV PG_VERSION 9.6.6

# needs to go _before_ calling localedef
ENV LANG en_US.utf8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/*

# this is how the step is done in other similar docker files but the file path is different here
#RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8

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


# make the sample config easier to munge (and "correct by default")
RUN sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/local/pgsql/share/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql

ENV PATH $PATH:/usr/local/pgsql/bin
ENV PGDATA /var/lib/postgresql/data
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA" # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /usr/local/bin/

#todo:: do not hardcode git tag
RUN git clone --single-branch --branch REL9_6_6 --depth 1 https://github.com/postgres/postgres.git /postgresqlsrc

# build complementary tools needed for installcheck not provided in the postgres zip download
RUN cd /postgresqlsrc \
  && ./configure --prefix=/usr/local/pgsql --enable-debug --enable-cassert --without-readline --without-zlib \
  && make -C /postgresqlsrc/src/test/regress \
  && make -C /postgresqlsrc/src/test/isolation

RUN ln -s /postgresqlsrc/src/test/regress/pg_regress /usr/local/pgsql/bin/pg_regress && \
    ln -s /postgresqlsrc/src/test/isolation/pg_isolation_regress /usr/local/pgsql/bin/pg_isolation_regress

#RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]