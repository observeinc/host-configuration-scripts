#!/bin/bash

customer_id=0
ingest_token=0
observe_host_name_base=

archive_config="FALSE"
cloud_metadata="TRUE"
datacenter=""
appgroup=""
branch="main"
validate_endpoint="TRUE"
modules=()
#supported_agents=("fluent" "telegraf1" "osquery1")
archive_configs="TRUE"
observe_domain="collect.observeinc.com"
observe_environment=""
fluent_config_directory="/etc/fluent-bit/"
telegraf_config_directory="/etc/telegraf/"
osquery_config_directory="/etc/osquery/"

base_url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch}"
config_file_directory="$HOME/observe_config_files"

declare -A config_replacements
declare -A fluent_record_modifiers
declare -A supported_agents

supported_agents["fluent"]="/etc/td-agent-bit/"
supported_agents["telegraf1"]="/etc/telegraf/"
supported_agents["osquery1"]="/etc/osquery/"

fluent_record_modifiers["host"]="\${HOSTNAME}"
fluent_record_modifiers["#REPLACE_WITH_RECORD_MODIFIERS#"]=""

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
        echo "need to install $agent, or check status"
        # get agent configs
        getConfigurationFiles "$agent" "agent"

        installAgent
    else
        echo "$agent not needed for this install/upgrade... skipping"
    fi
}

installAgent () {
    #TODO: this can probably be more elegant 
    `curl ${base_url}/installer_scripts/observe_${observe_os}_${agent}.sh --fail --create-dirs --output ${config_file_directory}/installer/observe_${observe_os}_${agent}.sh`
    `chmod 700 ${config_file_directory}/installer/observe_${observe_os}_${agent}.sh`
    "${config_file_directory}/installer/observe_${observe_os}_${agent}.sh"
}

getOSDetails () {
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

parseInputs () {
    # Parse command-line options
    options=$(getopt -o c:t:m:b:d:a:h --long customer_id:,ingest_token:,module:,branch:,datacenter:,appgroup:,extract_tag:,module_option:,help,module_flag,archive_configs,observe_domain: -- "$@")
    eval set -- "$options"

    # Handle options
    while true; do
    case $1 in
        -c|--customer_id)
        customer_id=$2
        config_replacements["#REPLACE_WITH_CUSTOMER_ID#"]=$customer_id
        shift 2
        ;;
        -t|--ingest_token)
        ingest_token=$2
        config_replacements["#REPLACE_WITH_CUSTOMER_INGEST_TOKEN#"]=$ingest_token
        shift 2
        ;;
        -m|--module)
        modules+=($2)
        shift 2
        ;;
        -b|--branch)
        branch=$2
        echo $branch
        base_url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch}"
        shift 2
        ;;
        -d|--datacenter)
        datacenter=$2
        config_replacements["#REPLACE_WITH_DATACENTER#"]=$datacenter
        fluent_record_modifiers["datacenter"]=$datacenter
        shift 2
        ;;
        --appgroup)
        appgroup=$2
        config_replacements["#REPLACE_WITH_APPGROUP#"]=$appgroup
        fluent_record_modifiers["appgroup"]=$appgroup
        shift 2
        ;;
        --extract_tag)
        #extract the key=value pair for a record modifier
        fluent_record_modifiers[$(echo $2 | cut -d= -f1)]=$(echo $2 | cut -d= -f2)
        shift 2
        ;;
        --module_option)
        #extract the key=value pair for a record modifier
        config_replacements[$(echo $2 | cut -d= -f1)]=$(echo $2 | cut -d= -f2)
        shift 2
        ;;
        --module_flag)
        #TODO: implement this for ec2?
        ;;
        --observe_domain)
        observe_domain=$2
        #update observe environement whenever customer_id or observe_domain is changed.
        observe_environment="https://${customer_id}.${observe_domain}"
        shift 2
        ;;
        --archive_configs)
        #TODO: which way do we want this?
        ;;
        -h|--help)
        printHelp
        ;;
        --)
        shift
        break
        ;;
        *)
        requiredInputs
        ;;
    esac
    done
    
    #build observe environment string
    observe_environment="https:\/\/${customer_id}.${observe_domain}"
    config_replacements["#REPLACE_WITH_OBSERVE_ENVIRONMENT#"]="${observe_environment}"
}

requiredInputs(){
    echo "* Error: Invalid argument.*"
    printVariables
    printHelp
    exit 1
}

printVariables () {
      echo "* VARIABLES *"

      echo "customer_id: $customer_id"
      echo "ingest_token: $ingest_token"
      echo "observe_host_name: $observe_host_name"
      echo "config_files_clean: $config_files_clean"
      echo "ec2metadata: $ec2metadata"
      echo "cloud_metadata: $cloud_metadata"
      echo "datacenter: $datacenter"
      echo "appgroup: $appgroup"
      echo "testeject: $testeject"
      echo "validate_endpoint: $validate_endpoint"
      echo "branch: $branch"
      echo "module: $module"
      echo "observe_jenkins_path: ${observe_jenkins_path}"
      for key in "${!config_replacements[@]}"; do
        echo "${key} is ${config_replacements[${key}]}"
      done
      for key in "${!fluent_record_modifiers[@]}"; do
        echo "${key} is ${fluent_record_modifiers[${key}]}"
      done
}

