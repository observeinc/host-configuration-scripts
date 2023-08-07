import configparser
import json
import re
import logging
import requests
import os, sys



def setup_logging():
    """Sets up Logging"""

    def log_file_name(path_pattern):
        """
        Naive (slow) version of next_path
        """
        i = 1
        while os.path.exists(path_pattern % i):
            i += 1
        return path_pattern % i

    #Create appropriate log_path name (without overwriting)
    logs_folder_name = "validation_outputs"
    log_path_pattern = f"{logs_folder_name}/test-log-%s.log"
    log_path = log_file_name(log_path_pattern)

    # Create a logger instance for this module
    logger = logging.getLogger(__name__)
    logging.basicConfig(
        # filename=log_path,
        format="%(asctime)s %(levelname)s %(filename)s:%(lineno)d %(message)s",
        datefmt="%m/%d/%Y %I:%M:%S %p",
        # encoding="utf-8",
        level='DEBUG',
        handlers=[logging.FileHandler(log_path), logging.StreamHandler(sys.stdout)],
    )
    return logger


def getObserveConfig(config: str, environment: str) -> str:
    """Fetches config file"""
    # Set your Observe environment details in config\configfile.ini
    configuration = configparser.ConfigParser()
    configuration.read("config.ini")
    observe_configuration = configuration[environment]

    return observe_configuration[config]


def get_bearer_token() -> str:

    """Gets bearer token for login"""

    ENVIRONMENT = 'target-stage-tenant'
    customer_id = getObserveConfig("customer_id", ENVIRONMENT)
    domain = getObserveConfig("domain", ENVIRONMENT)
    user_email = getObserveConfig("user_email", ENVIRONMENT)
    user_password = getObserveConfig("user_password", ENVIRONMENT)

    url = f"https://{customer_id}.{domain}.com/v1/login"

    message = '{"user_email":"$user_email$","user_password":"$user_password$"}'
    tokens_to_replace = {
        "$user_email$": user_email,
        "$user_password$": user_password,
    }
    for key, value in tokens_to_replace.items():
        message = message.replace(key, value)

    header = {
        "Content-Type": "application/json",
    }

    response = json.loads(
        requests.post(url, data=message, headers=header, timeout=10).text
    )
    bear_toke = response['access_key']
    return bear_toke

def main():
    logger = setup_logging()
    logger.info("Starting Validation...")

    token = get_bearer_token()



if __name__ == '__main__':
    main()

