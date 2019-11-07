#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

function replacePrivateKey() {
    echo "ca key file exchange"
    cp docker-compose-template.yml docker-compose.yml
    PRIV_KEY=$(ls crypto-config/peerOrganizations/org1.battery.com/ca/ | grep _sk)
    sed -i "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
}

function checkPrereqs() {
    # check config dir
    if [ ! -d "crypto-config" ]; then
        echo "crypto-config dir missing"
        exit 1
    fi
    # check crypto-config dir
     if [ ! -d "config" ]; then
        echo "config dir missing"
        exit 1
    fi
}

checkPrereqs
replacePrivateKey

docker-compose -f docker-compose.yml down

replacePrivateKey

docker-compose -f docker-compose.yml up -d 
docker ps -a

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec cli peer channel create -o orderer.battery.com:7050 -c battery -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.battery.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer channel join -b /etc/hyperledger/configtx/battery.block
sleep 5

#Join peer1.org1.battery.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer1.org1.battery.com peer channel join -b /etc/hyperledger/configtx/battery.block
sleep 5

# Join peer0.org2.battery.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer channel join -b /etc/hyperledger/configtx/battery.block
sleep 5

#Join peer1.org2.battery.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer1.org2.battery.com peer channel join -b /etc/hyperledger/configtx/battery.block
sleep 5

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode install -n elca_test -v 1.0 -p github.com/battery
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode install -n elca_test -v 1.0 -p github.com/battery
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca_test -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca_test -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca_test -c '{"Args":["initMarble"]}'
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca_test -c '{"Args":["initMarble"]}'
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode query -C battery -n elca_test -c '{"Args":["readMarble","marble1"]}'
sleep 5
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode query -C battery -n elca_test -c '{"Args":["readMarblePrivateDetails","marble1"]}'
sleep 5


#docker logs peer0.org1.battery.com 2>&1 | grep -i -a -E 'private|pvt|privdata'

echo '-------------------------------------END-------------------------------------'

