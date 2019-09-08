#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="1500"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ptunstad.no/orderers/orderer.ptunstad.no/msp/tlscacerts/tlsca.ptunstad.no-cert.pem
PEER0_ORG1_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer0.org1.ptunstad.no/tls/ca.crt

CC_SRC_PATH="github.com/hyperledger/fabric/examples/chaincode/go"
#if [ "$LANGUAGE" = "node" ]; then
#	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
#fi

#if [ "$LANGUAGE" = "java" ]; then
#	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
#fi

echo "Channel name : "$CHANNEL_NAME

#Custom config vars
#Prevents "Minimum memory limit allowed is 4MB" error on low RAM devices (like RasPi)
CORE_VM_DOCKER_HOSTCONFIG_MEMORY=536870912
# Sets the default images to use my build for the ARM architecture
CORE_CHAINCODE_BUILDER=ptunstad/fabric-ccenv:arm64-1.4.1 
CORE_CHAINCODE_GOLANG=ptunstad/fabric-baseos:arm64-0.4.15 
CORE_CHAINCODE_CAR=ptunstad/fabric-baseos:arm64-0.4.15 
### CORE_CHAINCODE_JAVA=apelser/fabric-javaenv:arm64-1.4.1

echo "Channel name : "$CHANNEL_NAME


verifyResult () {
  if [ $1 -ne 0 ] ; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
      exit 1
  fi
}


# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ptunstad.no/orderers/orderer.ptunstad.no/msp/tlscacerts/tlsca.ptunstad.no-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ptunstad.no/users/Admin@ptunstad.no/msp
}

setGlobals () {
  PEER=$1
  ORG=$2
  if [ $ORG -eq 1 ]; then
    CORE_PEER_LOCALMSPID="Org1MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/users/Admin@org1.ptunstad.no/msp
    if [ $1 -eq 0 -o $1 -eq 1 ] ; then
      
      if [ $1 -eq 0 ]; then
        CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer0.org1.ptunstad.no/tls/server.crt
        CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer0.org1.ptunstad.no/tls/server.key
        CORE_PEER_ADDRESS=peer0.org1.ptunstad.no:7051
      else
        CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer1.org1.ptunstad.no/tls/server.crt
        CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer1.org1.ptunstad.no/tls/server.key
        CORE_PEER_ADDRESS=peer1.org1.ptunstad.no:7051
      fi
    else
      if [ $1 -eq 2 ]; then
        CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer2.org1.ptunstad.no/tls/server.crt
        CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer2.org1.ptunstad.no/tls/server.key
        CORE_PEER_ADDRESS=peer2.org1.ptunstad.no:7051
      else
        CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer3.org1.ptunstad.no/tls/server.crt
        CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.ptunstad.no/peers/peer3.org1.ptunstad.no/tls/server.key
        CORE_PEER_ADDRESS=peer3.org1.ptunstad.no:7051
      fi
    fi
  else
    echo "================== ERROR !!! ORG Unknown =================="
    fi

  if [ "$VERBOSE" == "true" ]; then
      env | grep CORE
    fi
}


updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
    peer channel update -o orderer.ptunstad.no:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
                set +x
  else
                set -x
    peer channel update -o orderer.ptunstad.no:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
                set +x
  fi
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
  sleep $DELAY
  echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

        set -x
  peer channel join -b $CHANNEL_NAME.block  >&log.txt
  res=$?
        set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=` expr $COUNTER + 1`
    echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannelWithRetry $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

installChaincode () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.2}
        set -x
  peer chaincode install -n mycode -v ${VERSION} -l ${LANGUAGE} -p github.com/hyperledger/fabric/examples/chaincode/go/tuna_chaincode >&log.txt
  res=$?
        set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
  echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
  echo
}

instantiateChaincode () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.2}

  # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
  # lets supply it directly as we know it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
    peer chaincode instantiate -o orderer.ptunstad.no:7050 -C $CHANNEL_NAME -n mycode -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org1MSP.member')" >&log.txt ## '{"Args":["c","asdf"]}'
    res=$?
                set +x
  else
                set -x
    peer chaincode instantiate -o orderer.ptunstad.no:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycode -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init"]}' -P "OR  ('Org1MSP.peer','Org2MSP.peer')" >&log.txt
    res=$?
                set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  echo
}

chaincodeInvoke () {
        PEER=$1
        setGlobals $PEER
        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer chaincode invoke -o orderer.ptunstad.no:7050 -C $CHANNEL_NAME -n mycode -c '{"Args":["initLedger"]}' >&log.txt
        else
                peer chaincode invoke -o orderer.ptunstad.no:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycode -c '{"Args":["initLedger"]}'
        fi
        res=$?
        cat log.txt
        verifyResult $res "Invoke2 execution on PEER$PEER failed "
        echo "===================== Invoke2 transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
        echo
}

chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n mycode -c '{"Args":["queryTuna","0"]}' >&log.txt
    res=$?
    set +x
    test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    # removed the string "Query Result" from peer chaincode query command
    # result. as a result, have to support both options until the change
    # is merged.
    test $rc -ne 0 && VALUE=$(cat log.txt | egrep '^[0-9]+$')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}

# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
fetchChannelConfig() {
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  echo "Fetching the most recent configuration block for the channel"
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer.ptunstad.no:7050 -c $CHANNEL --cafile $ORDERER_CA
    set +x
  else
    set -x
    peer channel fetch config config_block.pb -o orderer.ptunstad.no:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    set +x
  fi

  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"
  set +x
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and signing the config update
signConfigtxAsPeerOrg() {
        PEERORG=$1
        TX=$2
        setGlobals 0 $PEERORG
        set -x
        peer channel signconfigtx -f "${TX}"
        set +x
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx which transitions between the two
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config > original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config > modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb > config_update.pb
  configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${OUTPUT}"
  set +x
}

# parsePeerConnectionParameters $@
# Helper function that takes the parameters from a chaincode operation
# (e.g. invoke, query, instantiate) and checks for an even number of
# peers and associated org, then sets $PEER_CONN_PARMS and $PEERS
parsePeerConnectionParameters() {
  # check for uneven number of peer and org parameters
  if [ $(($# % 2)) -ne 0 ]; then
    exit 1
  fi

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    PEER="peer$1.org$2"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $PEER.ptunstad.no:7051"
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_ORG$2_CA")
      PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    fi
    # shift by two to get the next pair of peer/org parameters
    shift
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}




createChannel() {

	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.ptunstad.no:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.ptunstad.no:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi

	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}



joinChannel () {

	for org in 1; do
	    for peer in 0 1 2 3; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}



## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
sleep 10
updateAnchorPeers 0 1

## Install chaincode on Peer0/Org1 and Peer2/org1
echo "Installing chaincode on org1/peer0..."
sleep 10
installChaincode 0 1 1.2
echo "Install chaincode on org1/peer2..."
sleep 10
installChaincode 2 1 1.2
echo "Install chaincode on org1/peer1..."
sleep 10
installChaincode 1 1 1.2

#Instantiate chaincode on Peer2/org1
echo "Instantiating chaincode on org1/peer2..."
sleep 10
instantiateChaincode 2 1 1.2


#Invoke on chaincode on Peer0/Org1
echo "Sending invoke transaction on org1/peer0..."
sleep 10
chaincodeInvoke 0 1


echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
