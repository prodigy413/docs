~~~
#!/bin/bash

export SET_ENV="
LOCAL_LOG_FILE=""
"

export SET_VARIABLE="
ACTION=${1}
AZ=${2}
KIND=${3}
FILE=/home/obi/test/develop-code/scripts/scale/${4}
"

check_parameter() {
    echo "Start checking parameter"
    echo "All args(${0} ${*})"

    if [ ${#} -ne 4 ]; then
        echo "Args shouldd be 4" ; exit 2
    fi

    if [ "${1}" != "start" ] && [ "${1}" != "stop" ] && [ "${1}" != "restart" ]; then
        echo "[start, stop, restart]" ; exit 2
    fi

    if [ "${2}" != "az02" ] && [ "${2}" != "az04" ]; then
        echo "[az02, az04]" ; exit 2
    fi

    if [ "${3}" != "deployment" ] && [ "${3}" != "statefulset" ] && [ "${3}" != "all" ]; then
        echo "[deployment, deployment, all]" ; exit 2
    fi

    if [ ! -f "${4}" ]; then
        echo "File not found." ; exit 2
    fi

    echo "parameter check completed."

    return 0
}

GET_CURRENT_MS_DATA() {
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

GET_TARGET_MS_DATA() {
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

#CHK_RESOURCE_EXIST() {
#    local KEYWORD=$1 
#    local RESOURCE_FOUND=0
#
#    for _DATA in "${CURRENT_MS_DATA[@]}"
#    do
#        if [[ "${_DATA}" == *"${KEYWORD}"* ]]; then
#            RESOURCE_FOUND=1
#            break
#        fi
#    done
#
#    return ${RESOURCE_FOUND}
#}

CHK_RESOURCE_EXIST() {

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

STOP_MS() {
    #declare -a TARGET_MS_DATA
    eval "${SET_ENV}" > /dev/null 2>&1
    eval "${SET_VARIABLE}" > /dev/null 2>&1
    GET_TARGET_MS_DATA

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

START_MS() {
    eval "${SET_ENV}" > /dev/null 2>&1
    eval "${SET_VARIABLE}" > /dev/null 2>&1
    GET_TARGET_MS_DATA

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

RESTART_MS() {
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

check_parameter "$@"

eval "${SET_VARIABLE}" > /dev/null 2>&1

GET_CURRENT_MS_DATA

CHK_RESOURCE_EXIST

#while IFS=',' read -r namespace kind name replicas restart
#do
#    DATA="${namespace},${kind},${name}"
#    if CHK_RESOURCE_EXIST "${DATA}"; then
#        echo "${DATA} not found"
#        break
#    fi
#
#done < <(grep -v '^#' "${FILE}" | tail -n +2)

if [ "${ACTION}" == "stop" ]; then
    export -f STOP_MS GET_TARGET_MS_DATA
    if ! timeout 10m bash -c STOP_MS; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "start" ]; then
    export -f START_MS GET_TARGET_MS_DATA
    if ! timeout 10m bash -c START_MS; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "restart" ]; then
    export -f RESTART_MS
    if ! timeout 10m bash -c RESTART_MS; then
        echo "Failed" ; exit 1
    fi
fi
~~~
