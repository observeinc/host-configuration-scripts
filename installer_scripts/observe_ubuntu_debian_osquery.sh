      printMessage "osquery"

      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B

      if ! grep -Fq https://pkg.osquery.io/deb /etc/apt/sources.list.d/osquery.list
      then
        echo deb [arch=$ARCH] https://pkg.osquery.io/deb deb main | sudo tee -a /etc/apt/sources.list.d/osquery.list
      fi

      sudo apt-get update
      sudo apt-get install -y osquery
      sudo service osqueryd start 2>/dev/null || true

      # ################
      sourcefilename=$config_file_directory/osquery.conf
      filename=/etc/osquery/osquery.conf

      osquery_conf_filename=/etc/osquery/osquery.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sourcefilename=$config_file_directory/osquery.flags
      filename=/etc/osquery/osquery.flags

      osquery_flags_filename=/etc/osquery/osquery.flags

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sudo service osqueryd restart
      sudo systemctl enable osqueryd

      fi