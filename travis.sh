export TRAVIS_BUILD_DIR="`pwd`/timescaledb"
#before_install
docker run -d --name arm-testing -v ${TRAVIS_BUILD_DIR}:/timescaledb arm-may /bin/sleep infinity
#  install:
docker exec arm-testing /bin/bash -c "mkdir /arm_build && chown postgres /arm_build"
docker exec -u postgres arm-testing /bin/bash -c "cd /arm_build && cmake /timescaledb -DCMAKE_BUILD_TYPE=Debug && make"
docker exec arm-testing /bin/bash -c "cd /arm_build && make install"
#   after_failure:
#   after_success:
#   script:
