#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ccp-template.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

function configtx_ccp {
    sed -e "s/\${ORG}/$1/g" \
        configtx.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

ORG=$1
P0PORT="${2}"
CAPORT="${3}"
PEERPEM=../organizations/peerOrganizations/$ORG.o3.fit/tlsca/tlsca.$ORG.o3.fit-cert.pem
CAPEM=../organizations/peerOrganizations/$ORG.o3.fit/ca/ca.$ORG.o3.fit-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ../organizations/peerOrganizations/$ORG.o3.fit/connection-$ORG.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ../organizations/peerOrganizations/$ORG.o3.fit/connection-$ORG.yaml
#echo "$(configtx_ccp $ORG $P0PORT)" > fabric-ca/$ORG/configtx.yaml
