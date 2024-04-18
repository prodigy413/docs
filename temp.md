~~~python
from logging import basicConfig, getLogger, INFO, WARN


def set_logging(name: str, level: str = 'info'):

    date_format = '%Y-%m-%d %H:%M:%S'
    formatter = '%(asctime)s.%(msecs)03d %(levelname)s %(message)s'
    basicConfig(filename='/proc/1/fd/1', format=formatter, datefmt=date_format, level=INFO)

    logger = getLogger(name)
    if level == 'info':
        logger.setLevel(INFO)
    elif level == 'warn':
        logger.setLevel(WARN)
    else:
        raise Exception('Only INFO or WARN is available')

    return logger
~~~
