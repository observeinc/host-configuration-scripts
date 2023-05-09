#!/bin/bash

http_code=0
branch_replace="jlb/refactor"
base_url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}"
config_file_directory="$HOME/observe_config_files"

getConfigurationFiles(){
    module=$1
    module_type=$2
    manifest_url="${base_url}/manifests/${module_type}/${module}.manifest"
    echo $manifest_url

    if (manifest=`curl --fail $manifest_url`); then
        manifest=`curl --fail $manifest_url`
        echo $manifest
        echo "Found manifest file Observe $module_type for \"$module\"."
        filecount=0
        while IFS= read -r config_file; do
            echo "$config_file"
            config_url="${base_url}/config_files/${config_file}"
            echo $config_url
            if (`curl $config_url --create-dirs --fail --output ${config_file_directory}/${config_file}`); then
                file_count=$((file_count+1))
            else
                echo "Could not find $config_file listed in manifest for $module_type \"$module\"."
                exit 1
            fi
        done <<< "$manifest"
        echo "Downloaded $file_count config files for $module_type \"$module\"."
    else   
        echo "Manifest file not found for $module_type \"$module\".  Please ensure this is a valid Observe $module_type or try again."
    fi

}

checkAgentInstallReqs () {
    agent=$1
    if [ -d "${config_file_directory}/$agent" ]; then
        echo "need to install fluent, or check status"
        # get agent configs
        getConfigurationFiles "$agent" "agent"
    else
        echo "Fluentbit not needed for this install/upgrade... skipping"
    fi
}

getConfigurationFiles "linux-host" "app"
checkAgentInstallReqs "fluent"