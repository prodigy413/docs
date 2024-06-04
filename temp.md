~~~bash
#!/bin/bash

RETRY_COUNT=2

NS=test01
SCRIPT_STATUS_CODE=0

F_RETRY() {
    local CMD=${1}

    for i in $(seq 1 ${RETRY_COUNT})
    do
        eval "${CMD}" > /dev/null 2>&1
        RC=$?
        if [ ${RC} -eq 0 ]; then
            echo "Good!"
            break
        else
            echo "Failed. Retry ${i}"
            sleep 1
        fi
    done

    return 1
}

K8S_CMD="kubectl get nssss ${NS}"

F_RETRY "${K8S_CMD}"
SCRIPT_STATUS_CODE=$?

if [ ${SCRIPT_STATUS_CODE} -ne 0 ]; then
    echo "Script failed."
else
    echo "Script suceeded."
fi
~~~
