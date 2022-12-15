#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

function createOrg () {
    ORG_NAME=$1
    P0PORT=$2
    CAPORT=$3
	infoln "Enrolling the CA admin"
	mkdir -p ../organizations/peerOrganizations/${ORG_NAME}.o3.fit/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:${CAPORT} --caname ca-${ORG_NAME} --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-${ORG_NAME}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-${ORG_NAME}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-${ORG_NAME}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-${ORG_NAME}.pem
    OrganizationalUnitIdentifier: orderer" > "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/config.yaml"

	infoln "Registering peer0"
  set -x
	fabric-ca-client register --caname ca-${ORG_NAME} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-${ORG_NAME} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-${ORG_NAME} --id.name ${ORG_NAME}admin --id.secret ${ORG_NAME}adminpw --id.type admin --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${CAPORT} --caname ca-${ORG_NAME} -M "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/msp" --csr.hosts peer0.${ORG_NAME}.o3.fit --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${CAPORT} --caname ca-${ORG_NAME} -M "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls" --enrollment.profile tls --csr.hosts peer0.${ORG_NAME}.o3.fit --csr.hosts localhost --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null


  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/ca.crt"
  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/signcerts/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/server.crt"
  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/keystore/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/server.key"

  mkdir "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/tlscacerts"
  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/tlscacerts/ca.crt"

  mkdir "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/tlsca"
  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/tlsca/tlsca.${ORG_NAME}.o3.fit-cert.pem"

  mkdir "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/ca"
  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/peers/peer0.${ORG_NAME}.o3.fit/msp/cacerts/"* "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/ca/ca.${ORG_NAME}.o3.fit-cert.pem"

  infoln "Generating the user msp"
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:${CAPORT} --caname ca-${ORG_NAME} -M "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/users/User1@${ORG_NAME}.o3.fit/msp" --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/users/User1@${ORG_NAME}.o3.fit/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
	fabric-ca-client enroll -u https://${ORG_NAME}admin:${ORG_NAME}adminpw@localhost:${CAPORT} --caname ca-${ORG_NAME} -M "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/users/Admin@${ORG_NAME}.o3.fit/msp" --tls.certfiles "${PWD}/fabric-ca/${ORG_NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/${ORG_NAME}.o3.fit/users/Admin@${ORG_NAME}.o3.fit/msp/config.yaml"
}
