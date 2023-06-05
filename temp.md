~~~
#!/bin/bash

ENDPOINT=""
AWS_CLI="aws"
PROFILE=""
BUCKET=(
    "obi-test-tfstate"
    "obi-test-tfstate-02"
    )
FILE_PREFIX="xxxxxxx_fluentd_ns_$(date +%Y%m%d)"

WORK_DIR="/tmp/20230605_test/"
REPORT_FILE="$(date +%Y%m%d)_log_check_report.csv"
CSV_HEADER="Bucket,Namespace,MS,LogCount"
echo ${CSV_HEADER} >> ${WORK_DIR}"${REPORT_FILE}"
declare -A MS_DATA

for BKT in "${BUCKET[@]}"
do
    cd ${WORK_DIR} || echo error
    #FILE_NAME=$(sudo ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${PROFILE} s3 ls s3://${BUCKET} | grep ${FILE_PREFIX} | awk '{print $4}')
    FILE_NAME=$(${AWS_CLI} s3 ls s3://"${BKT}" | grep "${FILE_PREFIX}" | awk '{print $4}')

    if [ -n "${FILE_NAME}" ]
    then
        #sudo timeout ${AWS_CLI} --endpoint-url ${ENDPOINT} --profile ${PROFILE} s3 cp s3://${BUCKET}/${FILE_NAME} .
        timeout 10m ${AWS_CLI} s3 cp s3://"${BKT}"/"${FILE_NAME}" .

        #sudo tar xf ${FILE_NAME}
        tar xf "${FILE_NAME}"

        NS_DIR=($(ls -ld */ | awk '{if(/release/) print $9}'| sort))

        for DIR in "${NS_DIR[@]}"
        do
            cd ${WORK_DIR}"${DIR}" || echo error

            for LOG_FILE in *.gz
            do
                MS_NAME=$(echo "${LOG_FILE}" | cut -f 1 -d ".")
                MS_COUNT=$(gzip -dc "${LOG_FILE}" | awk '{print $3}' | sort | uniq)
                MS_DATA[${MS_NAME}]=$(echo "${MS_COUNT}" | sed 's/ /\n/g' | wc -l)
                echo "${BKT}","${DIR}","${MS_NAME}","${MS_DATA[${MS_NAME}]}" >> ${WORK_DIR}"${REPORT_FILE}"
            done
        done
    fi
done








#!/bin/bash

LOG_DIR="/tmp/logs/"
declare -A MS_DATA

cd ${LOG_DIR} &>/dev/null || echo "Wrong dir"

NS_DIR=($(ls -ld */ | awk '{if(/release/) print $9}'| sort))
#NS_DIR=($(find . -type d -name "release*" | sed 's/\.\///g' | sort))
for DIR in "${NS_DIR[@]}"
do
    cd ${LOG_DIR}"${DIR}" &>/dev/null || echo "Wrong dir"

    if [ "$(ls -A .)" ]
    then
        for LOG_FILE in *.log
        do
            MS_NAME=$(echo "${LOG_FILE}" | cut -f 1 -d ".")
            MS_COUNT=$(< "${LOG_FILE}" awk '{print $3}' | sort | uniq)
            MS_DATA[${MS_NAME}]=$(echo "${MS_COUNT}" | sed 's/ /\n/g' | wc -l)

            if [[ ${MS_DATA[${MS_NAME}]} -lt 3 ]]
            then
                echo "${DIR}","${MS_NAME}","${MS_DATA[${MS_NAME}]}"
                echo "Restart MS"
                #kubectl rollout restart deployment nginx01
                exit
            else
                echo "${DIR}","${MS_NAME}","${MS_DATA[${MS_NAME}]}"
            fi
        done
    fi
done

~~~
