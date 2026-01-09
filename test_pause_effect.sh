#!/bin/bash

# 実行時間の指定
DURATION=10

# 1. コア数の計算
TOTAL_CORES=$(nproc)
HALF_CORES=$((TOTAL_CORES / 2))
PIDS=()

# CPUモデル名を取得（ディレクトリ名に使用）
CPU_MODEL=$(lscpu | grep "Model name" | awk '{sub(/^[^ ]+ +[^ ]+ +/, ""); print}' | tr ' ' '_')

# タイムスタンプを取得（全実行で共通）
TIMESTAMP=$(date +%m%d_%H%M)

# ベースディレクトリ: result/<CPUモデル名>/<timestamp>/
BASE_DIR="result/${CPU_MODEL}/${TIMESTAMP}"
mkdir -p "$BASE_DIR"
uname -a > "$BASE_DIR/env.txt"
lscpu >> "$BASE_DIR/env.txt"

# 2. 停止処理 (Ctrl+C および タイムアウト用)
cleanup() {
    echo ""
    echo "Stopping all processes..."
    for pid in "${PIDS[@]}"; do
        # プロセスが存在している場合のみkillを実行
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
        fi
    done
    wait
    echo "All processes stopped."
	sleep 1
}

exec_test() {
    # この関数の引数でコマンドを1つ受け取る
    CMD1="$1"
    PCM_POWER_DIR="$2"

	if [ -z "$PCM_POWER_DIR" ]; then
        echo "Usage: exec_test <cmd_for_first_half> <pcm_power_dir>"
        exit 1
    fi

    # 実行権限チェック (CMD1)
    if [ ! -x "$CMD1" ]; then
        echo "Error: $CMD1 に実行権限がありません。"
        exit 1
    fi

	# 実行権限チェック (PCM_POWER_DIR)
	if [ ! -x "$PCM_POWER_DIR/build/bin/pcm-power" ]; then
        echo "Error: $PCM_POWER_DIR/build/bin/pcm-power に実行権限がありません。"
        exit 1
    fi

    # sysbench の実行パス確認
    if [ ! -x "_bin/bin/sysbench" ]; then
        echo "Error: sysbench の実行パスが見つかりません。"
        exit 1
    fi

	echo "Total cores: $TOTAL_CORES"
	echo "Cores 0 to $((HALF_CORES - 1)): $CMD1"
	echo "Cores $HALF_CORES to $((TOTAL_CORES - 1)): _bin/bin/sysbench"
	echo "---"

    # INSERT_YOUR_CODE
    # 消費電力の測定をpcm-powerで実施し、ファイルに出力
    # コマンド名のディレクトリ: result/<CPUモデル名>/<timestamp>/<コマンド名>/
    CMD_DIR="$BASE_DIR/$(basename "$CMD1")"
    mkdir -p "$CMD_DIR"
    PCM_POWER_OUT="$CMD_DIR/pcm_power_output.txt"

    # 3. 前半のコアでCMD1を実行
    for (( i=0; i<HALF_CORES; i++ )); do
        taskset -c $i $CMD1 &
        PIDS+=($!)
        echo "Started command 1 on core $i (PID: $!)"
    done

    # 4. 後半のコアでCMD2を実行（sysbenchの結果もファイルに出力）
	SYSBENCH_OUT="$CMD_DIR/sysbench_output.txt"
    : > "$SYSBENCH_OUT"   # 既存ファイルがあれば空にしておく

    for (( i=HALF_CORES; i<TOTAL_CORES; i++ )); do
        taskset -c $i _bin/bin/sysbench cpu --threads=1 --time="$DURATION" run >> "$SYSBENCH_OUT" 2>&1 &
        PIDS+=($!)
        echo "Started command 2 on core $i (PID: $!, Output: $SYSBENCH_OUT)"
    done

    echo "---"
    echo "Mixed workload running for 10 seconds..."
    "$2"/build/bin/pcm-power 1 > "$PCM_POWER_OUT" 2>&1 &
    PCM_POWER_PID=$!
    echo "Started pcm-power measurement (PID: $PCM_POWER_PID, Output: $PCM_POWER_OUT)"
    # 10秒間待機
    sleep 10

    # 時間が来たらpcm-powerも停止し、終了処理を呼び出す
    echo "Time limit reached."
    if ps -p $PCM_POWER_PID > /dev/null 2>&1; then
        kill $PCM_POWER_PID
        echo "Stopped pcm-power measurement (PID: $PCM_POWER_PID)"
    fi
	
	# sysbench の結果から events per second: を抜き出してサマリーファイルを作成
    SUMMARY_OUT="$CMD_DIR/sysbench_events_per_second.txt"
    grep "events per second:" "$SYSBENCH_OUT" > "$SUMMARY_OUT"
    echo "Saved events per second summary to $SUMMARY_OUT"

    cleanup
}

# Ctrl+C でも止まるようにtrapを設定
trap cleanup SIGINT

exec_test "./spin_pause" "/home/morisaki/Application/pcm"
exec_test "./spin_busy" "/home/morisaki/Application/pcm"