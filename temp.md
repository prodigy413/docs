~~~
import os
import json
import logging
import urllib3

http = urllib3.PoolManager()
# http = urllib3.ProxyManager(os.environ['HTTP_PROXY'])
logger = logging.getLogger()
logger.setLevel(logging.INFO)


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
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_CRIT'], message, 'CRITICAL')
    elif sns_severity.endswith('WARN'):
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_WARN'], message, 'WARNING')
    elif sns_severity.endswith('INFO'):
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_INFO'], message, 'INFORMATIONAL')
    else:
        raise Exception('Unexpected SNS Message.')








    variables = {
      HTTP_PROXY         = "http://10.0.1.239:3128"
      HTTPS_PROXY        = "http://10.0.1.239:3128"
      SLACK_WEBHOOK_CRIT = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      SLACK_WEBHOOK_WARN = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
~~~
