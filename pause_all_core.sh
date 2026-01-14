#! /bin/bash

# 1. コア数の計算
TOTAL_CORES=$(nproc)
HALF_CORES=$((TOTAL_CORES / 2))
PIDS=()

# 2. 停止処理
cleanup() {
	echo "spinloop count:"
    for pid in "${PIDS[@]}"; do
        # プロセスが存在している場合のみSIGINTを送信
        if kill -0 "$pid" 2>/dev/null; then
            kill -INT "$pid"
        fi
    done
    wait
	echo "--------------------------------"
    echo "All processes stopped."
	echo "--------------------------------"
	sleep 1
}

exec_test() {
    # この関数の引数でコマンドを1つ受け取る
    CMD1="$1"
    # 実行権限チェック (CMD1)
    if [ ! -x "$CMD1" ]; then
        echo "Error: $CMD1 に実行権限がありません。"
        exit 1
    fi

    # sysbench の実行パス確認
    if [ ! -x "_bin/bin/sysbench" ]; then
        echo "Error: sysbench の実行パスが見つかりません。"
        exit 1
    fi

	echo "--------------------------------"
	echo "Total cores: $TOTAL_CORES"
	echo "Cores 0 to $((HALF_CORES - 1)): $CMD1"
	echo "Cores $HALF_CORES to $((TOTAL_CORES - 1)): _bin/bin/sysbench"
	echo "--------------------------------"


    # 3. 前半のコアでCMD1を実行
    for (( i=0; i<HALF_CORES; i++ )); do
        taskset -c $i $CMD1 &
        PIDS+=($!)
    done

    # 4. 後半のコアでCMD2を実行
    SYSBENCH_PIDS=()
	echo "sysbench total number of events:"
    for (( i=HALF_CORES; i<TOTAL_CORES; i++ )); do
        taskset -c $i _bin/bin/sysbench cpu run --threads=1 --time=10 | grep "total number of events" | awk '{print $5}' &
        pid=$!
        PIDS+=($pid)
        SYSBENCH_PIDS+=($pid)
    done
    # sysbenchの実行が終わるまで待機
    wait "${SYSBENCH_PIDS[@]}"
    cleanup
}

# Ctrl+C でも止まるようにtrapを設定
trap cleanup SIGINT

exec_test "./spin_pause"
exec_test "./spin_busy"
