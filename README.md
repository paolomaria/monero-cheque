# Monero-cheque

A CLI in order to create cheque for the Monero currency.

## Description

One of the maim disadvantage of the Monero is the fact that you need either a computer or a smartphone in order to execute a transaction. This may be inconvenient for people which do not have a smartphone.

With this CLI you can create Monero cheques which then can be printed out as paper and given to the person who you want to send some Monero. The credentials in order to get paid are written on the cheque.

**IMPORTANT**: this CLI is still experimental. Use it at your own risk !!

## Prerequisites

The packages which provide the following binaries have to be installed:

 - openssl
 - python3
 - srm
 - expect
 - monero-wallet-cli
 - rst2pdf
 
## How to use

Once you did checkout the project go to the Monero-cheque directory and all `./createCheques.sh`:
```
cd monero-cheque
./createCheque.sh
```
A usage message will appear:
```
Usage: createCheques.sh -n <number of cheques> -a <amount of each cheques> -o <output file prefix> [-d <daemon address>] [-t <stagenet|testnet>] [-s]
    -s: simulate only. Don't tranfer any money.
```

If you want to create 10 cheques of 0.5 XMR each, just call:
```
createCheques.sh -n 10 -a 0.5 -o myFirstCheque

```

This will create two files:
 - myFirstCheque.txt: contains the signkey and viewkey of the generated cheque accounts. This is needed if you want to recover your Moneros (excluding the transaction fees) if anything goes wrong.
 - myFirstCheque.pdf: the checques you can print out and use for payment. The qrcode on each cheque contains a JSON message whcih can be used to restore the cheque wallet.

The cheques are currently in french.

## Ideas

 - multi language support
 - use monero-wallet-rpc instead of monero-wallet-cli
 
 
## Donations

Every donation is very welcome. You can transfer some Moneros to the following public key: `44wEhACSPxyRZRAZyWURjvWH61q5CAhYqWvycUYnkLuUMmwCHhCzFtJGLD1EoiZc2y2EtWBxcgZxzhoU1yAucq8dB2hB51B:J1s`

