      printMessage "telegraf"
      # 2027/01/27 - Comment out old key approach
      # https://www.influxdata.com/blog/linux-package-signing-key-rotation/
      # wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
      wget -qO- https://repos.influxdata.com/influxdata-archive_compat.key | sudo apt-key add -
      
      # sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null

      #shellcheck disable=SC1091
      # 2027/01/27 - Comment out old key approach
      #source /etc/lsb-release
      source /etc/os-release

      # 2027/01/27 - Comment out old key approach
      if ! grep -Fq "deb https://repos.influxdata.com/${ID} ${CODENAME} stable" /etc/apt/sources.list.d/influxdb.list
      then
        echo "deb https://repos.influxdata.com/${ID} ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
      fi
      
      #       if ! grep -Fq https://repos.influxdata.com/"${DISTRIB_ID,,}" /etc/apt/sources.list.d/influxdb.list
      #       then
      # sudo tee -a /etc/apt/sources.list.d/influxdb.list > /dev/null << EOT
      # deb https://repos.influxdata.com/"${DISTRIB_ID,,}" "${DISTRIB_CODENAME}" stable
      # EOT
      #       fi

      sudo apt-get update
      sudo apt-get install -y telegraf
      sudo apt-get install -y ntp

      sourcefilename=$config_file_directory/telegraf.conf
      filename=/etc/telegraf/telegraf.conf

      telegraf_conf_filename=/etc/telegraf/telegraf.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sudo systemctl enable telegraf

      sudo service telegraf restart

      fi