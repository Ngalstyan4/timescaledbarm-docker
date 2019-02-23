cd /postgres
tar -zxf pg9.6_installed.tar.gz
export PATH=/postgres/pg9.6_installed/bin:$PATH
cp -r /timescaledb . # no permission to write to /timescaledb
chown -R postgres:postgres timescaledb
cd timescaledb
./bootstrap -DCMAKE_BUILD_TYPE="Debug" -DUSE_OPENSSL=0
(cd build/;  make; make install)
 
