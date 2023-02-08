~~~
import os
import json
import logging
import urllib3

http = urllib3.PoolManager()
# http = urllib3.ProxyManager(os.environ['HTTP_PROXY'])
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_secret(secret_name, secret_key):
    http_secret = urllib3.PoolManager()
    headers = {
        'X-Aws-Parameters-Secrets-Token': os.environ['AWS_SESSION_TOKEN']
    }
    secret_url = f'http://localhost:2773/secretsmanager/get?secretId={secret_name}'
    response = http_secret.request('GET', secret_url, headers=headers)
    secret_string = json.loads(json.loads(response.data)['SecretString'])

    return secret_string[secret_key]


def send_msg_to_slack(webhook_url, slack_msg, severity):
    url = webhook_url
    msg = {
        "text": slack_msg
    }
    encoded_msg = json.dumps(msg).encode("utf-8")
    response = http.request("POST", url, body=encoded_msg)

    logger.info(f'{severity} event sent. status: {response.status}')


def lambda_handler(event, context):

    sns_msg = json.loads(event["Records"][0]["Sns"]["Message"])

    log_group = sns_msg["detail"]["logGroup"]
    msg_list = [x["message"] for x in sns_msg["detail"]["logEvents"]]
    message = f'LogGroup: {log_group}\nMessage:\n{"".join(msg_list)}'
    sns_severity = event["Records"][0]["Sns"]['TopicArn']

    if sns_severity.endswith('CRIT'):
        webhook_url = get_secret(os.environ['SECRET_NAME'], os.environ['SECRET_KEY_CRIT'])
        send_msg_to_slack(webhook_url, message, 'CRITICAL')
    elif sns_severity.endswith('WARN'):
        webhook_url = get_secret(os.environ['SECRET_NAME'], os.environ['SECRET_KEY_WARN'])
        send_msg_to_slack(webhook_url, message, 'WARNING')
    elif sns_severity.endswith('INFO'):
        webhook_url = get_secret(os.environ['SECRET_NAME'], os.environ['SECRET_KEY_INFO'])
        send_msg_to_slack(webhook_url, message, 'INFORMATIONAL')
    else:
        raise Exception('Unexpected SNS Message.')

~~~
