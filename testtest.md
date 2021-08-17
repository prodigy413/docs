#!/bin/bash

start=`date "+%H:%M:%S"`

function tasktime() {
  end=`date "+%H:%M:%S"`
  echo "Task started at ${start}"
  echo "Task completed at ${end}"
}

if [ "$1" = "main" ]; then
  echo -n "This is production environment. Continue？ [y/n]: "
  read answer
  if [[ ${answer,,} = y ]]; then
    echo "Good!!"

  tasktime
  else
    echo "Task stopped"
    exit 1
  fi
elif [ "$1" = "dev" ]; then
  echo "This is dev"

  tasktime
else
  echo "Bad"
fi
