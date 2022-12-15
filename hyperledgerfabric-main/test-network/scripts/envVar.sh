#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/o3.fit/orderers/orderer.o3.fit/msp/tlscacerts/tlsca.o3.fit-cert.pem
export PEER0_org1_CA=${PWD}/organizations/peerOrganizations/org1.o3.fit/peers/peer0.org1.o3.fit/tls/ca.crt
export PEER0_org2_CA=${PWD}/organizations/peerOrganizations/org2.o3.fit/peers/peer0.org2.o3.fit/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.o3.fit/peers/peer0.org3.o3.fit/tls/ca.crt
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/o3.fit/orderers/orderer.o3.fit/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/o3.fit/orderers/orderer.o3.fit/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  USING_ORG=$1
  USING_PORT=$2

  infoln "Using organization ${USING_ORG} - Port: ${USING_PORT}"
  if [ $USING_ORG == "org1" ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_org1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/$USING_ORG.o3.fit/users/Admin@$USING_ORG.o3.fit/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG == "org2" ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_org2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.o3.fit/users/Admin@org2.o3.fit/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG == "org3" ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.o3.fit/users/Admin@org3.o3.fit/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    export CORE_PEER_LOCALMSPID="${USING_ORG}MSP"
    export PEER0_${USING_ORG}_CA=${PWD}/organizations/peerOrganizations/${USING_ORG}.o3.fit/peers/peer0.${USING_ORG}.o3.fit/tls/ca.crt
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${USING_ORG}.o3.fit/peers/peer0.${USING_ORG}.o3.fit/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${USING_ORG}.o3.fit/users/Admin@${USING_ORG}.o3.fit/msp
    export CORE_PEER_ADDRESS=localhost:${USING_PORT}

    echo "envVAR ${USING_ORG} Port: ${USING_PORT} Path: ${CORE_PEER_MSPCONFIGPATH}"
    echo $PEER0_org1_CA
    echo $CORE_PEER_ADDRESS
#    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1 $2

  local USING_ORG=""
#  if [ -z "$OVERRIDE_ORG" ]; then
#    USING_ORG=$1
#    USING_PORT=$2
#  else
#    USING_ORG="${OVERRIDE_ORG}"
#  fi
    USING_ORG=$1
    USING_PORT=$2
  if [ $USING_ORG == "org1" ]; then
    export CORE_PEER_ADDRESS=peer0.org1.o3.fit:7051
  elif [ $USING_ORG == "org2" ]; then
    export CORE_PEER_ADDRESS=peer0.org2.o3.fit:9051
  else
    export CORE_PEER_ADDRESS=peer0.${USING_ORG}.o3.fit:${USING_PORT}
#    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
echo "I Parse ${1}"
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
