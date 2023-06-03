~~~
ENDPOINT=""
AWS_CLI="aws"
AWS_PROFILE=""
BUCKET="obi-test-tfstate"
OBJ_PREFIX="m8dpop1s_fluentd_ns_`date +%Y%m%d`"

base_dir="/tmp/20230603_test/"
report_file="`date +%Y%m%d`_log_check_report.csv"
csv_header="Namespace,MS,LogCount"
echo ${csv_header} >> ${base_dir}${report_file}
declare -A MS_INFO

OBJ_NAME=$(sudo ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${AWS_PROFILE} s3 ls s3://${BUCKET} | grep -i ${OBJ_PREFIX} | awk '{print $4}')

cd ${base_dir}
sudo ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${AWS_PROFILE} s3 cp s3://${BUCKET}/${OBJ_NAME} .

sudo tar xf ${OBJ_NAME}

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

~~~
