
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz

#export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bash_profile

go version
