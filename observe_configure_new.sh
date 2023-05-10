#!/bin/bash

customer_id=0
ingest_token=0
observe_host_name_base=

config_files_clean="FALSE"
cloud_metadata="TRUE"
datacenter=""
testeject="NO"
appgroup=""
branch="main"
validate_endpoint="TRUE"
module="linux-host"

branch="jlb/refactor"
base_url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch}"
config_file_directory="$HOME/observe_config_files"

getConfigurationFiles(){
    module_name=$1
    module_type=$2
    file_count=0
    manifest_url="${base_url}/manifests/${module_type}/${module_name}.manifest"
    echo $manifest_url

    if (manifest=`curl --fail $manifest_url`); then
        manifest=`curl --fail $manifest_url`
        echo $manifest
        echo "Found manifest file Observe $module_type for \"$module_name\"."
        filecount=0
        while IFS= read -r config_file; do
            echo "$config_file"
            config_url="${base_url}/config_files/${config_file}"
            echo $config_url
            if (`curl $config_url --create-dirs --fail --output ${config_file_directory}/${config_file}`); then
                file_count=$((file_count+1))
            else
                echo "Could not find $config_file listed in manifest for $module_type \"$module_name\"."
                exit 1
            fi
        done <<< "$manifest"
        echo "Downloaded $file_count config files for $module_type \"$module_name\"."
    else   
        echo "Manifest file not found for $module_type \"$module_name\".  Please ensure this is a valid Observe module or try again."
    fi

}

checkAgentInstallReqs () {
    agent=$1
    if [ -d "${config_file_directory}/$agent" ]; then
        echo "need to install fluent, or check status"
        # get agent configs
        getConfigurationFiles "$agent" "agent"

        installAgent
    else
        echo "$agent not needed for this install/upgrade... skipping"
    fi
}

installAgent () {
    install_results=`curl ${base_url}/installer_scripts/observe_${observe_os}_${agent}.sh --fail | bash -s`
    echo $install_results
}

getOSDetails () {
# identify OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$( echo "${ID}" | tr '[:upper:]' '[:lower:]')
elif lsb_release &>/dev/null; then
    OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
else
    OS=$(uname -s)
fi


case ${OS} in
amzn|amazonlinux)
    echo "Amazon OS"
    observe_os="amazonlinux"
    ;;

rhel|centos)
    echo "RHEL OS"
    observe_os="rhelcentos"
    ;;

ubuntu|debian)
    echo "UBUNTU OS"
    observe_os="ubuntudebian"
    ;;
Darwin)
    echo "Darwin -- JLB local testing!!"
    observe_os="jlbtest"
    ;;
*)
    echo "Unknown / Unsupported OS: \"${OS}\"  Please visit docs.observeinc.com/updatemelater to see supported OS"
    exit 1;
    ;;
esac
}

getOSDetails
getConfigurationFiles "linux-host" "app"
checkAgentInstallReqs "fluent"
checkAgentInstallReqs "telegraf"
checkAgentInstallReqs "osquery"
