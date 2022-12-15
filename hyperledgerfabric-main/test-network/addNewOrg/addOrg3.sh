#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric test network by adding
# adding a third organization to the network
#

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

. ../scripts/utils.sh

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  addNewOrg.sh up|down|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>]"
  echo "  addNewOrg.sh -h|--help (print this message)"
  echo "    <mode> - one of 'up', 'down', or 'generate'"
  echo "      - 'up' - add org3 to the sample network. You need to bring up the test network and create a channel first."
  echo "      - 'down' - bring down the test network and org3 nodes"
  echo "      - 'generate' - generate required certificates and org definition"
  echo "    -c <channel name> - test network channel name (defaults to \"mychannel\")"
  echo "    -ca <use CA> -  Use a CA to generate the crypto material"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -verbose - verbose mode"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network. e.g.:"
  echo
  echo "	addNewOrg.sh generate"
  echo "	addNewOrg.sh up"
  echo "	addNewOrg.sh up -c mychannel -s couchdb"
  echo "	addNewOrg.sh down"
  echo
  echo "Taking all defaults:"
  echo "	addNewOrg.sh up"
  echo "	addNewOrg.sh down"
}

# We use the cryptogen tool to generate the cryptographic material
# (x509 certs) for the new org.  After we run the tool, the certs will
# be put in the organizations folder with org1 and org2

# Create Organziation crypto material using cryptogen or CAs
function generateOrg() {
  # Create crypto material using cryptogen
  if [ "$CRYPTO" == "cryptogen" ]; then
    which cryptogen
    if [ "$?" -ne 0 ]; then
      fatalln "cryptogen tool not found. exiting"
    fi
    infoln "Generating certificates using cryptogen tool"

    infoln "Creating ${ORG_NAME} Identities"

    set -x
    cryptogen generate --config=org3-crypto.yaml --output="../organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

  fi

  # Create crypto material using Fabric CA
  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "ERROR! fabric-ca-client binary not found.."
      echo
      echo "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
      echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
      exit 1
    fi

    infoln "Generating certificates using Fabric CA"
    docker-compose -f $COMPOSE_FILE_CA_ORG up -d 2>&1

    . registerEnroll.sh

    sleep 10

    infoln "Creating ${ORG_NAME} Identities"
    createOrg $ORG_NAME $P0PORT $CAPORT

  fi

  infoln "Generating CCP files for ${ORG_NAME}"
  ./ccp-generate.sh $ORG_NAME $P0PORT $CAPORT
}

# Generate channel configuration transaction
function generateOrgDefinition() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found. exiting"
  fi
  infoln "Generating ${ORG_NAME} organization definition"
  export FABRIC_CFG_PATH="${PWD}/fabric-ca/${ORG_NAME}/"

  set -x
  configtxgen -printOrg ${ORG_NAME}MSP > ../organizations/peerOrganizations/${ORG_NAME}.o3.fit/${ORG_NAME}.json
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate ${ORG_NAME} organization definition..."
  fi
}

function OrgUp () {
  # start org3 nodes
  if [ "${DATABASE}" == "couchdb" ]; then
    DOCKER_SOCK=${DOCKER_SOCK} docker-compose -f $COMPOSE_FILE_ORG -f $COMPOSE_FILE_COUCH_ORG up -d 2>&1
  else
    DOCKER_SOCK=${DOCKER_SOCK} docker-compose -f $COMPOSE_FILE_ORG up -d 2>&1
  fi
  if [ $? -ne 0 ]; then
    fatalln "ERROR !!!! Unable to start ${ORG_NAME} network"
  fi
}

# Generate the needed certificates, the genesis block and start the network.
function addOrg () {
    export COMPOSE_FILE_ORG_NAME=$ORG_NAME

  # If the test network is not up, abort
  if [ ! -d ../organizations/ordererOrganizations ]; then
    fatalln "ERROR: Please, run ./network.sh up createChannel first."
  fi

  # If the test network is not up, abort
  if [ ! -d fabric-ca/${ORG_NAME} ]; then
    mkdir "${PWD}/fabric-ca/${ORG_NAME}"
    mkdir "${PWD}/fabric-ca/${ORG_NAME}/docker"
    ./utils-generate.sh $ORG_NAME $P0PORT $CAPORT
  else
    fatalln "ERROR: ${ORG_NAME} already exist."
  fi

    # use this as the docker compose couch file
    COMPOSE_FILE_COUCH_ORG=fabric-ca/${ORG_NAME}/docker/docker-compose-couch.yaml
    # use this as the default docker-compose yaml definition
    COMPOSE_FILE_ORG=fabric-ca/${ORG_NAME}/docker/docker-compose.yaml
    # certificate authorities compose file
    COMPOSE_FILE_CA_ORG=fabric-ca/${ORG_NAME}/docker/docker-compose-ca.yaml

  # generate artifacts if they don't exist
  if [ ! -d "../organizations/peerOrganizations/${ORG_NAME}.o3.fit" ]; then
    generateOrg
    generateOrgDefinition
  fi

  infoln "Bringing up ${ORG_NAME} peer"
  OrgUp

  # Use the CLI container to create the configuration transaction needed to add
  # Org to the network
  infoln "Generating and submitting config tx to add ${ORG_NAME}"
  docker exec cli ./scripts/new-org-scripts/updateChannelConfig.sh $CHANNEL_NAME $ORG_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    fatalln "ERROR !!!! Unable to create config tx"
  fi

  infoln "Joining ${ORG_NAME} peers to network"
  docker exec cli ./scripts/new-org-scripts/joinChannel.sh $CHANNEL_NAME $ORG_NAME $P0PORT $CLI_DELAY $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    fatalln "ERROR !!!! Unable to join ${ORG_NAME} peers to network"
  fi
}

# Tear down running network
function networkDown () {
    cd ..
    ./network.sh down
}

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel" # channel name defaults to "mychannel"
ORG_NAME="org3"
ORG_PORT=1105
# database
DATABASE="leveldb"

# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"


# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -t )
    CLI_TIMEOUT="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -n )
    ORG_NAME="$2"
    shift
    ;;
  -p0 )
    P0PORT="$2"
    shift
    ;;
  -p1 )
    CAPORT="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done


# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  infoln "Adding '${ORG_NAME}' to channel '${CHANNEL_NAME}' with '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}'"
  echo
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping network"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and organization definition for ${ORG_NAME}"
else
  printHelp
  exit 1
fi

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
    addOrg
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateOrg
  generateOrgDefinition
else
  printHelp
  exit 1
fi
