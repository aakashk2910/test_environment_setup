#!/usr/bin/env bash

mkdir -p quic_tests
TEST_DIR=$PWD/quic_tests
cd quic_tests

sudo rm -rf ./build
mkdir build
cd build

#install CMAKE, Git and C
sudo apt-get -y install git-core
sudo apt-get -y install cmake
sudo apt-get -y install build-essential

#install Go
PKG_OK=$(go version|grep "go version go")
echo Checking for Go: $PKG_OK
if [ "" == "$PKG_OK" ]; then
  echo "No GO. Setting up."
  wget https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz || exit -1
  tar -xzf go1.4-bootstrap-20171003.tar.gz
  cd go/src
  sudo ./all.bash
  cd ../..
  export PATH=$PWD/go/bin:$PATH
fi

#install zlib
PKG_OK=$(ldconfig -p | grep libz.so$)
echo Checking for Zlib: $PKG_OK
if [ "" == "$PKG_OK" ]; then
  echo "No Zlib. Setting up."
  wget --no-check-certificate  https://zlib.net/zlib-1.2.11.tar.gz|| exit -1
  tar -xf zlib-1.2.11.tar.gz
  cd zlib-1.2.11/
  make distclean
  ./configure
  make
  sudo make install
  cd ..
fi

#install nghttp2
git clone https://github.com/nghttp2/nghttp2.git
cd nghttp2
sudo apt-get -y install build-essential
sudo cmake .
sudo make install
sudo ldconfig
cd ..

#install Boringssl and LSQUIC
git clone https://boringssl.googlesource.com/boringssl
cd boringssl
git checkout 49de1fc2910524c888866c7e2b0db1ba8af2a530
sudo cmake . &&  make
BORINGSSL=$PWD
https://github.com/aakashk2910/quic_perf.git
cd lsquic
git submodule init
git submodule update
#mkdir -p lib
#cd lib
#  ln -s BORINGSSL/ssl/libssl.a
#  ln -s BORINGSSL/crypto/libcrypto.a
#cd ..
sudo cmake -DBORINGSSL_DIR=$BORINGSSL .
sudo make
cd ../../

#install the test files and website lists
git clone https://github.com/aakashk2910/test_setup.git
cd test_setup

cp quic_support.txt ../boringssl/lsquic/
cp run_test.sh ../boringssl/lsquic/

mkdir ../tls_test
cp tls_perf ../tls_test/
cp run_tls.sh ../tls_test/
cp top100ktls13.txt ../tls_test/

mkdir ../quic_perf_test
cp quic_perf ../quic_perf_test
cp run_test.sh ../quic_perf_test
cp quic_support.txt ../quic_perf_test

cd ..

#install Google Drive test files
git clone https://github.com/aakashk2910/google_drive_test.git

#write out current crontab
#crontab -l > mycron
#echo new cron into cron file
echo "0 */2 * * * cd /home/ubuntu/quic_tests/build/tls_test && sudo ./run_tls.sh top100ktls13.txt

59 */2 * * * cd /home/ubuntu/quic_tests/build/quic_perf_test && sudo ./run_test.sh quic_support.txt

0 8 * * * cd /home/ubuntu/quic_tests/build/google_drive_test && sudo ./gdrive_test.sh target.csv

0 3 * * * cd /home/ubuntu/quic_tests/build/google_drive_test && sudo ./gdrive_test100.sh target_greater_than_100M.csv" >> mycron
#install new cron file
crontab mycron
rm mycron
