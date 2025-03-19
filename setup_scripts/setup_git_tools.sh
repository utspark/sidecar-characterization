#!/bin/bash
SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
PARENTDIR=$(builtin cd $SCRIPTDIR; pwd)

mkdir -p $PARENTDIR/build/bin
# Install wrk2
cd $PARENTDIR/tools/wrk2
make
sudo cp wrk $PARENTDIR/build/bin/

# Install pmu-tools
cd $PARENTDIR/tools/pmu-tools
sudo cp toplev $PARENTDIR/build/bin/

echo "export PATH=\"$PARENTDIR/build/bin/:\$PATH\"" >> ~/.bashrc
