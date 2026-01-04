#!/bin/sh

# =========================
# Configuration
# =========================

SERVERS="iperf3.example.com"
OUTDIR="/var/db/node_exporter"
OUTFILE="$OUTDIR/iperf3.prom"
TMPFILE="$OUTDIR/iperf3.prom.$$"
IPERF_BIN="/usr/local/bin/iperf3"
TIMEOUT=30

# =========================
# Preparation
# =========================

mkdir -p "$OUTDIR" || exit 1

echo "# iperf3 bandwidth exporter" > "$TMPFILE"
echo "# generated at $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$TMPFILE"

# =========================
# Helper function
# =========================

run_iperf() {
    MODE="$1"   # upload | download
    SERVER="$2"

    if [ "$MODE" = "download" ]; then
        EXTRA="-R"
    else
        EXTRA=""
    fi

    OUTPUT=$(timeout "$TIMEOUT" "$IPERF_BIN" -c "$SERVER" $EXTRA -J 2>/dev/null)
    RET=$?

    if [ $RET -ne 0 ] || [ -z "$OUTPUT" ]; then
        echo "ERROR"
        return
    fi

    BW=$(echo "$OUTPUT" | jq '.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second' 2>/dev/null)
    RETR=$(echo "$OUTPUT" | jq '.end.sum_sent.retransmits // 0' 2>/dev/null)

    if [ -z "$BW" ] || [ "$BW" = "null" ]; then
        echo "ERROR"
        return
    fi

    MBPS=$(echo "$BW / 1000000" | bc -l)

    echo "$MBPS $RETR"
}

# =========================
# Metrics
# =========================

for SERVER in $SERVERS; do
    UP_STATUS=1
    DOWN_STATUS=1

    UP_RESULT=$(run_iperf upload "$SERVER")
    if [ "$UP_RESULT" = "ERROR" ]; then
        UP_STATUS=0
    else
        UP_MBPS=$(echo "$UP_RESULT" | awk '{print $1}')
        UP_RETR=$(echo "$UP_RESULT" | awk '{print $2}')
    fi

    DOWN_RESULT=$(run_iperf download "$SERVER")
    if [ "$DOWN_RESULT" = "ERROR" ]; then
        DOWN_STATUS=0
    else
        DOWN_MBPS=$(echo "$DOWN_RESULT" | awk '{print $1}')
        DOWN_RETR=$(echo "$DOWN_RESULT" | awk '{print $2}')
    fi

    UP=$((UP_STATUS & DOWN_STATUS))

    cat <<EOF >> "$TMPFILE"
# HELP iperf_upload_mbps iperf3 upload throughput
# TYPE iperf_upload_mbps gauge
iperf_upload_mbps{server="$SERVER"} ${UP_MBPS:-0}

# HELP iperf_download_mbps iperf3 download throughput
# TYPE iperf_download_mbps gauge
iperf_download_mbps{server="$SERVER"} ${DOWN_MBPS:-0}

# HELP iperf_retransmits_upload iperf3 TCP retransmits (upload)
# TYPE iperf_retransmits_upload gauge
iperf_retransmits_upload{server="$SERVER"} ${UP_RETR:-0}

# HELP iperf_retransmits_download iperf3 TCP retransmits (download)
# TYPE iperf_retransmits_download gauge
iperf_retransmits_download{server="$SERVER"} ${DOWN_RETR:-0}

# HELP iperf_up iperf3 measurement success (1=ok, 0=error)
# TYPE iperf_up gauge
iperf_up{server="$SERVER"} $UP
EOF

done

# =========================
# Atomic replace
# =========================

mv "$TMPFILE" "$OUTFILE"
