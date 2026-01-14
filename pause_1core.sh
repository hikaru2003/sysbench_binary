#! /bin/bash

if [ $# -ne 3 ];then
	echo "./pause.sh [CPU 1] [CPU 2] [CPU 3]"
	exit 1
fi

function test_ () {
        echo "sysbench with ${3} (core placement: ${1}, ${2})"
        taskset -c $1 _bin/bin/sysbench cpu run --threads=1 --time=10 | grep "total number of events" &
        wait_pid=$!
        taskset -c $2 $3 &
        kill_pid=$!
        wait $wait_pid
        kill -SIGINT $kill_pid

}

test_ $1 $1 ./spin_pause
test_ $1 $2 ./spin_pause
test_ $1 $3 ./spin_pause
test_ $1 $1 ./spin_busy
test_ $1 $2 ./spin_busy
test_ $1 $3 ./spin_busy
