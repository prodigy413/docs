~~~
import os
import json
import logging
import urllib3
from datetime import datetime, timedelta

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
    msg_time = datetime.strptime(sns_msg['time'], '%Y-%m-%dT%H:%M:%SZ') + timedelta(hours=9)
    #msg_list = [x["message"] for x in sns_msg["detail"]["logEvents"]]
    #message = f'Time: {msg_time} JST\nLogGroup: {log_group}\nMessage:\n{"".join(msg_list)}'
    msg_list = [x for x in sns_msg["detail"]["logEvents"]]
    sample_msg = '{\n    "id": "12345678910",\n    "timestamp": 12345678910,\n    "message": "test message"\n}'
    message = f'Time: {msg_time} JST\nLogGroup: {log_group}\nMessage:\n{sample_msg}'
    sns_severity = event["Records"][0]["Sns"]['TopicArn']

    if sns_severity.endswith('CRIT'):
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_CRIT'], message, 'CRITICAL')
    elif sns_severity.endswith('WARN'):
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_WARN'], message, 'WARNING')
    elif sns_severity.endswith('INFO'):
        send_msg_to_slack(os.environ['SLACK_WEBHOOK_INFO'], message, 'INFORMATIONAL')
    else:
        raise Exception('Unexpected SNS Message.')

~~~
