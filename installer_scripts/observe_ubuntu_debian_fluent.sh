
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
if ! grep -Fq "deb https://packages.fluentbit.io/"${OS}"/"${CODENAME}" "${CODENAME}" main" /etc/apt/sources.list
then
  echo deb https://packages.fluentbit.io/"${OS}"/"${CODENAME}" "${CODENAME}" main | sudo tee -a /etc/apt/sources.list
fi


sudo apt-get update
sudo apt-get install -y td-agent-bit
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