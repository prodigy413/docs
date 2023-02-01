~~~
    from_time = datetime.datetime(year=yesterday.year, month=yesterday.month, day=yesterday.day, hour=0, minute=0,second=0)
    # 出力日時（to）取得（例：2023-01-29 23:59:59.999999）
    print(from_time)
    to_time = datetime.datetime(year=yesterday.year, month=yesterday.month, day=yesterday.day, hour=23, minute=59,second=59,microsecond=999999)
    print(to_time)
~~~
