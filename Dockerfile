FROM resin/rpi-raspbian:stretch
ENV QEMU_RESERVED_VA=0xf700000
RUN apt-get update && apt-get install -y --no-install-recommends git libreadline-dev libstdc++6-4.6-dev build-essential cmake libpq-dev
RUN apt-get install emacs # ::todo remove this line later
# install postgres 10
RUN apt-get install postgresql-9.6 postgresql-contrib libpq-dev postgresql-server-dev-all
RUN mkdir postgres && chown postgres:postgres postgres && chmod 770 postgres && cd postgres&& pwd

USER postgres

# RUN cd postgres && git clone https://github.com/timescale/timescaledb.git && \
#     cd timescaledb && git checkout tags/1.1.1 &&					      \
#     ./bootstrap -DCMAKE_BUILD_TYPE="Debug" -DUSE_OPENSSL=0 && \
#     (cd build/; make )
# add postgres user to sudo-ers to be able to run make install
USER root
RUN chown -R postgres:postgres /usr/share/postgresql && chown -R postgres:postgres /usr/lib/postgresql && echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN apt-get install flex bison
USER postgres
#RUN cd postgres/timescaledb/build && make install

# COPY ./setup.sh /postgres/timescaledb
# COPY ./setup.sh /postgres/timescaledb/build
# COPY ./cc /postgres/timescaledb
# COPY ./cc /postgres/timescaledb/build
# COPY ./diff postgres/timescaledb
# RUN nohup /postgres/timescaledb/build/cc &

#RUN (cd postgres/timescaledb/build/;  make installcheck)
COPY ./init.sh /
COPY ./pg9.6_installed.tar.gz /postgres

ENV PATH="/postgres/pg9.6_installed/bin:${PATH}"

#ENTRYPOINT /bin/bash /postgres/init.sh