printHelp(){

      echo "## HELP CONTENT"

      echo "### Required inputs"
      echo "- Required --customer_id YOUR_OBSERVE_CUSTOMERID "
      echo "- Required --ingest_token YOUR_OBSERVE_DATA_STREAM_TOKEN "
      echo "## Optional inputs"
      echo "- Optional --observe_host_name - Defaults to https://<YOUR_OBSERVE_CUSTOMERID>.collect.observeinc.com/ "
      echo "- Optional --config_files_clean TRUE or FALSE - Defaults to FALSE "
      echo "    - controls whether to delete created config_files temp directory"
      echo "- Optional --ec2metadata TRUE or FALSE - Defaults to FALSE "
      echo "    - controls fluentbit config for whether to use default ec2 metrics "
      echo "- Optional --cloud_metadata TRUE or FALSE - Defaults to FALSE"
      echo "    - controls fluentbit config for whether to poll for VM metadata"
      echo "- Optional --datacenter defaults to AWS"
      echo "- Optional --appgroup id supplied sets value in fluentbit config"
      echo "- Optional --branch_input branch of repository to pull scrips and config files from -Defaults to main"
      echo "- Optional --validate_endpoint of observe_hostname using customer_id and ingest_token -Defaults to TRUE"
      echo "- Optional --module to use for installs -Defaults to linux_host which installs osquery, fluentbit and telegraf"
      echo "    - Optional module flag: securityonion adds a config to fluentbit. If securityonion is specified without linux_host, only fluent bit will be installed."
      echo "    - Optional module flag: jenkins adds a config to fluentbit. If jenkins is specified without linux_host, only fluent bit will be installed."
      echo "- Optional --observe_jenkins_path used in combination with jenkins module - location of jenkins echos"
      echo "- Optional --custom_fluentbit_config add an additional configuration file for fluentbit"
      echo "***************************"
      echo "### Sample command:"
      echo "\`\`\` curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh  | bash -s -- --customer_id YOUR_CUSTOMERID --ingest_token YOUR_DATA_STREAM_TOKEN --observe_host_name https://<YOUR_CUSTOMERID>.collect.observeinc.com/ --config_files_clean TRUE --ec2metadata TRUE --datacenter MY_DATA_CENTER --appgroup MY_APP_GROUP\`\`\`"
      echo "***************************"
      exit 0
}

updateConfigs () {

    #TODO - add in logic that config file directory exists and has stuff in it
    for key in "${!config_replacements[@]}"; do
        sed -i "s/${key}/${config_replacements[${key}]}/g" "${config_file_directory}"/*/observe/*
    done

    # if [ "$ec2metadata" == TRUE ]; then
    #     sed -i "s/#REPLACE_WITH_OBSERVE_EC2_OPTION//g" $config_file_directory/*
    # fi
}

deployConfigs () {
    #TODO add in compare logic for existing files.
    #TODO some sort of logic to avoid duplicate stanzas?
    #TODO dry-run flag?

    for agent in "${!supported_agents[@]}"; do
        if [[ -d "${config_file_directory}/${agent}" ]]; then
            cp -r "${config_file_directory}/${agent}"/* "${config_replacements[${agent}]}"
            echo "copied ?  ${config_file_directory}/${agent}/* to ${supported_agents[${agent}]}"
            sleep 5
        else
            echo "${config_file_directory}/${agent} does not exist - cannot deploy configuration files!"
        fi
    done
}

cleanup () {
    if  [ $archive_configs ]; then
        tempdir="$(date +%Y%m%d%H%M)"
        mkdir -p "${config_file_directory}"/archive/"${tempdir}"
        mv "${config_file_directory}"/* "${config_file_directory}"/archive/"${tempdir}" > /dev/null 2>&1
    fi
}

validateObserveHostName () {
  local url="$1"
  # check for properly formatted url input - assumes - https://<customer-id>.collect.observe[anything]/
  # we can modify this rule to be specific as needed
  regex='^(https?)://[0-9]+.collect.observe[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*\/'


  if [[ $url =~ $regex ]]
  then
      echo "$url IS valid"
  else
      echo "$url IS NOT valid - example valid input - https://123456789012.collect.observeinc.com/"
      exit 1
  fi
}

# Do the work.

parseInputs $@

getOSDetails

for this_module in $modules; do
    getConfigurationFiles $this_module "app"
done

updateConfigs

for agent in "${!supported_agents[@]}"; do
    checkAgentInstallReqs $agent
done

deployConfigs

cleanup