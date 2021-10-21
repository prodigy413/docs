~~~python
import boto3
import datetime

client = boto3.client('cloudwatch')

statistics = {"sum":"Sum", "avg":"Average", "max":"Maximum"}
seconds_of_day = 86400
start_time = datetime.datetime.now() - datetime.timedelta(days=1)
end_time = datetime.datetime.now()

response = client.get_metric_statistics(
    Namespace = "ECS/ContainerInsights",
    MetricName = "CpuUtilized",
    Dimensions = [
        {
            "Name": "TaskDefinitionFamily",
            "Value": "test"
        },
        {
            "Name": "ClusterName",
            "Value": "greatobi-dev-ecs-01"
        }
    ],
    StartTime = start_time,
    EndTime = end_time,
    Period = seconds_of_day,
    Statistics = [statistics["avg"]]
)
ecs_resource = print(response["Datapoints"][0][statistics["avg"]])
~~~
