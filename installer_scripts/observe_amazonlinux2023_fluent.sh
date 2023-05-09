sudo tee /etc/yum.repos.d/fluent-bit.repo > /dev/null << EOT
[fluent-bit]
name = Fluent Bit
baseurl = https://packages.fluentbit.io/amazonlinux/2023/
gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOT

sudo yum install fluent-bit -y