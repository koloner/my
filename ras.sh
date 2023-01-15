#!/bin/bash
# shellcheck disable=SC1091,SC2164,SC2034,SC1072,SC1073,SC1009
function radiusConfig(){
preinst
	packages=("openvpn-auth-radius" "build-essential" "libgcrypt20-dev" "unzip" "mlocate")
    for pkg in ${packages[@]}; do
        #is_pkg_installed=$(dpkg-query -W --showformat='${Status}\n' ${pkg} | grep "install ok installed" )
		is_pkg_installed=$( dpkg -s  ${pkg} | grep "install ok installed" )
		if [[ "$is_pkg_installed" == *"install ok installed"* ]]; then
			echo ${pkg} is installed.

        else
             apt install   ${pkg} -y
		fi
	done
	
	freeradius=/etc/radiusclient/radiusclient.conf
	if test -f "$freeradius"; then
        echo freeradius is installed.
    else
		wget https://github.com/FreeRADIUS/freeradius-client/archive/master.zip
		unzip master.zip
		mv freeradius-client-master freeradius-client
		cd freeradius-client
		./configure --prefix=/
		make && make install
		touch /etc/radiusclient/dictionary.microsoft 
			echo "# Microsoft’s VSA’s, from RFC 2548
#
# $Id: poptop_ads_howto_8.htm,v 1.8 2008/10/02 08:11:48 wskwok Exp $
#
VENDOR Microsoft 311 Microsoft
BEGIN VENDOR Microsoft
ATTRIBUTE MS-CHAP-Response 1 string Microsoft
ATTRIBUTE MS-CHAP-Error 2 string Microsoft
ATTRIBUTE MS-CHAP-CPW-1 3 string Microsoft
ATTRIBUTE MS-CHAP-CPW-2 4 string Microsoft
ATTRIBUTE MS-CHAP-LM-Enc-PW 5 string Microsoft
ATTRIBUTE MS-CHAP-NT-Enc-PW 6 string Microsoft
ATTRIBUTE MS-MPPE-Encryption-Policy 7 string Microsoft
# This is referred to as both singular and plural in the RFC.
# Plural seems to make more sense.
ATTRIBUTE MS-MPPE-Encryption-Type 8 string Microsoft
ATTRIBUTE MS-MPPE-Encryption-Types 8 string Microsoft
ATTRIBUTE MS-RAS-Vendor 9 integer Microsoft
ATTRIBUTE MS-CHAP-Domain 10 string Microsoft
ATTRIBUTE MS-CHAP-Challenge 11 string Microsoft
ATTRIBUTE MS-CHAP-MPPE-Keys 12 string Microsoft encrypt=1
ATTRIBUTE MS-BAP-Usage 13 integer Microsoft
ATTRIBUTE MS-Link-Utilization-Threshold 14 integer Microsoft
ATTRIBUTE MS-Link-Drop-Time-Limit 15 integer Microsoft
ATTRIBUTE MS-MPPE-Send-Key 16 string Microsoft
ATTRIBUTE MS-MPPE-Recv-Key 17 string Microsoft
ATTRIBUTE MS-RAS-Version 18 string Microsoft
ATTRIBUTE MS-Old-ARAP-Password 19 string Microsoft
ATTRIBUTE MS-New-ARAP-Password 20 string Microsoft
ATTRIBUTE MS-ARAP-PW-Change-Reason 21 integer Microsoft
ATTRIBUTE MS-Filter 22 string Microsoft
ATTRIBUTE MS-Acct-Auth-Type 23 integer Microsoft
ATTRIBUTE MS-Acct-EAP-Type 24 integer Microsoft
ATTRIBUTE MS-CHAP2-Response 25 string Microsoft
ATTRIBUTE MS-CHAP2-Success 26 string Microsoft
ATTRIBUTE MS-CHAP2-CPW 27 string Microsoft
ATTRIBUTE MS-Primary-DNS-Server 28 ipaddr
ATTRIBUTE MS-Secondary-DNS-Server 29 ipaddr
ATTRIBUTE MS-Primary-NBNS-Server 30 ipaddr Microsoft
ATTRIBUTE MS-Secondary-NBNS-Server 31 ipaddr Microsoft
#ATTRIBUTE MS-ARAP-Challenge 33 string Microsoft
#
# Integer Translations
#
# MS-BAP-Usage Values
VALUE MS-BAP-Usage Not-Allowed 0
VALUE MS-BAP-Usage Allowed 1
VALUE MS-BAP-Usage Required 2
# MS-ARAP-Password-Change-Reason Values
VALUE MS-ARAP-PW-Change-Reason Just-Change-Password 1
VALUE MS-ARAP-PW-Change-Reason Expired-Password 2
VALUE MS-ARAP-PW-Change-Reason Admin-Requires-Password-Change 3
VALUE MS-ARAP-PW-Change-Reason Password-Too-Short 4
# MS-Acct-Auth-Type Values
VALUE MS-Acct-Auth-Type PAP 1
VALUE MS-Acct-Auth-Type CHAP 2
VALUE MS-Acct-Auth-Type MS-CHAP-1 3
VALUE MS-Acct-Auth-Type MS-CHAP-2 4
VALUE MS-Acct-Auth-Type EAP 5
# MS-Acct-EAP-Type Values
VALUE MS-Acct-EAP-Type MD5 4
VALUE MS-Acct-EAP-Type OTP 5
VALUE MS-Acct-EAP-Type Generic-Token-Card 6
VALUE MS-Acct-EAP-Type TLS 13
END-VENDOR Microsoft" | tee /etc/radiusclient/dictionary.microsoft
sed -i -r '/.*ATTRIBUTE.*NAS-IPv6-Address.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Framed-IPv6-Prefix.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Login-IPv6-Host.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Framed-IPv6-Pool.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Framed-IPv6-Address.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*DNS-Server-IPv6-Address.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Route-IPv6-Information.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Framed-Interface-Id.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -r '/.*ATTRIBUTE.*Framed-IPv6-Rout.*/s/^/#/g' /etc/radiusclient/dictionary
sed -i -e '$a INCLUDE /etc/radiusclient/dictionary.merit' /etc/radiusclient/dictionary
sed -i -e '$a INCLUDE /etc/radiusclient/dictionary.microsoft' /etc/radiusclient/dictionary
sed -i '/issue.*issue/a seqfile \/var\/run\/freeradius\/freeradius.pid' /etc/radiusclient/radiusclient.conf
sed -i -r '/^radius_deadtime/s/^/#/g' /etc/radiusclient/radiusclient.conf #comment
sed -i '/.*net.ipv4.ip.*/s/^#//g' /etc/sysctl.conf
mkdir /var/run/freeradius
sysctl -p
systemctl restart openvpn
        fi

	 sed -e '/^acctserver.*localhost/s/^/#/' -i -r /etc/radiusclient/radiusclient.conf #comment
	 sed -e '/^authserver.*localhost/s/^/#/' -i -r /etc/radiusclient/radiusclient.conf #comment
	 clear
	cat /etc/radiusclient/radiusclient.conf | grep -o '^authserver.*\|^acc.*\|^securepass.*'
	f=0
	g=0
	while [ $f -eq 0 ];do
		if [ "$g" = 0 ]; then
		echo "Do you have another RAS IP?[y/n]"
        read ans
		fi

        if [ "$ans" = "y" ]
	
        then
          read -rp "Please Enter IBSng IP Address: " IPBS
          read -rp "Please Enter SecurePass: " secpass
		  echo "$IPBS	$secpass" |  tee /etc/radiusclient/servers
          sed -i -r "/.*simply.*/a authserver   $IPBS"  /etc/radiusclient/radiusclient.conf
          sed -i -r "/.*for authserver applies.*/a acctserver   $IPBS" /etc/radiusclient/radiusclient.conf
          echo "Add Successfully"
		sleep 1
echo -e "
NAS-Identifier=OpenVpn
Service-Type=5
Framed-Protocol=1
NAS-Port-Type=5
NAS-IP-Address=$IP
OpenVPNConfig=/etc/openvpn/server/server.conf
subnet=255.255.255.0
overwriteccfiles=true
server
{
acctport=1813
authport=1812
name=$IPBS
retry=1
wait=1
sharedsecret=$secpass
}" >> /usr/lib/openvpn/radiusplugin.cnf
		systemctl restart openvpn
		g=0
		elif [ "$ans" = "n" ]; then
			 f=1
		else
			 checkans
		fi
        
	done

}
 function addras(){
	clear
	cat /etc/radiusclient/radiusclient.conf | grep -o '^authserver.*\|^acc.*\|^securepass.*'
	f=0
	g=0
	while [ $f -eq 0 ];do
		if [ "$g" = 0 ]; then
		echo "Do you have another RAS IP?[y/n]"
        read ans
		fi

        if [ "$ans" = "y" ]
	
        then
          read -rp "Please Enter IBSng IP Address: " IPBS
          read -rp "Please Enter SecurePass: " secpass
		  echo "$IPBS	$secpass" |  tee /etc/radiusclient/servers
          sed -i -r "/.*simply.*/a authserver   $IPBS"  /etc/radiusclient/radiusclient.conf
          sed -i -r "/.*for authserver applies.*/a acctserver   $IPBS" /etc/radiusclient/radiusclient.conf
          echo "Add Successfully"
		sleep 1
		echo -e "
	NAS-Identifier=OpenVpn
	Service-Type=5
	Framed-Protocol=1
	NAS-Port-Type=5
	NAS-IP-Address=$IP
	OpenVPNConfig=/etc/openvpn/server/server.conf
	subnet=255.255.255.0
	overwriteccfiles=true
	server
	{
		acctport=1813
		authport=1812
		name=$IPBS
		retry=1
		wait=1
		sharedsecret=$secpass
	}" >> /usr/lib/openvpn/radiusplugin.cnf
		systemctl restart openvpn
		g=0
		elif [ "$ans" = "n" ]; then
			 f=1
		else
			 checkans
		fi
        
	done
}
function editras(){
	clear
	cat /etc/radiusclient/radiusclient.conf | grep -o '^authserver.*\|^acc.*\|^securepass.*'
	read -rp "Please enter new RAS IP: " newrasip
	read -rp "Now please enter new Secret: " newsecret
	sed -i -r "s/authserver.*/authserver   $newrasip/g"  /etc/radiusclient/radiusclient.conf
	sed -i -r "s/acctserver.*/acctserver   $newrasip/g" /etc/radiusclient/radiusclient.conf
	sed -i -r "s/sharedsecret=.*/sharedsecret=$newsecret/g" /usr/lib/openvpn/radiusplugin.cnf
	sed -i -r "s/name=.*/name=$newrasip/g" /usr/lib/openvpn/radiusplugin.cnf
	echo "$newrasip	$newsecret" |  tee /etc/radiusclient/servers
	sleep 3
	}
	
	function Selection(){
	choice=0
	while [ $choice -eq 0 ]
	do
	clear
	printf " %-40s \n" "`date`"
	echo
	echo -e "\e[0;31m1) Install OpenVPN Server With IBSng Config \e[0m"
	echo -e "\e[0;33m2) Install Cisco Any Connect Server With IBSng Config \e[0m"
	echo -e "\e[0;31m3) Install L2TP Server With IBSng Config \e[0m"
	echo -e "\e[0;33m4) Install PPTP Server With IBSng Config \e[0m"
	echo -e "\e[0;31m5) Install IKEv2 Server With IBSng Config \e[0m"
	echo -e "\e[0;33m6) Install ShadowSocks Server \e[0m"
	echo -e "\e[0;31m7) Install WireGaurd Server \e[0m"
	echo
	echo -e "\e[0;32m9) Edit IBSng Configuration \e[0m"
	echo
	echo "0) Exit"
	echo
	read -rp "Select a number:" Selection

	if [ $Selection -gt 10 ]
	then
		echo "The variable is greater than 9."
		sleep 1s
	elif [ $Selection -eq 1 ]
	then
		installopenvpn
	elif [ $Selection -eq 2 ]
	then
		installocs
	elif [ $Selection -eq 3 ]
	then
		installl2tp
	elif [ $Selection -eq 4 ]
	then
		installpptp
	elif [ $Selection -eq 5 ]
	then
		installikev2
	elif [ $Selection -eq 6 ]
	then
		installsocks5
	elif [ $Selection -eq 7 ]
	then
		installwiregaurd
	elif [ $Selection -eq 9 ]
	then
		editras
	elif [ $Selection -eq 0 ]
	then
		choice=1
	else
		echo "Exit"
	fi
	done
}


Selection
