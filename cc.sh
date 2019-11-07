docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.battery.com/users/Admin@org1.battery/msp" cli peer chaincode install -n elca4 -v 1.0 -p github.com/battery
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.battery.com/users/Admin@org2.battery/msp" cli peer chaincode install -n elca4 -v 1.0 -p github.com/battery
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.battery.com/users/Admin@org1.battery/msp" cli peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca4 -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.battery.com/users/Admin@org2.battery/msp" cli peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca4 -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.battery.com/users/Admin@org1.battery/msp" cli peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca4 -c '{"Args":["initMarble"]}'
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.battery.com/users/Admin@org2.battery/msp" cli peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca4 -c '{"Args":["initMarble"]}'

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.battery.com/users/Admin@org1.battery/msp" cli peer chaincode query -C battery -n elca4 -c '{"Args":["readMarble","marble1"]}'
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.battery.com/users/Admin@org2.battery/msp" cli peer chaincode query -C battery -n elca -c '{"Args":["readMarblePrivateDetails","marble1"]}'



#docker logs peer0.org1.battery.com 2>&1 | grep -i -a -E 'private|pvt|privdata'

echo '-------------------------------------END-------------------------------------'

