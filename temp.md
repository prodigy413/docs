~~~json
{
	"metrics": {
		"aggregation_dimensions": [
			[
				"InstanceId"
			]
		],
		"append_dimensions": {
			"ImageId": "${aws:ImageId}",
			"InstanceId": "${aws:InstanceId}",
			"InstanceType": "${aws:InstanceType}"
		},
		"metrics_collected": {
			"procstat": [
				{
					"exe": "amazon-ssm-agent",
					"measurement": [
						"pid_count"
					],
					"metrics_collection_interval": 60
				},
				{
					"exe": "amazon-cloudwatch-agent",
					"measurement": [
						"pid_count"
					],
					"metrics_collection_interval": 60
				},
				{
					"exe": "sshd",
					"measurement": [
						"pid_count"
					],
					"metrics_collection_interval": 60
				}
			],
			"disk": {
				"measurement": [
					"used_percent"
				],
				"metrics_collection_interval": 60,
				"resources": [
					"*"
				]
			},
			"mem": {
				"measurement": [
					"mem_used_percent"
				],
				"metrics_collection_interval": 60
			}
		}
	},
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/messages",
						"log_group_name": "obi-test-log"
					}
				]
			}
		}
	}
}
~~~
