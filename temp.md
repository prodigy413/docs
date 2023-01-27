~~~
def lambda_handler(event, context):
    response = logs_client.describe_log_groups()

    #log_groups_from_env = json.loads(f"[{os.environ['LOG_GROUP_LISTS']}]")
    log_groups_from_env = os.environ['LOG_GROUP_LISTS'].split(',')
    log_groups_from_aws = jmespath.search('logGroups[].logGroupName', response)
    log_group_final = []

    for log_group in log_groups_from_env:
        if log_group not in log_groups_from_aws:
            logger.warning(f'{log_group} does not exist.')
        else:
            log_group_final.append(log_group)

    logger.info(f'Target Log Groups : {log_group_final}')
    logger.info('Target log groups check completed.')

    return {
        'element_num': len(log_group_final),
        'log_groups': log_group_final
    }
~~~
