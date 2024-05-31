~~~
#!/bin/bash

set_env() {
    {
        echo LOCAL_LOG_FILE=""
        echo . /home/obi/test/develop-code/scripts/scale/env/

        echo ACTION="${1}"
        echo AZ="${2}"
        echo KIND="${3}"
        echo FILE="/home/obi/test/develop-code/scripts/scale/${4}"
    } >> /home/obi/test/develop-code/scripts/scale/env.tmp
}

set_env "$@"

source /home/obi/test/develop-code/scripts/scale/env.tmp

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

    if [ "${3}" != "deployment" ] && [ "${3}" != "deployment" ] && [ "${3}" != "all" ]; then
        echo "[deployment, deployment, all]" ; exit 2
    fi

    if [ ! -f "${4}" ]; then
        echo "File not found." ; exit 2
    fi

    echo "parameter check completed."

    return 0
}

chk_namespace() {
    current_namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')

    while IFS=',' read -r namespace kind name replicas restart
    do
        if echo "${current_namespaces}" | grep -vqw "${namespace}"; then
            echo "Namespace not found." ; exit 2
        fi
    done < <(tail -n +2 "${FILE}")

    echo "Namespace check OK."
}

check_parameter "$@"
chk_namespace

stop_ms() {
    # shellcheck source=/dev/null
    source /home/obi/test/develop-code/scripts/scale/env.tmp
    rm -rf /home/obi/test/develop-code/scripts/scale/env.tmp
    while IFS=',' read -r namespace kind name replicas restart; do
        current_replicas=$(kubectl -n "${namespace}" get "${kind}" "${name}" -o jsonpath='{.spec.replicas}')

        if [ "${current_replicas}" -eq 0 ]; then
            echo "Already 0"
        else
            kubectl -n "${namespace}" scale "${kind}" "${name}" --replicas=0
        fi
    done < <(tail -n +2 "${FILE}")

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart; do
        kubectl -n "${namespace}" wait pod --for=delete --timeout 600s -l app="${name}" > /dev/null
        echo "${kind}/${name} stop completed."
    done < <(tail -n +2 "${FILE}")
}

start_ms() {
    # shellcheck source=/dev/null
    source /home/obi/test/develop-code/scripts/scale/env.tmp
    rm -rf /home/obi/test/develop-code/scripts/scale/env.tmp
    while IFS=',' read -r namespace kind name replicas restart; do
        current_replicas=$(kubectl -n "${namespace}" get "${kind}" "${name}" -o jsonpath='{.spec.replicas}')

        if [ "${current_replicas}" -eq "${replicas}" ]; then
            echo "Already ${replicas}"
        else
            kubectl -n "${namespace}" scale "${kind}" "${name}" --replicas="${replicas}"
        fi
    done < <(tail -n +2 "${FILE}")

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart; do
        kubectl -n "${namespace}" rollout status "${kind}" "${name}" --timeout 600s > /dev/null
        echo "${kind}/${name} startup completed."
    done < <(tail -n +2 "${FILE}")
}

restart_ms() {
    # shellcheck source=/dev/null
    source /home/obi/test/develop-code/scripts/scale/env.tmp
    rm -rf /home/obi/test/develop-code/scripts/scale/env.tmp
    while IFS=',' read -r namespace kind name replicas restart; do
        if ${restart}; then
            kubectl -n "${namespace}" rollout restart "${kind}" "${name}"
        fi
    done < <(tail -n +2 "${FILE}")

    echo "Start status check"
    while IFS=',' read -r namespace kind name replicas restart; do
        if ${restart}; then
            kubectl -n "${namespace}" rollout status "${kind}" "${name}" --timeout 600s > /dev/null
            echo "${kind}/${name} restart completed."
        fi
    done < <(tail -n +2 "${FILE}")
}

if [ "${ACTION}" == "stop" ]; then
    export -f stop_ms
    if ! timeout 10s bash -c stop_ms; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "start" ]; then
    export -f start_ms
    if ! timeout 10s bash -c start_ms; then
        echo "Failed" ; exit 1
    fi
elif [ "${ACTION}" == "restart" ]; then
    export -f restart_ms
    if ! timeout 10s bash -c restart_ms; then
        echo "Failed" ; exit 1
    fi
fi





namespace,kind,name,replicas,restart
test01,deployment,x-test-01,1,true
test01,deployment,x-test-02,1,false
test01,deployment,x-test-03,1,true
test02,deployment,x-test-04,1,false
test02,deployment,x-test-05,1,true
test03,deployment,x-test-06,1,false
test03,statefulset,x-test-07,1,true
test04,statefulset,x-test-08,1,false
~~~
