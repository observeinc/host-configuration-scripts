     printMessage "fluent"

cat << EOF | sudo tee /etc/yum.repos.d/td-agent-bit.repo
[td-agent-bit]
name = TD Agent Bit
baseurl = https://packages.fluentbit.io/centos/\$releasever/\$basearch/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOF

      sudo yum install td-agent-bit -y

      sudo service td-agent-bit start

      sourcefilename=$config_file_directory/td-agent-bit.conf
      filename=/etc/td-agent-bit/td-agent-bit.conf

      td_agent_bit_filename=/etc/td-agent-bit/td-agent-bit.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      includeFiletdAgent

      sudo service td-agent-bit restart
      sudo systemctl enable td-agent-bit

    fi