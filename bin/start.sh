#!/bin/sh
cd /app

mkdir /data

# Use Env variables in Config
## Change Network Config if needed
echo "Setup configs..."
if [ "$NETWORK" == "testnet" ]
then
    sed -i 's/livenet/testnet/g' flocore-node.json
fi
if [ "$NETWORK" == "regtest" ]
then
  sed -i 's/livenet/regtest/g' flocore-node.json
fi
## Add Seednode config for fcoin if needed
if ! [ -z "$ADDNODE" ]
then
    echo nodes="$ADDNODE" > /data/fcoin.conf
fi
## Add any custom config values
if [ ! -z "$CUSTOM_FCOIN_CONFIG" ]
then
    echo -e "${CUSTOM_FCOIN_CONFIG}" >> /data/fcoin.conf
fi

## Download the Blockchain Bootstrap if set
if [ ! -z "$BLOCKCHAIN_BOOTSTRAP" ] && [ "$(cat /data/bootstrap-url.txt)" != "$BLOCKCHAIN_BOOTSTRAP" ]
then
  # download and extract a Blockchain bootstrap
  echo 'Downloading Blockchain Bootstrap...'
  RUNTIME="$(date +%s)"
  curl -L $BLOCKCHAIN_BOOTSTRAP -o /data/bootstrap.tar.gz --progress-bar | tee /dev/null
  RUNTIME="$(($(date +%s)-RUNTIME))"
  echo "Blockchain Bootstrap Download Complete (took ${RUNTIME} seconds)"
  echo 'Extracting Bootstrap...'
  RUNTIME="$(date +%s)"
  tar -xzf /data/bootstrap.tar.gz -C /data
  RUNTIME="$(($(date +%s)-RUNTIME))"
  echo "Blockchain Bootstrap Extraction Complete! (took ${RUNTIME} seconds)"
  
  # Check if the necessary folders 'blocks' or 'testnet' are in the root of /data
  if [ ! -d /data/blocks ] && [ ! -d /data/testnet ]; then
      # Attempt to find a directory that does contain these folders
      for d in /data/*; do
          if [ -d "$d/blocks" ] || [ -d "$d/testnet" ]; then
              # We found the directory with our data, move everything to /data
              echo "Moving extracted files to the root of /data..."
              mv $d/* /data
              rmdir $d
              break
          fi
      done
  fi

  rm -f /data/bootstrap.tar.gz
  echo 'Erased Blockchain Bootstrap `.tar.gz` file'
  echo "$BLOCKCHAIN_BOOTSTRAP" > /data/bootstrap-url.txt
  ls /data
fi

# Currently fcoin requires us to create these directories
echo "Pregenerate fcoin directories"
mkdir /data/blocks
mkdir /data/testnet
mkdir /data/testnet/blocks
mkdir /data/regtest
mkdir /data/regtest/blocks

echo "Config setup complete!"

# Initial Startup of Flosight
echo "Starting FLO Explorer $NETWORK"
/app/bin/flocore-node start > /data/latest.log &
# Store PID for later
echo $! > /data/flosight.pid

# Allow to startup
timeout 1m tail -n 100 -f /data/latest.log

# Initialize block sync check file
curl --silent http://localhost:80/api/status?q=getBestBlockHash > currentHealthCheck.log
echo 'different' > previousHealthCheck.log

# Every 5 minutes
while true; do
  # Check to see if the most recent block hash is the same as the last time we checked.
  if [ "$(cat previousHealthCheck.log)" == "$(cat currentHealthCheck.log)" ] 
  then
      # Restart instance
      echo "NO NEW BLOCKS IN 5+ MINUTES - RESTARTING PROCESS"
      kill -2 $(cat /data/flosight.pid)
      wait $(cat /data/flosight.pid)
      /app/bin/flocore-node start >> /data/latest.log &
      # Store PID for later
      echo $! > /data/flosight.pid
  fi
  # Wait 5 minutes before checking again
  timeout 5m tail -f /data/latest.log

  mv currentHealthCheck.log previousHealthCheck.log
  curl --silent http://localhost:80/api/status?q=getBestBlockHash > currentHealthCheck.log
done;
