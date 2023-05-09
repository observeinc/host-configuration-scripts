export AL_VERSION=$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release | xargs)

curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery

if [[ $AL_VERSION == "2023" ]]; then
  sudo dnf config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
  sudo dnf config-manager --enable osquery-s3-rpm-repo
  sudo dnf install osquery -y
else
  sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
  sudo yum-config-manager --enable osquery-s3-rpm-repo
  sudo yum install osquery -y
fi

sudo service osqueryd restart
sudo systemctl enable osqueryd
