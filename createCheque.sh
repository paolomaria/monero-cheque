#!/bin/bash

# Copyright  2024 by Paolomaria
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# It is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

function show_dep_text {
	echo 'Checking presence of the required shell programs (openssl, python3, srm, expect, rst2pdf, monero-wallet-cli, python module qrcode)...'
}
if ! [ -x "$(command -v openssl)" ]; then
	show_dep_text
    echo 'Error: openssl is not present on your system. Please install it and run this script again.'
    exit 1
fi
if ! [ -x "$(command -v python3)" ]; then
	show_dep_text
    echo 'Error: python3 is not present on your system. Please install it and run this script again.'
    exit 1
fi
if ! [ -x "$(command -v srm)" ]; then
	show_dep_text
    echo 'Error: srm is not present on your system. Please install it and run this script again.'
    exit 1
fi
if ! [ -x "$(command -v expect)" ]; then
	show_dep_text
    echo 'Error: expect is not present on your system. Please install it and run this script again.'
    exit 1
fi
if ! [ -x "$(command -v monero-wallet-cli)" ]; then
	show_dep_text
    echo 'Error: monero-wallet-cli is not present on your system. Please install it and run this script again.'
    exit 1
fi
if ! [ -x "$(command -v rst2pdf)" ]; then
	show_dep_text
    echo 'Error: rst2pdf is not present on your system. Please install it and run this script again.'
    exit 1
fi

#pip list | grep qrcode

amount=none
number=none
outputFilePrefix="none"
daemonAddress=
netToUse=
simulate=0

now=`date +"%d/%m/%Y"`

function show_usage {
  echo "Usage: createCheques.sh -n <number of cheques> -a <amount of each cheques> -o <output file prefix> [-d <daemon address>] [-t <stagenet|testnet>] [-s]"
  echo "    -s: simulate only. Don't tranfer any money."
}

while getopts "ha:n:so:d:t:" opt; do
  case "$opt" in
    h)
	  show_usage
      exit 0
      ;;
    n)  number=$OPTARG
      ;;
    a)  amount=$OPTARG
      ;;
    o)  outputFilePrefix=$OPTARG
      ;;
    t)  netToUse="--$OPTARG"
      ;;
    d)  daemonAddress="--daemon-address $daemonAddress$OPTARG"
      ;;
    s)  simulate=1
      ;;
  esac
done

if [ -n "$netToUse" -a "$netToUse" != "--testnet" -a "$netToUse" != "--stagenet" ]; then
	show_usage
	exit 1
fi

if [ $amount == "none" -o $number == "none" ]; then
	show_usage
	exit 1
fi

if [ $outputFilePrefix == "none" ]; then
	show_usage
	exit 1
fi

if ! [[ "$amount" =~ ^0\.[0-9]*$ ]]; then
	echo "Amount must be a positive number and less than 1.0"
	exit 1
fi

if ! [[ "$number" =~ ^[1-9][0-9]*$ ]]; then
	echo "Number of cheques must be a positive number"
	exit 1
fi

if [ $number -gt 10 ]; then
	echo "Number of cheques can be maximal 10"
	exit 1
fi

outputFile=$outputFilePrefix.txt
pdfFile=$outputFilePrefix.pdf
rstFile=$(mktemp /tmp/.XXXXXXXXX)
chmod 600 $rstFile

if [ -f $outputFile ]; then
	echo "The file $outputFile already exists"
	exit 1
fi

if [ -f $pdfFile ]; then
	echo "The file $pdfFile already exists"
	exit 1
fi

> $outputFile
chmod 600 $outputFile

#totalAmount=$(( $amount * $number ))


read -p 'Wallet File: ' secretId
echo
read -sp 'Password: ' secretPw
echo

monero-wallet-cli $netToUse --wallet-file $secretId --password $secretPw wallet_info
walletInfo=`monero-wallet-cli $netToUse --wallet-file $secretId --password $secretPw wallet_info`
#echo $walletInfo
walletAddress=`echo "$walletInfo" | grep Address | sed -e "s/Address: //g"`
echo $walletAddress

jsonTemplate='{"version":1,"filename":"__FILENAME__","scan_from_height":0,"password":"__PASSWORD__","viewkey":"__VIEWKEY__","spendkey":"__SPENDKEY__","address":"__ADDRESS__"}'

completeTransferCommand=""

amountForCheque="$amount XMR (moins les frais de transaction)"

if [ ! -z $netToUse ]; then
	amountForCheque="sans valeur ($amount XMR sur $netToUse)"
fi
if [ $simulate -eq 1 ]; then
	amountForCheque="sans valeur"
