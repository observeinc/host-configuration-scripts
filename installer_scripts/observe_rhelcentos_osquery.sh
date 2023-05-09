        printMessage "osquery"

        sudo yum install yum-utils -y

        curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery

        sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo

        sudo yum-config-manager --enable osquery-s3-rpm-repo

        sudo yum install osquery -y


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