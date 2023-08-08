import configparser
import json
import re
import logging
import requests
import os, sys
import pprint


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


def send_query(bearer_token: str, query: str, url_extension: str = '', type='gql') -> object:
    """

    @param bearer_token: generated from credentials
    @param query: graphQL query
    @return: response of graphQL query
    """
    customer_id = getObserveConfig("customer_id", ENVIRONMENT)
    domain = getObserveConfig("domain", ENVIRONMENT)

    # Set the GraphQL API endpoint URL
    url = f"https://{customer_id}.{domain}.com/v1/meta{url_extension}"

    # Set the headers (including authentication)
    headers = {
        "Authorization": f"""Bearer {customer_id} {bearer_token}""",
        'Content-Type': 'application/json',
        'Accept': 'application/x-ndjson'
    }

    # Create the request payload for GQL/OpenAPI
    if type == 'gql':
        data = {
            'query': query
        }
    elif type == 'openapi':
        data = json.loads(query)
    else:
        data = {None}
    # Send the POST request
    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        #result = response.json() #TODO json object is per line with new line delimiteres for openpi
        if type == 'gql':
            result = response.json()
            logger.debug("Request for query {} successful with status code {}:".format(query, response.status_code))
            logger.debug("Response:{}".format(result))
            return result
        else:
            result = response.text
            json_objects = result.strip().split('\n')
            json_list = []
            for obj in json_objects:
                json_list.append(json.loads(obj))
            logger.debug("Request for query {} successful with status code {}:".format(query, response.status_code))
            logger.debug("Response:{}".format(json_list))
            return json_list
    except requests.exceptions.HTTPError as err:
        logging.debug(err.request.url)
        logging.debug(err)
        logging.debug(err.response.text)
        return None


def search_dataset_id(bearer_token: str, dataset_name: str) -> str:
    """Uses Bearer token and dataset_name to return dataset_id
    dataset_id is used to query a dataset
    @param bearer_token: token for querying
    @param dataset_name: dataset name for which to find its id eg: "Server/OSQuery Events"
    @return:
    """

    query = """    
    query {
        datasetSearch(labelMatches: "%s"){
            dataset{
                id
                name
            }
        }
    }
    """ % (dataset_name)

    response = send_query(bearer_token, query, type='gql')

    dataset_id = response["data"]["datasetSearch"][0]["dataset"]["id"]
    logging.debug("Dataset Name: {} <-->  Dataset ID: {}".format(dataset_name, dataset_id))

    return dataset_id


def query_dataset(bearer_token: str, dataset_id: str, pipeline: str = "", interval: str ="30m") -> object:
    """

    Queries the last 30 minutes (default) of a dataset returning result of query. Uses Observe OpenAPI

    @param bearer_token: bearer token for authorization
    @param dataset_id: dataset_id to query using openAPI query
    @param pipeline: OPAL Pipeline

    @return: dataset: queried dataset  in json separated by timestamps

    See  https://developer.observeinc.com/#/paths/~1v1~1meta~1export~1query/post
    """
    logger.info("Querying Dataset for Dataset ID: {}".format(dataset_id))
    query = """
     {
        "query": {
            "stages":[
              {
                 "input":[
                     {
                     "inputName": "default",
                     "datasetId": "%s"
                    }
                ],
                "stageID":"main",
                "pipeline": "%s"
            }
        ]
      },

      "interval" : "%s"
      
    }
    """ % (dataset_id, pipeline, interval)
    dataset = send_query(bearer_token, query, url_extension='/export/query', type='openapi')
    return dataset


def main():
    logger.info("Starting Validation...")
    logging.getLogger().setLevel(logging.DEBUG)

    fluentbit_pipeline = "make_col ec2_instance_id:string(event.ec2_instance_id)|make_col " \
                         "name:'fluentbit_events'|timechart options(bins: 1), " \
                         "count: count_distinct_exact(1), group_by(ec2_instance_id,name)"

    telegraf_pipeline = "make_col ec2_instance_id:string(tags.instanceId)|make_col name:'telegraf_events'|timechart " \
                        "options(bins: 1), count: count_distinct_exact(1), group_by(ec2_instance_id, name)"

    osquery_pipeline = "make_col ec2_instance_id:string(tags.ec2_instance_id)|make_col " \
                       "name:'osquery_events'|timechart options(bins: 1), " \
                       "count: count_distinct_exact(1), group_by(ec2_instance_id,name)"

    bearer_token = get_bearer_token()

    fluentbit_events_id = search_dataset_id(bearer_token, "Server/Fluentbit Events")
    osquery_events_id = search_dataset_id(bearer_token, "Server/OSQuery Events")
    telegraf_events_id = search_dataset_id(bearer_token, "Server/Telegraf Events")

    fluent_bit_query = query_dataset(bearer_token, fluentbit_events_id, fluentbit_pipeline)
    osquery_query = query_dataset(bearer_token, osquery_events_id,  osquery_pipeline)
    telegraf_query = query_dataset(bearer_token, telegraf_events_id,  telegraf_pipeline)

    pass


if __name__ == '__main__':
    main()
