FROM resin/rpi-raspbian:stretch

RUN apt-get update && apt-get install -y --no-install-recommends git libreadline-dev libstdc++6-4.6-dev build-essential cmake libpq-dev

# install postgres 10
RUN apt-get install postgresql-9.6 postgresql-contrib libpq-dev postgresql-server-dev-all
RUN mkdir postgres && chown postgres:postgres postgres && chmod 770 postgres && cd postgres&& pwd

USER postgres
RUN cd postgres && git clone https://github.com/timescale/timescaledb.git && \
    cd timescaledb &&					      \
    ./bootstrap -DCMAKE_BUILD_TYPE="Debug" -DUSE_OPENSSL=0 && \
    (cd build/; make )
USER root
RUN cd postgres/timescaledb/build && make install
USER postgres

#RUN (cd postgres/timescaledb/build/;  make installcheck)