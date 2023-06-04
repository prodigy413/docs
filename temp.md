~~~
#!/bin/bash

ENDPOINT=""
AWS_CLI="aws"
AWS_PROFILE=""
BUCKET="obi-test-tfstate"
OBJ_PREFIX="xxxxxx_fluentd_ns_`date +%Y%m%d`"

base_dir="/tmp/20230604_test/"
report_file="`date +%Y%m%d`_log_check_report.csv"
csv_header="Namespace,MS,LogCount"
echo ${csv_header} >> ${base_dir}${report_file}
declare -A MS_INFO

#OBJ_NAME=$(sudo ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${AWS_PROFILE} s3 ls s3://${BUCKET} | grep -i ${OBJ_PREFIX} | awk '{print $4}')
OBJ_NAME=$(${AWS_CLI} s3 ls s3://${BUCKET} | grep -i ${OBJ_PREFIX} | awk '{print $4}')

cd ${base_dir}
#sudo timeout ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${AWS_PROFILE} s3 cp s3://${BUCKET}/${OBJ_NAME} .
timeout ${AWS_CLI} s3 cp s3://${BUCKET}/${OBJ_NAME} .

#sudo tar xf ${OBJ_NAME}
tar xf ${OBJ_NAME}

ns_dir=($(ls -l | grep ^d | awk '{print $9}' | grep ^release | sort))

for dir in ${ns_dir[@]}
do
    cd ${base_dir}${dir}

    for I in `ls | grep .gz`
    do
        MS_NAME=`echo $I | cut -f 1 -d "."`
        MS_COUNT=$(gzip -dc $I | awk '{print $3}' | sort | uniq)
        MS_INFO[${MS_NAME}]=$(echo ${MS_COUNT} | sed 's/ /\n/g' | wc -l)
        echo ${dir},${MS_NAME},${MS_INFO[${MS_NAME}]} >> ${base_dir}${report_file}
    done
done





#!/bin/bash

base_dir="/tmp/logs/"
declare -A MS_INFO

cd ${base_dir}

ns_dir=($(ls -l | grep ^d | awk '{print $9}' | grep ^release | sort))

for dir in ${ns_dir[@]}
do
    cd ${base_dir}${dir}

    for I in `ls | grep .log`
    do
        MS_NAME=`echo $I | cut -f 1 -d "."`
        MS_COUNT=$(cat $I | awk '{print $3}' | sort | uniq)
        MS_INFO[${MS_NAME}]=$(echo ${MS_COUNT} | sed 's/ /\n/g' | wc -l)

        if [[ ${MS_INFO[${MS_NAME}]} -lt 3 ]]
        then
            echo ${dir},${MS_NAME},${MS_INFO[${MS_NAME}]}
            echo "Restart MS"
            kubectl rollout restart deployment nginx01
        fi
    done
done

~~~
