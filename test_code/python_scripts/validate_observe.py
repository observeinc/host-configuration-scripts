import configparser
import json
import re
import logging
import requests
import os, sys


def log_file_name(path_pattern: str) -> str:
    """
    Naive (slow) version of next_path
    """
    i = 1
    while os.path.exists(path_pattern % i):
        i += 1
    return path_pattern % i


ENVIRONMENT = 'target-stage-tenant'

# Create appropriate log_path name (without overwriting)
logs_folder_name = "validation_outputs"
log_path_pattern = f"{logs_folder_name}/test-log-%s.log"
log_path = log_file_name(log_path_pattern)
log_level = 'DEBUG'

# Set up the logger instance
logger = logging.getLogger(__name__)
logging.basicConfig(
    format="%(asctime)s %(levelname)s %(filename)s:%(lineno)d %(message)s",
    datefmt="%m/%d/%Y %I:%M:%S %p",
    level=log_level,  # Set the desired log level
    handlers=[logging.FileHandler(log_path), logging.StreamHandler(sys.stdout)],
)




def getObserveConfig(config: str, environment: str) -> str:
    """Fetches config file
    @param config:
    @param environment:
    @return: config element
    """

    # Set your Observe environment details in config\configfile.ini
    configuration = configparser.ConfigParser()
    configuration.read("config.ini")
    observe_configuration = configuration[environment]

    return observe_configuration[config]


def get_bearer_token() -> str:
    """Logins into account and gets bearer token
    @return: bearer_token
    """

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
    bearer_token = response['access_key']
    return bearer_token

def send_graphql_query(bearer_token: str, query: str) -> object:
    """

    @param bearer_token: generated from credentials
    @param query: graphQL query
    @return: response of graphQL query
    """
    customer_id = getObserveConfig("customer_id", ENVIRONMENT)
    domain = getObserveConfig("domain", ENVIRONMENT)

    # Set the GraphQL API endpoint URL
    url = f"https://{customer_id}.{domain}.com/v1/meta"

    # Set the headers (including authentication)
    headers = {
        "Authorization": f"""Bearer {customer_id} {bearer_token}""",
        'Content-Type': 'application/json',
    }

    # Create the request payload
    data = {
        'query': query
    }

    # Send the POST request
    response = requests.post(url, json=data, headers=headers)


    # Handle the response
    if response.status_code == 200:
        result = response.json()
        logger.debug("Request for query {} successful with status code {}:".format(query, response.status_code))
        logger.debug("Response:{}".format(result))
        return result
    else:
        logger.debug("Request failed with status code:", response.status_code)
        response.raise_for_status()
        return None


def get_datastream_id(bearer_token: str)-> str:
    """Uses bearer_token and returns datastream name & datastream ID for querying

    """

    datastream_token = getObserveConfig("datastream_token", ENVIRONMENT).split(':')[0].strip('"')
    query = """
    query {
      datastreamToken(id: "%s") {
        id
        name
        datastreamId
      }  
    }    
    """ % (datastream_token)

    response = send_graphql_query(bearer_token, query)
    datastream_id = response["data"]["datastreamToken"]["datastreamId"]

    return datastream_id

def get_dataset_id(bearer_token: str, datastream_id: str) -> str:
    """Uses Bearer token and datastream_id to return dataset_id
    dataset_id is used to query a dataset
    """

    datastream_token = getObserveConfig("datastream_token", ENVIRONMENT).split(':')[0].strip('"')
    query = """    
    query{
      datastream(id: "%s")
      {
        id
        name
        description
        tokens {
          id
        }
        updatedDate
        datasetId        
      }
      
    }
    """ % (datastream_id)

    response = send_graphql_query(bearer_token, query)
    dataset_id = response["data"]["datastream"]["datasetId"]

    return dataset_id





def main():
    logger.info("Starting Validation...")

    bearer_token = get_bearer_token()
    datastream_id = get_datastream_id(bearer_token)
    dataset_id = get_dataset_id(bearer_token, datastream_id)





if __name__ == '__main__':
    main()
