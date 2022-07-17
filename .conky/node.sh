#!/bin/bash

# Retrieve status of Klever node (eligible, elected, jailed, observer).
# Also retrieve staking rewards of indivitual wallets,
# as well as some general tokenomics of Klever Blockchain.
# Written by Maik L. @ community-node.ath.cx - 2022
# Version 0.2.1

# If you do NOT run a Klever node, this part need to be commented.
# Adjust your IP, wallet address, BLS_KEY and local directory.
# -> retrieve metrics and store at temporary file
truncate -s 0 /home/USER_NAME/.cache/nodestat.tmp
truncate -s 0 /home/USER_NAME/.cache/valistat.tmp
curl http://YOUR_NODE_IP:8080/node/status >> /home/USER_NAME/.cache/nodestat.tmp
curl http://YOUR_NODE_IP:8080/validator/statistics >> /home/USER_NAME/.cache/valistat.tmp
BALANCE='curl http://YOUR_NODE_IP:8080/address/YOUR_NODE_WALLET'
BLSkey=YOUR_BLS_KEY
BLSkey=\"$BLSkey\"
kversion=klv_app_version
NVersion=\"$kversion\"

# Following details need to be adjusted based on your wallet addresses and local directory.
# -> retrieve metrics and store at temporary file
curl https://node.mainnet.klever.finance/address/YOUR_FIRST_WALLET/allowance?asset=KFI > /home/USER_NAME/.cache/rewards.tmp
curl https://node.mainnet.klever.finance/address/YOUR_SECOND_WALLET/allowance?asset=KFI > /home/USER_NAME/.cache/rewards2.tmp
curl https://api.mainnet.klever.finance/v1.0/assets/KFI > /home/USER_NAME/.cache/KFI.tmp
curl https://api.mainnet.klever.finance/v1.0/assets/KLV > /home/USER_NAME/.cache/KLV.tmp
STATSFILE='/home/USER_NAME/.conky/nodestatus.txt'

# Update the TEMPFILE to the path where the status.json file should be stored
TEMPFILE='/home/USER_NAME/.cache/nodestatus.txt'

#Clear out the file
truncate -s 0 $TEMPFILE

# Modify the full path to the local user directory
METRICS='cat /home/USER_NAME/.cache/nodestat.tmp'
PEERS='cat /home/USER_NAME/.cache/valistat.tmp'
KFIREWARDS='cat /home/USER_NAME/.cache/rewards.tmp'
KFIREWARDS2='cat /home/USER_NAME/.cache/rewards2.tmp'
KFISTATS='cat /home/USER_NAME/.cache/KFI.tmp'
KLVSTATS='cat /home/USER_NAME/.cache/KLV.tmp'


# Header of conky segment to start Klever Node Stats
# If you are NOT running a node, just comment the following lines.
echo '${hr 2}' >> $TEMPFILE
echo '${font sans-serif:bold:size=12}${alignc}Klever Node Status' >> $TEMPFILE


# Just collecting and preparing some variables.
# DONT change that part.
struct=.data.statistics.
bal=.data.account
var1=.Rating
var2=.TotalNumValidatorSuccess
var3=.TotalNumLeaderFailure
var4=.TotalNumLeaderSuccess
var5=.TotalNumValidatorIgnoredSignatures
var6=.Balance
var7=.Allowance
var8=.data.metrics.
var9=.TotalNumValidatorFailure
var10=.data.metrics.klv_node_type
temp=''
KFIREW=.data.stakingRewards

# tokenomcis
KFIMAX=.data.asset.maxSupply
KFICIR=.data.asset.circulatingSupply
KFISTAKED=.data.asset.staking.totalStaked
KLVMAX=.data.asset.maxSupply
KLVCIR=.data.asset.circulatingSupply
KLVSTAKED=.data.asset.staking.totalStaked

