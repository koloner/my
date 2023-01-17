#!/bin/bash
# Script by : PR Aiman
User=$1
clear

# Check If Username Exist, Else Proceed
egrep "^$User" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
clear
echo -e "Username Already Exist"
exit 0
else
Pass=$2
Days=$3
clear
MYIP=$(wget -qO- ipv4.icanhazip.com)
Today=`date +%s`
Days_Detailed=$(( $Days * 86400 ))
Expire_On=$(($Today + $Days_Detailed))
Expiration=$(date -u --date="1970-01-01 $Expire_On sec GMT" +%Y/%m/%d)
Expiration_Display=$(date -u --date="1970-01-01 $Expire_On sec GMT" '+%d-%m-%Y')
clear
opensshport="$(netstat -ntlp | grep -i ssh | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
dropbearport="$(netstat -nlpt | grep -i dropbear | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
stunnel4port="$(netstat -nlpt | grep -i stunnel | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
openvpnport="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
privoxyport="$(netstat -nlpt | grep -i privoxy | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
squidport="$(netstat -nlpt | grep -i squid | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
useradd $User
usermod -s /bin/false $User
usermod -e  $Expiration $User
egrep "^$User" /etc/passwd >/dev/null
echo -e "$Pass\n$Pass\n"|passwd $User &> /dev/null
clear
echo -e "Expired Date : $Expiration_Display"
fi