fi

for (( i = 0 ; $i < $number; i = $i + 1)) ; do
	if [ $i -gt 0 ]; then
		echo "----" >> $rstFile
		echo >> $rstFile
		echo "----" >> $outputFile
		echo >> $outputFile
	fi
	userpass=`openssl rand -base64 6`
	passFormatted=`echo $userpass | sed -E "s/(^....)/\1-/g"`

	tdir=$(mktemp -d /tmp/.XXXXXXXXX)
	chequeWalletFile="$tdir/cheque"
	
	./createWallet.exp $chequeWalletFile $passFormatted $netToUse
	monero-wallet-cli --wallet-file $chequeWalletFile --password $passFormatted $netToUse wallet_info
	chequeWalletInfo=`monero-wallet-cli --wallet-file $chequeWalletFile --password $passFormatted $netToUse wallet_info`
	chequeWalletAddress=`echo "$chequeWalletInfo" | grep Address | sed -e "s/Address: //g"`
	#chequeWalletViewKey=`./executeCommand.exp $chequeWalletFile $passFormatted viewkey`
	chequeWalletViewKey=`./executeCommand.exp $chequeWalletFile $passFormatted viewkey $netToUse | grep secret | sed -e "s/secret: //g"`
	chequeWalletSpendKey=`./executeCommand.exp $chequeWalletFile $passFormatted spendkey $netToUse | grep secret | sed -e "s/secret: //g"`
	chequeWalletViewKey=`echo "$chequeWalletViewKey" | sed -e "s/\r//g"`
	chequeWalletSpendKey=`echo "$chequeWalletSpendKey" | sed -e "s/\r//g"`
	
	#echo $chequeWalletViewKey
	#echo $passFormatted
	#echo $chequeWalletSpendKey
	#echo $chequeWalletAddress
	
	jsonWalletFile=$(mktemp /tmp/cheque_XXXXXXXXX)
	myJson=`echo $jsonTemplate | sed -e "s@__FILENAME__@$jsonWalletFile@g" -e "s@__PASSWORD__@$passFormatted@g" -e "s@__VIEWKEY__@$chequeWalletViewKey@g" -e "s@__SPENDKEY__@$chequeWalletSpendKey@g" -e "s@__ADDRESS__@$chequeWalletAddress@g"`
	myJson=`echo $myJson | tr -d "\n\r"`
	rm $jsonWalletFile
	#echo $myJson
	
	qrfile=$(mktemp $tdir/.XXXXXXXXX.png)
	chmod 600 $qrfile
	python3 createQRCode.py $myJson $qrfile
	cat cheque.template.rst | sed -e "s@__QR_CODE__@$qrfile@g" -e "s@__SENDER_ADDR__@$walletAddress@g" -e "s@__NOW__@$now@g" -e "s@__PASSWORD__@$passFormatted@g" -e "s@__ADDRESSE__@$chequeWalletAddress@g" -e "s@__VIEWKEY__@$chequeWalletViewKey@g" -e "s@__SPENDKEY__@$chequeWalletSpendKey@g" -e "s@__AMOUNT__@$amountForCheque@g" >> $rstFile
	echo "Issued by $walletAddress the $now" >> $outputFile
	echo "  View Key: $chequeWalletViewKey" >> $outputFile
	echo "  Spend Key: $chequeWalletSpendKey" >> $outputFile
	echo "  (Addresse: $chequeWalletAddress)" >> $outputFile
	
	
	completeTransferCommand="${completeTransferCommand} $chequeWalletAddress $amount"
	



done

if [ $simulate -ne 1 ]; then
	echo "IMPORTANT: The amount of $amount XMR (plus transaction fee) for each cheque will be tranfered from the following wallet:"
	echo "    File: $secretId"
	echo "The spend key and view key of each cheque account will be stored in the file $outputFile. If you loose this file the money will be lost."
	read -p 'Proceed (Y/N): ' proceed
	echo
	if [ "$proceed" != "Y" ]; then
		echo "Transaction has been stopped by the user"
		rm $outputFile
		exit 1
	fi
	monero-wallet-cli --wallet-file $secretId --password $secretPw $daemonAddress $netToUse transfer $completeTransferCommand |& tee $tdir/createCheque.log
	grep "Transaction successfully submitted" $tdir/createCheque.log > /dev/null
fi

rst2pdf $rstFile -o $pdfFile
chmod 600 $pdfFile
srm $rstFile
srm -r $tdir

echo "The following files have been created:"
echo "    $pdfFile: the file containing the checques"
echo "    $outputFile: a text file containing the private keys of the created cheque accounts in case you have to recover the money."

