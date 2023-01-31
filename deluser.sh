#!/bin/bash
NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ $NUMBEROFCLIENTS == '0' ]]; then
  echo "You have no existing clients!"
  exit 1
fi
CLIENT=$1
cd /etc/openvpn/easy-rsa/ || return
./easyrsa --batch revoke "$CLIENT"
EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
rm -f /etc/openvpn/crl.pem
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
chmod 644 /etc/openvpn/crl.pem
find /home/ -maxdepth 2 -name "$CLIENT.ovpn" -delete
rm -f "/root/ovpn/$CLIENT.ovpn"
sed -i "/^$CLIENT,.*/d" /etc/openvpn/ipp.txt
cp /etc/openvpn/easy-rsa/pki/index.txt{,.bk}
echo "Certificate for client $CLIENT revoked."
