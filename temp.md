~~~
import boto3
import logging
#import mcid_logger

logs_client = boto3.client('logs')
#logger = mcid_logger.MCIDLogger(__name__)
#logger.setup("INFO", True)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    task_id = event['iterator']['task_id']

    # エクスポートタスク ステータス取得
    if task_id == "task_skipped":
        status_code = "COMPLETED"
    else:
        response = logs_client.describe_export_tasks(
            taskId=task_id,
        )
        status_code = response['exportTasks'][0]['status']['code']

    logger.info('Task ID : ' + task_id)
    logger.info('Status code : ' + status_code)
    #logger.info('Task ID : ' + task_id)
    #logger.info('Status code : ' + status_code)

    return {
        'status_code': status_code
    }
























import os
import boto3
import datetime
import logging
#import mcid_logger
from zoneinfo import ZoneInfo

logs_client = boto3.client('logs')

#logger = mcid_logger.MCIDLogger(__name__)
#logger.setup("INFO", True)
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    export_bucket = os.environ['EXPORT_BUCKET']
    index = event['iterator']['index']
    count = event['describe_log_groups']['element_num']
    target_log_group = event['describe_log_groups']['log_groups'][index]

    # Get Service Name and Change log group name
    if target_log_group.startswith('/aws/'):
        service_name = f"{(target_log_group.split('/')[2]).upper()}"
        
    elif target_log_group.startswith('LG-'):
        service_name = f"{target_log_group.split('-')[2]}"

    modified_log_group = f"{target_log_group.replace('/', '_')}"

    today = datetime.datetime.now(ZoneInfo("Asia/Tokyo")).date()     # 実行日取得（例：2023-01-30）
    yesterday = today - datetime.timedelta(days=1)                   # 前日取得（例：2023-01-29）
    # 出力日時（from）取得（例：2023-01-29 00:00:00）
    # from_time = datetime.datetime(year=yesterday.year, month=yesterday.month, day=yesterday.day, hour=0, minute=0,second=0)
    # 出力日時（to）取得（例：2023-01-29 23:59:59.999999）
    # to_time = datetime.datetime(year=yesterday.year, month=yesterday.month, day=yesterday.day, hour=23, minute=59,second=59,microsecond=999999)
    # 出力日時（from）取得（例：2023-01-29 00:00:00）
    from_time = datetime.datetime(year=today.year, month=today.month, day=today.day, hour=0, minute=0, second=0)
    # 出力日時（to）取得（例：2023-01-29 23:59:59.999999）
    to_time = datetime.datetime(year=today.year, month=today.month, day=today.day, hour=23, minute=59, second=59, microsecond=999999)

    # エポック時刻取得(float型)
    epoc_from_time = from_time.timestamp()
    epoc_to_time = to_time.timestamp()
    # エポック時刻をミリ秒にしint型にキャスト（create_export_taskメソッドにintで渡すため）
    m_epoc_from_time = int(epoc_from_time * 1000)
    m_epoc_epoc_to_time = int(epoc_to_time * 1000)

    # CloudWatch Logsエクスポート
    try:
        response = logs_client.create_export_task(
            logGroupName = target_log_group,
            fromTime = m_epoc_from_time,
            to = m_epoc_epoc_to_time,
            destination = export_bucket,
            destinationPrefix = f"logfile/{service_name}/{yesterday.strftime('%Y/%m/%d')}/{modified_log_group}"
        )
    except logs_client.exceptions.InvalidParameterException as e:
        logger.warning(f'{target_log_group} : {e}')
        response = dict()
        response['taskId'] = "task_skipped"

    logger.info('Target log group : ' + target_log_group)
    logger.info('Task ID : ' + response['taskId'])

    index += 1

    return {
        'index': index,
        'end_flg': count == index,
        'task_id': response['taskId']
    }


~~~
