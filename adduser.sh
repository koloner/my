#!/bin/bash
CLIENT=$1
PASS=1
CLIENTEXISTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c -E "/CN=$CLIENT\$")
if [[ $CLIENTEXISTS == '1' ]]; then
	echo "Username Already Exist"
	exit
else
	cd /etc/openvpn/easy-rsa/ || return
	case $PASS in
	1)
		./easyrsa --batch build-client-full "$CLIENT" nopass
		;;
	2)
		echo "⚠️ You will be asked for the client password below ⚠️"
		./easyrsa --batch build-client-full "$CLIENT"
		;;
	esac
	echo "Client $CLIENT added."
fi
# Home directory of the user, where the client configuration will be written
if [ -e "/home/${CLIENT}" ]; then
	# if $1 is a user name
	homeDir="/home/${CLIENT}"
elif [ "${SUDO_USER}" ]; then
	# if not, use SUDO_USER
	if [ "${SUDO_USER}" == "root" ]; then
		# If running sudo as root
		homeDir="/root"
	else
		homeDir="/home/${SUDO_USER}"
	fi
else
	# if not SUDO_USER, use /root
	homeDir="/root"
fi
# Determine if we use tls-auth or tls-crypt
if grep -qs "^tls-crypt" /etc/openvpn/server.conf; then
	TLS_SIG="1"
elif grep -qs "^tls-auth" /etc/openvpn/server.conf; then
	TLS_SIG="2"
fi
# Generates the custom client.ovpn
cp /etc/openvpn/client-template.txt "$homeDir/ovpn/$CLIENT.ovpn"
{
	echo "<ca>"
	cat "/etc/openvpn/easy-rsa/pki/ca.crt"
	echo "</ca>"
	echo "<cert>"
	awk '/BEGIN/,/END CERTIFICATE/' "/etc/openvpn/easy-rsa/pki/issued/$CLIENT.crt"
	echo "</cert>"
	echo "<key>"
	cat "/etc/openvpn/easy-rsa/pki/private/$CLIENT.key"
	echo "</key>"
	case $TLS_SIG in
	1)
		echo "<tls-crypt>"
		cat /etc/openvpn/tls-crypt.key
		echo "</tls-crypt>"
		;;
	2)
		echo "key-direction 1"
		echo "<tls-auth>"
		cat /etc/openvpn/tls-auth.key
		echo "</tls-auth>"
		;;
	esac
} >>"$homeDir/ovpn/$CLIENT.ovpn"
echo "OK $homeDir/ovpn/$CLIENT.ovpn."
exit 0
