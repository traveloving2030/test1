docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode install -n elca_test -v 1.0 -p github.com/battery
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode install -n elca_test -v 1.0 -p github.com/battery
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca_test -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode instantiate -o orderer.battery.com:7050 -C battery -n elca_test -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config /opt/gopath/src/github.com/battery/collections_config.json

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca_test -c '{"Args":["initMarble"]}'
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode invoke -o orderer.battery.com:7050 -C battery -n elca_test -c '{"Args":["initMarble"]}'

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.battery.com/msp" peer0.org1.battery.com peer chaincode query -C battery -n elca_test -c '{"Args":["readMarble","marble1"]}'
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.battery.com/msp" peer0.org2.battery.com peer chaincode query -C battery -n elca_test -c '{"Args":["readMarblePrivateDetails","marble1"]}'



#docker logs peer0.org1.battery.com 2>&1 | grep -i -a -E 'private|pvt|privdata'

echo '-------------------------------------END-------------------------------------'

