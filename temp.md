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

retry_command=2

check_args() {
    F_write_log_local "[I] Start checking parameter." 1
    F_write_log_local "[I] All args(${0} ${*})"

    if [ ${#} -ne 4 ]; then
        F_write_log_local "[E] The number of args is wrong."
        RC=${RE_ERROR} ; F_err_shell
    fi

    if [ "${1}" != "start" ] && [ "${1}" != "stop" ] && [ "${1}" != "restart" ]; then
        F_write_log_local "[E] 1st parameter is wrong."
        RC=${RE_ERROR} ; F_err_shell
    fi

    if [ "${2}" != "az02" ] && [ "${2}" != "az04" ]; then
        F_write_log_local "[E] 2nd parameter is wrong."
        RC=${RE_ERROR} ; F_err_shell
    fi

    if [ "${3}" != "deployment" ] && [ "${3}" != "statefulset" ] && [ "${3}" != "all" ]; then
        F_write_log_local "[E] 3rd parameter is wrong."
        RC=${RE_ERROR} ; F_err_shell
    fi

    if [ ! -f "${4}" ]; then
        F_write_log_local "[E] 4th parameter is wrong."
    fi

    F_write_log_local "[I] Checking paramter completed."

    return 0
}

retry_command() {
    local target_command="${@}"

    for i in $(seq 1 ${retry_command})
    do
        if ! eval "${target_command}" > /dev/null 2>&1; then
            F_write_log_local "[I] [${namespace}/${name}]: retry failed command. retry count:${i}"
            sleep 1
        else
            break
        fi
    done
}

get_current_ms_data() {
    GET_RESOURCE_CMD=(
        "kubectl get deployment,statefulset,daemonset -A --no-headers"
        "-o=custom-columns=\"NS:metadata.namespace,KIND:kind,NAME:metadata.name,REPLICAS:spec.replicas\""
        "| awk 'BEGIN {OFS=\",\"} {\$1=\$1;print}'"
    )

    if ! eval "${GET_RESOURCE_CMD[@]}" > /dev/null 2>&1; then
        echo "Failed get resource." ; exit 1
    fi

    while IFS= read -r line; do
        CURRENT_MS_DATA+=("${line,,}") # uppercase to lowercase
    done < <(eval "${GET_RESOURCE_CMD[@]}")
}

get_target_ms_data() {
    while IFS=',' read -r namespace kind name replicas restart; do
        if [ "${KIND}" == "deployment" ]; then
            if [ "${kind}" == "${KIND}" ]; then
                TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${restart}")
            fi
        elif [ "${KIND}" == "statefulset" ]; then
            if [ "${kind}" == "${KIND}" ]; then
                TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${restart}")
            fi
        elif [ "${KIND}" == "all" ]; then
            if [ "${kind}" == "deployment" ] || [ "${kind}" == "statefulset" ]; then
                TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${restart}")
            fi
        fi
done < <(grep -v '^#' "${FILE}" | tail -n +2)
}

check_ms_exists() {

    while IFS=',' read -r namespace kind name replicas restart
    do
        DATA_FROM_LIST="${namespace},${kind},${name}"
        for DATA_FROM_K8S in "${CURRENT_MS_DATA[@]}"
        do
            local RESOURCE_FOUND=0
            if [[ "${DATA_FROM_K8S}" == *"${DATA_FROM_LIST}"* ]]; then
                RESOURCE_FOUND=1
                break
            fi
        done

        if [ "${RESOURCE_FOUND}" -eq 0 ]; then
            echo "${DATA_FROM_LIST} not found" ; exit 1
        fi

    done < <(grep -v '^#' "${FILE}" | tail -n +2)
}

stop_ms() {
    #declare -a TARGET_MS_DATA
    eval "${SET_ENV}" > /dev/null 2>&1
    eval "${SET_VARIABLE}" > /dev/null 2>&1
    get_target_ms_data

    while IFS=',' read -r namespace kind name replicas restart
    do
        kubectl -n "${namespace}" scale "${kind}" "${name}" --replicas=0
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart
    do
        kubectl -n "${namespace}" wait pod --for=delete --timeout 600s -l app="${name}" > /dev/null
        echo "${kind}/${name} stop completed."
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

start_ms() {
    eval "${SET_ENV}" > /dev/null 2>&1
    eval "${SET_VARIABLE}" > /dev/null 2>&1
    get_target_ms_data

    while IFS=',' read -r namespace kind name replicas restart
    do
        kubectl -n "${namespace}" scale "${kind}" "${name}" --replicas="${replicas}"
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart
    do
        kubectl -n "${namespace}" rollout status "${kind}" "${name}" --timeout 600s > /dev/null
        echo "${kind}/${name} startup completed."
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")
}

restart_ms() {
    eval "${SET_ENV}" > /dev/null 2>&1
    eval "${SET_VARIABLE}" > /dev/null 2>&1

    while IFS=',' read -r namespace kind name replicas restart; do
        if ${restart}; then
            kubectl -n "${namespace}" rollout restart "${kind}" "${name}"
        fi
    done < <(grep -v '^#' "${FILE}" | tail -n +2)

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart; do
        if ${restart}; then
            kubectl -n "${namespace}" rollout status "${kind}" "${name}" --timeout 600s > /dev/null
            echo "${kind}/${name} restart completed."
        fi
    done < <(grep -v '^#' "${FILE}" | tail -n +2)
}

eval "${SET_ENV}" > /dev/null 2>&1

check_args "$@"

eval "${SET_VARIABLE}" > /dev/null 2>&1

get_current_ms_data

check_ms_exist

if [ "${ACTION}" == "stop" ]; then
    export -f stop_ms get_target_ms_data
    if ! timeout 10m bash -c stop_ms; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "start" ]; then
    export -f start_ms get_target_ms_data
    if ! timeout 10m bash -c start_ms; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "restart" ]; then
    export -f restart_ms
    if ! timeout 10m bash -c restart_ms; then
        echo "Failed" ; exit 1
    fi
fi
~~~
