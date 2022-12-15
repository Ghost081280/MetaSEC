#!/bin/bash

function docker_compose {
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${P0PORT}/$2/g" \
        -e "s/\${CAPORT}/$3/g" \
        docker/docker-compose.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

function docker_compose_ca {
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${P0PORT}/$2/g" \
        -e "s/\${CAPORT}/$3/g" \
        docker/docker-compose-ca.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

function docker_compose_couch {
    sed -e "s/\${ORG}/$1/g" \
        docker/docker-compose-couch.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

function fabric_ca_server_config {
    sed -e "s/\${ORG}/$1/g" \
        fabric-ca-server-config.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

function configtx_ccp {
    sed -e "s/\${ORG}/$1/g" \
        configtx.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

ORG=$1
P0PORT=$2
CAPORT=$3

echo "$(docker_compose $ORG $P0PORT $CAPORT)" > fabric-ca/$ORG/docker/docker-compose.yaml
echo "$(docker_compose_ca $ORG $P0PORT $CAPORT)" > fabric-ca/$ORG/docker/docker-compose-ca.yaml
echo "$(docker_compose_couch $ORG)" > fabric-ca/$ORG/docker/docker-compose-couch.yaml

echo "$(fabric_ca_server_config $ORG)" > fabric-ca/$ORG/fabric-ca-server-config.yaml
echo "$(configtx_ccp $ORG)" > fabric-ca/$ORG/configtx.yaml
