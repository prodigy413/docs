~~~
#!/bin/bash

test_function() {
    sleep 40
}

test_function &
f_pid=$!
echo ${f_pid}

timeout=30
start=$(date +%s)


while kill -0 ${f_pid} 2>/dev/null
do
    sleep 1
    current=$(date +%s)

    elapsed_time=$((current - start))
    echo ${elapsed_time}

    if [ ${elapsed_time} -ge ${timeout} ]; then
        echo "TIMEOUT!!"
        kill ${f_pid}
        break
    fi
done

wait ${f_pid}
echo $?





~~~mermaid
%%{init: {'theme':'forest'}}%%
flowchart TD
    A[Start Process] --> B[Apply Common Vars]
    B --> C[Check Args]
    C -- Failed --> D[End Process Forcibly]
    C -- No Problem --> E[Get k8s MS Data]
    E -- Failed --> F[End Process Forcibly]
    E -- Success --> G[Check MS Exists on k8s Cluster]
    G -- All MS Not Exist --> H[End Process Forcibly]
    G -- Some MS Not Exist --> I[Notify Warning Msg and Start MS Actions]
    G -- All MS Exist --> J[Start MS Actions]
    I --> K[Start MS Actions]
    J --> K
    K --> L{Action Arg}
    L -- Start --> M[Start Action]
    L -- Stop --> N[Stop Action]
    L -- Restart --> O[Restart Action]
~~~




~~~mermaid
flowchart TD
    A[Start Process] --> B[Run Test Command]
    B --> C{Command Succeeds?}
    C -- Yes --> D[Terminate Process]
    C -- No --> E{Attempt Count < 3?}
    E -- Yes --> B
    E -- No --> F[Send Error Message to Slack]
~~~
~~~
