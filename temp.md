~~~
  healthCheck:
    command:
      - "sh"
      - "-c"
      - "curl -f http://localhost || exit 1"
    interval: 30
    retries: 1
    startPeriod: 60
    timeout: 10
~~~