# general calculation
# If you are NOT running a node, just comment the following lines.
rating=$($PEERS | jq $struct$BLSkey$var1)
balance=$($BALANCE | jq $bal$var6/1000000 | bc -l | xargs printf "%'.3f")
allowance=$($BALANCE | jq $bal$var7 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.3f")
allowvalue=$(($allowance/1000000 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.2f"))
valifailure=$($PEERS | jq $struct$BLSkey$var9)

# general calculation of staked KFI rewards, based on your wallets
kfirewrds=$($KFIREWARDS | jq $KFIREW/1000000 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.3f")
kfirewrds2=$($KFIREWARDS2 |jq $KFIREW/1000000 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.3f")

#tokenomics
kfimax=$($KFISTATS | jq $KFIMAX/1000000000000)
kficir=$($KFISTATS | jq $KFICIR/1000000000000)
kfistaked=$($KFISTATS | jq $KFISTAKED/1000000 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.0f")
klvmax=$($KLVSTATS | jq $KLVMAX/1000000000000000)
klvcir=$($KLVSTATS | jq $KLVCIR/1000000000000000 | bc -l | xargs printf "%.4f")
klvstaked=$($KLVSTATS | jq $KLVSTAKED/1000000 | bc -l | LC_ALL=en_US.UTF-8 xargs printf "%'.0f")

# Version export to be activated if needed
# If you are NOT running a node, just comment the following lines.
nversion=$($METRICS | jq $var8$kversion | grep -oP '.*?(?=/go)' | sed 's/"//g')
echo 'Node Version: ${alignr}'$nversion >> $TEMPFILE


# Gather YOUR current Node Status
# If you are NOT running a node, just comment the following lines.
nodetype=$($METRICS | jq $var10 | grep -oP '.*?(?=")')
#nodestat=\"$nodetype\"
echo '${font sans-serif:normal:size=10}Node Status: ${alignr}'$nodetype >> $TEMPFILE 

# Get Node Consensus Slot State
# If you are NOT running a node, just comment the following lines.
if echo "$METRICS" | grep -oP 'signed';
then
    echo '${font sans-serif:normal:size=10}Slot Status: ${alignr}Unsigned' >> $TEMPFILE
else
    echo '${font sans-serif:normal:size=10}Slot Status: ${alignr}Signed' >> $TEMPFILE
fi

# rating of Validtor node - if node is running as Observer, value is NULL
# If you are NOT running a node, just comment the following lines.
if echo "$rating" | grep -oP 'null';
then 
echo '${font sans-serif:normal:size=10}Rating:${alignr} N/A'  >> $TEMPFILE
else 
echo '${font sans-serif:normal:size=10}Rating:${alignr}' $rating  >> $TEMPFILE 
fi
echo '${stippled_hr}' >> $TEMPFILE

# Don't change the following lines.
KLVPRICE='curl https://api.exchange.klever.io/v1/market/ticker?symbol=KLV-USDT'
priceval=.price

calcrew=$($KLVPRICE | jq $priceval | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/' | bc -l | xargs printf "%.4f")

# If you are NOT running a node, just comment the following lines.
if [ -z "$allowance" ];
	then echo '${font sans-serif:normal:size=10}Claimable Rewards: ${alignr}N/A' >> $TEMPFILE
	else echo '${font sans-serif:normal:size=10}Claimable Rewards:${alignr}' $allowvalue >> $TEMPFILE
fi


if [ -z "$balance" ];
	then echo '${font sans-serif:normal:size=10}Available Balance: ${alignr}N/A' >> $TEMPFILE
	else echo '${font sans-serif:normal:size=10}Available Balance:${alignr}' $balance >> $TEMPFILE
fi

if echo "$calcrew $allowvalue" | awk '{print $1 * $2}' | grep -oP '0';
then echo '${font sans-serif:bold:size=10}Rewards (USD): ${alignr}N/A' >> $TEMPFILE
else
    echo '${font sans-serif:bold:size=10}Rewards (USD): ${alignr}' | tr -d '\n' >> $TEMPFILE
    echo "$calcrew $allowvalue" | awk '{print $1 * $2}'  >> $TEMPFILE
fi

echo '${font sans-serif:bold:size=10}Balance  (USD): ${alignr}' | tr -d '\n' >> $TEMPFILE
echo "$calcrew $balance" | awk '{print $1 * $2}'  >> $TEMPFILE

# Don't change the following lines.
echo '${stippled_hr}' >> $TEMPFILE
echo '${font sans-serif:bold:size=10}KLV Price: ${alignr}' $calcrew >> $TEMPFILE
echo "" >> $TEMPFILE

# Blockchain stats about Coin and Governance Token (KLV + KFI)
echo '${hr 2}' >> $TEMPFILE
echo '${font sans-serif:bold:size=10}${alignc}Mainnet Tokenomics' >> $TEMPFILE
echo '${font sans-serif:bold:size=8}Name ${goto 50}Max Supply ${goto 120} Circ. Supply ${alignr}Staked' >> $TEMPFILE
echo '${hr 1}'  >> $TEMPFILE
echo '${font sans-serif:bold:size=8}KLV ${goto 50}'$klvmax 'B${goto 120}' $klvcir 'B${alignr}'$klvstaked >> $TEMPFILE
echo '${font sans-serif:bold:size=8}KFI ${goto 50}'$kfimax 'M${goto 120}' $kficir 'M${alignr}'$kfistaked >> $TEMPFILE
echo "" >> $TEMPFILE
echo '${hr 2}' >> $TEMPFILE

# normal staking like KLV and KFI to be displayed per wallet
# Just adjust the last digits of your wallets, to identify the wallet.
echo '${font sans-serif:bold:size=10}${alignc}Staking Rewards${font sans-serif:bold:size=7} in KLV' >> $TEMPFILE
echo '${stippled_hr}' >> $TEMPFILE
echo '${font sans-serif:bold:size=8}KFI Rewards (klv1...xxxxx): ${alignr}' $kfirewrds >> $TEMPFILE
echo '${font sans-serif:bold:size=8}KFI Rewards (klv1...yyyyy): ${alignr}' $kfirewrds2 >> $TEMPFILE


sleep 5
cp -f $TEMPFILE $STATSFILE
