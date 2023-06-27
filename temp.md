~~~
log_100_1000_file.py
import logging
from multiprocessing import Pool

logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s',filename='/tmp/100_10000.log',filemode='w')

def test_log(x):
    logging.debug(f"Debug message_{x}")
    logging.info(f"Informative message_{x}")
    logging.error(f"Error message_{x}")

if __name__ == '__main__':
    with Pool(100) as p:
        p.map(test_log, range(1000))




log_100_1000_stdout.py
import logging
from multiprocessing import Pool

logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s')

def test_log(x):
    logging.debug(f"Debug message_{x}")
    logging.info(f"Informative message_{x}")
    logging.error(f"Error message_{x}")

if __name__ == '__main__':
    with Pool(100) as p:
        p.map(test_log, range(1000))




log_1000_10000_file.py
import logging
from multiprocessing import Pool

logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s',filename='/tmp/1000_10000.log',filemode='w')

def test_log(x):
    logging.debug(f"Debug message_{x}")
    logging.info(f"Informative message_{x}")
    logging.error(f"Error message_{x}")

if __name__ == '__main__':
    with Pool(1000) as p:
        p.map(test_log, range(10000))




log_1000_10000_stdout.py
import logging
from multiprocessing import Pool

logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s')

def test_log(x):
    logging.debug(f"Debug message_{x}")
    logging.info(f"Informative message_{x}")
    logging.error(f"Error message_{x}")

if __name__ == '__main__':
    with Pool(1000) as p:
        p.map(test_log, range(10000))



apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-logging
  labels:
    app: python-logging
spec:
  selector:
    matchLabels:
      app: python-logging
  replicas: 9
  template:
    metadata:
      labels:
        app: python-logging
    spec:
      containers:
      - name: python-logging
        image: prodigy413/test-python:1.0
        imagePullPolicy: Always
        env:
        - name: TZ
          value: "Asia/Tokyo"
        command: ["/bin/bash",  "-c", "while true ; do python3 /tmp/log_1000_10000_stdout.py |& tee /proc/1/fd/1 ; done"]





2023-06-27 07:58:19 +0000 [warn]: #0 [in_tail_container_logs] Skip update_watcher because watcher has been already updated by other inotify event path="/var/log/containers/python-logging-5c78c5bc74-p6rr2_default_python-logging-f754b58bdc72621fd81947c095603e6e4779b46140120675df346c00d7828ab7.log" inode=2386571 inode_in_pos_file=2386710



~~~
