      printMessage "telegraf"

cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
EOF

# cat << EOF | sudo tee /etc/yum.repos.d/influxdb.repo
# [influxdb]
# name = InfluxDB Repository - RHEL \$releasever
# baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
# enabled = 1
# gpgcheck = 0
# gpgkey = https://repos.influxdata.com/influxdb.key
# EOF

      sudo yum install telegraf -y

      sourcefilename=$config_file_directory/telegraf.conf
      filename=/etc/telegraf/telegraf.conf

      telegraf_conf_filename=/etc/telegraf/telegraf.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      yum install ntp -y

      sudo systemctl enable telegraf

      sudo service telegraf restart

    fi