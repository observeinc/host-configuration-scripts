export AL_VERSION=$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release | xargs)

if [[ $AL_VERSION == "2023" ]]; then

sudo tee /etc/yum.repos.d/fluent-bit.repo > /dev/null << EOT
[fluent-bit]
name = Fluent Bit
baseurl = https://packages.fluentbit.io/amazonlinux/2023/
gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOT

  sudo yum install fluent-bit -y

  sudo service fluent-bit restart
  sudo systemctl enable fluent-bit 
else

sudo tee /etc/yum.repos.d/td-agent-bit.repo > /dev/null << EOT
[td-agent-bit]
name = TD Agent Bit
baseurl = https://packages.fluentbit.io/amazonlinux/2/\$basearch/
gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOT

  sudo yum install td-agent-bit -y

  sudo service td-agent-bit restart
  sudo systemctl enable td-agent-bit
fi