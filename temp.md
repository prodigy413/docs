~~~
#!/bin/bash

set_common_profile() {
    LOCAL_LOG_FILE=""
    . /home/obi/test/develop-code/scripts/scale/script/chc/def/chccm_env.prf
    . ${CHC_DEF}/chccm_func_shell.prf
    . ${CHC_DEF}/chccm_func_log.prf
}

check_args() {
    F_write_log_local "[I] パラメータチェックを開始します。" 1
    F_write_log_local "[I] 全引数(${0} ${*})" 1

    if [ ${#} -ne 4 ]; then
        exit_process "${RC_ERROR}" "[E] パラメータ数が不正です。"
    fi

    if [ "${1}" != "start" ] && [ "${1}" != "stop" ] && [ "${1}" != "restart" ]; then
        exit_process "${RC_ERROR}" "[E] パラメータ指定（第1引数）が不正です。"
    fi

    if [ "${2}" != "tok02" ] && [ "${2}" != "tok04" ]; then
        exit_process "${RC_ERROR}""[E] パラメータ指定（第2引数）が不正です。"
    fi

    if [ "${3}" != "deployment" ] && [ "${3}" != "statefulset" ] && [ "${3}" != "all" ]; then
        exit_process "${RC_ERROR}" "[E] パラメータ指定（第3引数）が不正です。"
    fi

    if [ ! -f "${SHELL_DEF_DIR}/${4}" ]; then
        exit_process "${RC_ERROR}" "[E] 第4引数で指定したファイルが存在しません。（ ${SHELL_DEF_DIR}/${4} ）"
    fi

    F_write_log_local "[I] パラメータチェック正常終了。" 1

    return 0
}

check_csv() {
    header=$(head -n 1 "${1}")

    expected_header="namespace,kind,name,replicas,startstop,restart,status_check"

    if [ "${header}" != "${expected_header}" ]; then
        exit_process "${RC_ERROR}" "[E] MSリストファイルのヘッダー設定が不正です。"
    fi

    while IFS=',' read -r namespace kind name replicas startstop restart status_check; do

        if [[ -z "${namespace}" || -z "${kind}" || -z "${name}" || -z "${replicas}" || -z "${startstop}" || -z "${restart}" || -z "${status_check}" ]]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルの中に空の値があります。"
        elif [ "${king}" != "deployment" ] && [ "${king}" != "statefulset" ]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルのkind設定が不正です。"
        elif [[ "${replicas}" =~ ^[0-9]+$ ]]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルのkind設定が不正です。"
        elif [ "${startstop}" != "true" ] && [ "${startstop}" != "false" ]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルのstartstop設定が不正です。"
        elif [ "${restart}" != "true" ] && [ "${restart}" != "false" ]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルのrestart設定が不正です。"
        elif [ "${status_check}" != "true" ] && [ "${status_check}" != "false" ]; then
            exit_process "${RC_ERROR}" "[E] MSリストファイルのstatus_check設定が不正です。"
        fi
    done < <(grep -v '^#' "${1}" | grep -v '^\s*$' | tail -n +2)
}

retry_command() {
    for i in $(seq 1 "${RETRY_COUNT}")
    do
        if [ "${1}" -eq 1 ]; then
            if ! eval "${2}" > /dev/null 2>&1; then
                F_write_log_local "[I] 実行失敗したため、コマンドを再実行します。再実行回数：${i}。" 1
                sleep 2
            else
                return 0
            fi
        elif [ "${1}" -eq 2 ]; then
            if ! eval "${2}" > /dev/null 2>&1; then
                if [[ "${result_message}" == *"timed out waiting"* ]]; then
                    is_timeout="true"
                    break
                else
                    F_write_log_local "[I] 実行失敗したため、コマンドを再実行します。再実行回数：${i}。" 1
                    sleep 2
                fi
            else
                return 0
            fi
        elif [ "${1}" -eq 3 ]; then
            if ! eval "${2}" > /dev/null 2>&1; then
                F_write_log_local "[I] 実行失敗したため、コマンドを再実行します。再実行回数：${i}。" 1
                sleep 2
            else
                if [ "${result_message}" == "No resources found" ]; then
                    F_write_log_local "[E] [${namespace}/${name}]: 対象ラベルが見つかりませんでした。" 1
                    break
                else
                    return 0
                fi
            fi
        else
            exit_process "${RC_ERROR}" "[E] retry_command関数：パラメータ指定が不正です。"
        fi
    done

    return 2
}

get_current_ms_data() {

    local -A namespace_map
    local -a target_namespace
    local templine

    while IFS=',' read -r namespace _
    do
        namespace_map[${namespace}]=1
    done < <(grep -v '^#' "${LISTFILE}" | grep -v '^\s*$' | tail -n +2)

    for ns in "${!namespace_map[@]}"
    do
        target_namespace+=("${ns}")
    done

    for ns in "${target_namespace[@]}"
    do
        local -a get_data_cmd=(
            "kubectl -n ${ns} get deployment,statefulset,daemonset --no-headers"
            "-o=custom-columns='NS:metadata.namespace,KIND:kind,NAME:metadata.name'"
            ">> "${TEMPFILE}" ; if [ ! -s "${TEMPFILE}" ]; then exit 1 ; fi"
        )

        if ! retry_command 1 "su - ${EXE_KUBE_ID} -c \"${get_data_cmd[*]}\""; then
            rm -rf "${TEMPFILE}"
            exit_process "${RC_ERROR}" "[E] Namespaceが存在しない or クラスタへアクセスできませんでした。"
        fi

        while IFS= read -r line; do
        templine=$(echo "${line,,}" | awk 'BEGIN {OFS=","} {$1=$1;print}')
            CURRENT_MS_DATA+=("${templine}")
        done < "${TEMPFILE}"
    done

    rm -rf "${TEMPFILE}"

    return 0
}

get_target_ms_data() {
    while IFS=',' read -r namespace kind name replicas startstop restart status_check; do
        if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "stop" ] && ! ${restart}; then
            if [ "${KIND}" == "all" ] || [ "${kind}" == "${KIND}" ]; then
                if [ "${kind}" == "deployment" ] || [ "${kind}" == "statefulset" ]; then
                    TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${startstop},${restart},${status_check}")
                fi
            fi
        elif [ "${ACTION}" == "restart" ] && ${restart}; then
            if [ "${KIND}" == "all" ] || [ "${kind}" == "${KIND}" ]; then
                if [ "${kind}" == "deployment" ] || [ "${kind}" == "statefulset" ]; then
                    TARGET_MS_DATA+=("${namespace},${kind},${name},${replicas},${startstop},${restart},${status_check}")
                fi
            fi
        fi
    done < <(grep -v '^#' "${LISTFILE}" | grep -v '^\s*$' | tail -n +2)

    if [[ -z "${TARGET_MS_DATA[*]}" ]]; then
        exit_process "${RC_ERROR}" "[E] 作業対象MSがないため、作業を中止します。"
    fi

    return 0
}

check_ms_exists() {

    while IFS=',' read -r namespace kind name replicas startstop restart status_check
    do
        local data_from_file="${namespace},${kind},${name}"
        local resource_found=0
        local -a resource_checked

        for data_from_k8s in "${CURRENT_MS_DATA[@]}"
        do
            if [[ "${data_from_k8s}" == *"${data_from_file}"* ]]; then
                resource_found=1
                resource_checked+=("${data_from_file}")
                break
            fi
        done

        if [ "${resource_found}" -eq 0 ]; then
            F_write_log_local "[E] [${namespace}/${name}]: 存在確認に失敗しました。" 1
            RC="${RC_ERROR}"
        fi

    done < <(grep -v '^#' "${LISTFILE}" | grep -v '^\s*$' | tail -n +2)

    if [[ -z "${resource_checked[*]}" ]]; then
        exit_process "${RC_ERROR}" "[E] 存在確認がすべて失敗したため、作業を中止します。"
    fi

    return 0
}

start_ms() {

    while IFS=',' read -r namespace kind name replicas startstop restart status_check
    do
        local scale_cmd="kubectl -n ${namespace} scale ${kind} ${name} --replicas=${replicas}"

        if ! retry_command 1 "su - ${EXE_KUBE_ID} -c \"${scale_cmd}\""; then
            F_write_log_local "[E] [${namespace}/${name}]: MSの起動処理に失敗しました。" 1
            RC="${RC_ERROR}"

            for i in "${!TARGET_MS_DATA[@]}"
            do
                if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                    unset "TARGET_MS_DATA[i]"
                fi
            done
        else
            F_write_log_local "[I] [${namespace}/${name}]: MSの起動処理を実施しました。" 1
            sleep "${START_INTERVAL}"
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    return 0
}

stop_ms() {

    while IFS=',' read -r namespace kind name replicas startstop restart status_check
    do
        local scale_cmd="kubectl -n ${namespace} scale ${kind} ${name} --replicas=0"
        local delete_pod_cmd="kubectl -n ${namespace} delete pod -l name=${name} --wait=false"
        local get_result_message_cmd="result_message=\$(su - ${EXE_KUBE_ID} -c \"${delete_pod_cmd}\" 2>&1)"

        if ! retry_command 1 "su - ${EXE_KUBE_ID} -c \"${scale_cmd}\""; then
            F_write_log_local "[E] [${namespace}/${name}]: MSの停止処理に失敗しました。" 1
            RC="${RC_ERROR}"

            for i in "${!TARGET_MS_DATA[@]}"
            do
                if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                    unset "TARGET_MS_DATA[i]"
                fi
            done
        elif [ "${kind}" == "statefulset" ]; then
            if ! retry_command 3 "${get_result_message_cmd}"; then
                F_write_log_local "[E] [${namespace}/${name}]: Podの削除処理に失敗しました。" 1
                RC="${RC_ERROR}"

                for i in "${!TARGET_MS_DATA[@]}"
                do
                    if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                        unset "TARGET_MS_DATA[i]"
                    fi
                done
            else
                F_write_log_local "[I] [${namespace}/${name}]: MSの停止処理を実施しました。" 1
                sleep "${STOP_RESTART_INTERVAL}"
            fi
        else
            F_write_log_local "[I] [${namespace}/${name}]: MSの停止処理を実施しました。" 1
            sleep "${STOP_RESTART_INTERVAL}"
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    return 0
}

restart_ms() {

    while IFS=',' read -r namespace kind name replicas startstop restart status_check
    do
        local restart_cmd="kubectl -n ${namespace} rollout restart ${kind} ${name}"
        local delete_pod_cmd="kubectl -n ${namespace} delete pod -l name=${name} --wait=false"
        local get_result_message_cmd="result_message=\$(su - ${EXE_KUBE_ID} -c \"${delete_pod_cmd}\" 2>&1)"

        if [ "${kind}" == "statefulset" ]; then
            if ! retry_command 3 "${get_result_message_cmd}"; then
                F_write_log_local "[E] [${namespace}/${name}]: MSの再起動処理に失敗しました。" 1
                RC="${RC_ERROR}"

                for i in "${!TARGET_MS_DATA[@]}"
                do
                    if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                        unset "TARGET_MS_DATA[i]"
                    fi
                done
            else
                F_write_log_local "[I] [${namespace}/${name}]: MSの再起動処理を実施しました。" 1
                sleep "${STOP_RESTART_INTERVAL}"
            fi
        else
            if ! retry_command 1 "su - ${EXE_KUBE_ID} -c \"${restart_cmd}\""; then
                F_write_log_local "[E] [${namespace}/${name}]: MSの再起動処理に失敗しました。" 1
                RC="${RC_ERROR}"
                for i in "${!TARGET_MS_DATA[@]}"
                do
                    if [[ "${TARGET_MS_DATA[i]}" == *${name}* ]]; then
                        unset "TARGET_MS_DATA[i]"
                    fi
                done
            else
                F_write_log_local "[I] [${namespace}/${name}]: MSの再起動処理を実施しました。" 1
                sleep "${STOP_RESTART_INTERVAL}"
            fi
        fi
    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    return 0
}

check_status() {

    set_common_profile

    SHELL_NAME=${SHELL_NAME_TMP}
    LOCAL_LOG_FILE=${LOCAL_LOG_FILE_TMP}
    INIT_FLG=${INIT_FLG_TMP}

    RC=0

    . ${SHELL_DEF_DIR}/dstcn_var_kubectl.prf

    if [ -z "${TARGET_MS_DATA_TMP[*]}" ]; then
        F_write_log_local "[E] 対象がないため、ステータス確認をスキップします。" 1
        RC="${RC_ERROR}"
        exit 0
    fi

    for ms_data in "${TARGET_MS_DATA_TMP[@]}"
    do
        TARGET_MS_DATA+=("${ms_data}")
    done

    F_write_log_local "[I] MSのステータス確認を実施します。" 1

    while IFS=',' read -r namespace kind name replicas startstop restart status_check
    do
        is_timeout=false

        if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "restart" ]; then
            get_status_cmd="kubectl -n ${namespace} rollout status ${kind} ${name} --timeout ${STATUS_CHECK_TIMEOUT}s"
        elif [ "${ACTION}" == "stop" ]; then
            for l in "name" "app"
            do
                get_label_cmd="kubectl -n ${namespace} get ${kind} ${name} -o jsonpath='{.metadata.labels.${l}}'"
                check_label_cmd="check_label_exists=\$(su - ${EXE_KUBE_ID} -c \"${get_label_cmd}\" 2>&1)"

                if ! retry_command 1 "${check_label_cmd}"; then
                    F_write_log_local "[E] [${namespace}/${name}]: ラベル取得に失敗しました。" 1
                fi

                if [ "${check_label_exists}" == "${name}" ]; then
                    label="${l}"
                    break
                else
                    label="/error"
                fi
            done

            get_status_cmd="kubectl -n ${namespace} wait pod --for=delete --timeout ${STATUS_CHECK_TIMEOUT}s -l ${label}=${name}"
        fi

        check_status_cmd="result_message=\$(su - ${EXE_KUBE_ID} -c \"${get_status_cmd}\" 2>&1)"

        if [ "${ACTION}" == "start" ] && ! "${status_check}"; then
            F_write_log_local "[I] [${namespace}/${name}]: ステータス確認をスキップします。" 1
        else
            if ! retry_command 2 "${check_status_cmd}"; then
                if "${is_timeout}"; then
                    F_write_log_local "[E] [${namespace}/${name}]: TIMEOUTによりステータス確認に失敗しました。" 1
                    RC="${RC_ERROR}"
                else
                    F_write_log_local "[E] [${namespace}/${name}]: ステータス確認に失敗しました。" 1
                    RC="${RC_ERROR}"
                fi
            else
                F_write_log_local "[I] [${namespace}/${name}]: ステータス確認が完了しました。 " 1
            fi
        fi

    done < <(printf "%s\n" "${TARGET_MS_DATA[@]}")

    if [ ${RC} -eq 0 ]; then
        return 0
    else
        return ${RC}
    fi
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

set_common_profile

F_sta_shell

check_args "${@}"

check_csv "${SHELL_DEF_DIR}/${4}"

export ACTION="${1}"

export AZ="${2}"

KIND="${3}"

LISTFILE="${SHELL_DEF_DIR}/${4}"

TEMPFILE="${SHELL_TMP_DIR}/${SHELL_NAME}.$$.mslist.tmp"

. ${SHELL_DEF_DIR}/dstcn_env_kubectl.prf

F_write_log_local "[I] メイン処理を開始します。" 1

get_current_ms_data

check_ms_exists

get_target_ms_data

if [ "${ACTION}" == "stop" ]; then
    F_write_log_local "[I] MSの停止処理を開始します。" 1
    type stop_ms &>/dev/null && stop_ms || exit_process "${RC_ERROR}" "[E] 該当関数が見つかりませんでした。"
elif [ "${ACTION}" == "start" ]; then
    F_write_log_local "[I] MSの起動処理を開始します。" 1
    type start_ms &>/dev/null && start_ms || exit_process "${RC_ERROR}" "[E] 該当関数が見つかりませんでした。"
elif [ "${ACTION}" == "restart" ]; then
    F_write_log_local "[I] MSの再起動処理を開始します。" 1
    type restart_ms &>/dev/null && restart_ms || exit_process "${RC_ERROR}" "[E] 該当関数が見つかりませんでした。"
fi

export -f set_common_profile retry_command check_status exit_process

export TARGET_MS_DATA_TMP="${TARGET_MS_DATA[*]}"
export SHELL_NAME_TMP="${SHELL_NAME}" LOCAL_LOG_FILE_TMP="${LOCAL_LOG_FILE}" INIT_FLG_TMP="${INIT_FLG}"

timeout "${SCRIPT_TIMEOUT}" bash -c check_status

timeout_rc=$?

if [ "${timeout_rc}" -ne 0 ]; then
    if [ "${timeout_rc}" -eq 124 ]; then
        exit_process "${RC_ERROR}" "[E] TIMEOUTによりスクリプトを強制終了します。"
    else
        RC="${RC_ERROR}"
    fi
fi

exit_process "${RC}"

~~~
