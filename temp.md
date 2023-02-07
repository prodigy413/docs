~~~
def copy_task(source_bucket, target_bucket, key):
    s3 = boto3.client('s3')
    source_info = {
        'Bucket': source_bucket,
        'Key': key
    }
    s3.copy_object(CopySource=source_info, Bucket=target_bucket, Key=key)
~~~
