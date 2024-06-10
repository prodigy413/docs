~~~
#!/bin/bash


LOCAL_LOG_FILE=""

# shellcheck source=/dev/null
. /home/obi/test/develop-code/scripts/scale/script/chc/def/chccm_env.sh
. ${CHC_DEF}/chccm_func_shell.sh
. ${CHC_DEF}/chccm_func_log.sh
. ${SHELL_DEF_DIR}/dstcn_env_kubectl.sh


ACTION=${1}

AZ=${2}

KIND=${3}

FILE=${SHELL_DEF_DIR}/${4}

RETRY_COUNT=1

KUBEUSER="kubeuser"

TIMEOUT=70

ENTIRE_RETURN_CODE=0

check_args() {
    F_write_log_local "[I] Start checking parameter." 1
    F_write_log_local "[I] All args(${0} ${*})"

    if [ ${#} -ne 4 ]; then
        exit_process "${RC_ERROR}" "[E] The number of args is wrong."
    fi

    if [ "${1}" != "start" ] && [ "${1}" != "stop" ] && [ "${1}" != "restart" ]; then
        exit_process "${RC_ERROR}" "[E] 1st parameter is wrong."
    fi

    if [ "${2}" != "az02" ] && [ "${2}" != "az04" ]; then
        exit_process "${RC_ERROR}" "[E] 2nd parameter is wrong."
    fi

    if [ "${3}" != "deployment" ] && [ "${3}" != "statefulset" ] && [ "${3}" != "all" ]; then
        exit_process "${RC_ERROR}" "[E] 3rd parameter is wrong."
    fi

    if [ ! -f "${SHELL_DEF_DIR}/${4}" ]; then
        exit_process "${RC_ERROR}" "[E] 4th parameter is wrong."
    fi

    F_write_log_local "[I] Checking paramter completed."

    return 0
}

retry_command() {
    for i in $(seq 1 ${RETRY_COUNT})
    do
        if ! eval "${1}" > /dev/null 2>&1; then
            F_write_log_local "[I] [${namespace}/${name}]: retry failed command. retry count:${i}" 1
            sleep 1
        else
            return 0
        fi
    done

    return 1
}

get_current_ms_data() {

    local -A namespace_map
    local -a target_namespace

    while IFS=',' read -r namespace _
    do
        namespace_map[${namespace}]=1
    done < <(grep -v '^#' "${FILE}" | grep -v '^\s*$' | tail -n +2)

    for ns in "${!namespace_map[@]}"
    do
        target_namespace+=("${ns}")
    done

    for ns in "${target_namespace[@]}"
    do
        local -a k8s_cmd=(
            "kubectl -n ${ns} get deployment,statefulset,daemonset --no-headers"
            "-o=custom-columns=\"NS:metadata.namespace,KIND:kind,NAME:metadata.name,LABEL:metadata.labels.name\""
            "| awk 'BEGIN {OFS=\",\"} {\$1=\$1;print}'"
        )

        if ! sudo su - ${KUBEUSER} -c "${k8s_cmd[*]}" > /dev/null 2>&1; then
            exit_process "${RC_ERROR}" "[E] Failed to get resources."
        fi

        while IFS= read -r line; do
            CURRENT_MS_DATA+=("${line,,}")
        done < <(sudo su - ${KUBEUSER} -c "${k8s_cmd[*]}")
    done
}

get_target_ms_data() {
    while IFS=',' read -r namespace kind name replicas restart status_check; do
        if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "stop" ] && ! ${restart}; then
            if [ "${KIND}" == "all" ] || [ "${kind}" == "${KIND}" ]; then
                if [ "${kind}" == "deployment" ] || [ "${kind}" == "statefulset" ]; then
                    TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${restart},${status_check}")
                fi
            fi
        elif [ "${ACTION}" == "restart" ] && ${restart}; then
            if [ "${KIND}" == "all" ] || [ "${kind}" == "${KIND}" ]; then
                if [ "${kind}" == "deployment" ] || [ "${kind}" == "statefulset" ]; then
                    TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${restart},${status_check}")
                fi
            fi
        fi
    done < <(grep -v '^#' "${FILE}" | grep -v '^\s*$' | tail -n +2)
}

check_ms_exists() {

    while IFS=',' read -r namespace kind name replicas restart status_check
    do
        local data_from_file="${namespace},${kind},${name}"
        local resource_found=0

        for data_from_l8s in "${CURRENT_MS_DATA[@]}"
        do
            if [[ "${data_from_l8s}" == *"${data_from_file}"* ]]; then
                resource_found=1
                break
            fi
        done

        if [ "${resource_found}" -eq 0 ]; then
            F_write_log_local "[${namespace}/${name}] not found" 1
            ENTIRE_RETURN_CODE=1
        fi

    done < <(grep -v '^#' "${FILE}" | grep -v '^\s*$' | tail -n +2)
}

stop_ms() {

    while IFS=',' read -r namespace kind name replicas restart status_check
    do
        local scale_cmd="kubectl -n ${namespace} scale ${kind} ${name} --replicas=0"

        if ! retry_command "sudo su - ${KUBEUSER} -c \"${scale_cmd}\""; then
            F_write_log_local "[E] [${namespace}/${name}]: failed scale." 1
            ENTIRE_RETURN_CODE=1

            for i in "${!TARGET_MS_DATA[@]}"
            do
                if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                    unset "TARGET_MS_DATA[i]"
                fi
            done
        else
            F_write_log_local "[I] [${namespace}/${name}]: scaled." 1
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

start_ms() {

    while IFS=',' read -r namespace kind name replicas restart status_check
    do
        local scale_cmd="kubectl -n ${namespace} scale ${kind} ${name} --replicas=${replicas}"
        if ! retry_command "sudo su - ${KUBEUSER} -c \"${scale_cmd}\""; then
            F_write_log_local "[E] [${namespace}/${name}]: failed scale." 1
            ENTIRE_RETURN_CODE=1

            for i in "${!TARGET_MS_DATA[@]}"
            do
                if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                    unset "TARGET_MS_DATA[i]"
                fi
            done
        else
            F_write_log_local "[I] [${namespace}/${name}]: scaled." 1
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

restart_ms() {

    while IFS=',' read -r namespace kind name replicas restart status_check
    do
        local restart_cmd="kubectl -n ${namespace} rollout restart ${kind} ${name}"
        if ! retry_command "sudo su - ${KUBEUSER} -c \"${restart_cmd}\""; then
            F_write_log_local "[E] [${namespace}/${name}]: failed restart." 1
            ENTIRE_RETURN_CODE=1

            for i in "${!TARGET_MS_DATA[@]}"
            do
                if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                    unset "TARGET_MS_DATA[i]"
                fi
            done
        else
            F_write_log_local "[I] [${namespace}/${name}]: restarted." 1
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

check_status() {
    if [[ -z "${TARGET_MS_DATA[*]}" ]]; then
            exit_process "${RC_ERROR}" "[E] Skipped status check, because all task failed."
    fi

    F_write_log_local "[I] Start status check." 1

    while IFS=',' read -r namespace kind name replicas restart status_check
    do
        if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "restart" ]; then
            status_check_cmd="kubectl -n ${namespace} rollout status ${kind} ${name} --timeout ${TIMEOUT}s > /dev/null 2>&1"
        elif [ "${ACTION}" == "stop" ]; then
            check_label_cmd="kubectl -n ${namespace} get ${kind} ${name} -o jsonpath='{.metadata.labels.name}'"
            check_label_exists=$(sudo su - ${KUBEUSER} -c "${check_label_cmd}")

            if [ -z "${check_label_exists}" ]; then
                label="app"
            else
                label="name"
            fi
            status_check_cmd="kubectl -n ${namespace} wait pod --for=delete --timeout ${TIMEOUT}s -l ${label}=${name} > /dev/null 2>&1"
        fi

        if ! sudo su - ${KUBEUSER} -c "${status_check_cmd}"; then
            F_write_log_local "[E] [${namespace}/${name}] status check failed." 1
            ENTIRE_RETURN_CODE=1
        else
            F_write_log_local "[I] [${namespace}/${name}] status check completed." 1
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

exit_process() {
    if [ -n "${2}" ]; then
        F_write_log_local "${2}" 1
    fi

    RC="${1}"

    if [ "${RC_ERROR}" -eq "${1}" ]; then
        F_err_shell
    else
        F_end_shell
    fi
}

F_sta_shell

check_args "${@}"

get_current_ms_data

check_ms_exists

get_target_ms_data

if [ "${ACTION}" == "stop" ]; then
    stop_ms
elif [ "${ACTION}" == "start" ]; then
    start_ms
elif [ "${ACTION}" == "restart" ]; then
    restart_ms
fi

check_status

if [ ${ENTIRE_RETURN_CODE} -eq 1 ]; then
    F_err_shell
else
    F_end_shell
fi




namespace,kind,name,replicas,restart,group,status_check
test01,deployment,x-test-01,1,false,1,true
test01,deployment,x-test-02,1,false,1,true
test01,deployment,x-test-03,1,false,1,true
test02,deployment,x-test-04,1,false,2,true
test02,deployment,x-test-05,1,false,1,true
test03,deployment,x-test-06,1,false,2,false
#test03,deployment,x-test-xx,1,false,1,false
test03,statefulset,x-test-07,1,false,1,false
test04,statefulset,x-test-08,1,true,2,true
test04,deployment,x-test-09,1,true,2,true
#test04,statefulset,x-test-xx,1,false,2,true
~~~
