# iperf3_bandwidth_exporter - Internet Bandwidth Monitoring Solution
The intention of this solution is to use iperf3 for Internet bandwidth monitoring and creating node_exporter file usable by Prometheus for longer data retention and visualization.

The monitoring script requires
* sh - Bourne Shell - default shell in FreeBSD
* iperf3 - perform network throughput tests
* jq - Command-line JSON processor
* bc - arbitrary-precision decimal arithmetic language and calculator - default software in FreeBSD

The monitoring script generates iperf3 metrics into file __*/var/db/node_exporter/iperf3/iperf3.prom*__

## iperf3 Monitoring Script

The script was developed and tested on FreeBSD

### Installation

In this section we cover the installation of iperf3_bandwidth_exporter script on FreeBSD.

```bash
pkg install iperf3 jq
```

### Make bandwidth monitoring script executable and copy it to production location 

```bash
chmod 755 ./iperf3_bandwidth_exporter.sh
cp ./iperf3_bandwidth_exporter.sh /usr/local/bin/iperf3_bandwidth_exporter.sh
```

### Verify script works as expected

```bash
/usr/local/bin/iperf3_bandwidth_exporter.sh
cat /var/db/node_exporter/iperf3.prom
```

### Setup cron entry

```bash
cat <<EOF > /etc/cron.d/iperf3_bandwidth_exporter
*/10 * * * * root /usr/local/bin/iperf3_bandwidth_exporter.sh
EOF

chmod 644 /etc/cron.d/iperf3_bandwidth_exporter
```

### Verify cron task is working

```bash
tail -f /var/log/cron
```
Wait at least 10 minutes and you should see something like ...

```text
Jan  4 19:20:00 freebsd01 /usr/sbin/cron[12141]: (root) CMD (/usr/local/bin/iperf3_bandwidth_exporter.sh)
```

## Using Node Exporter to expose iperf3 data

### Enable and start Node Exporter

```bash
sysrc node_exporter_enable="YES"
sysrc node_exporter_listen_address=":9100"
sysrc node_exporter_textfile_dir="/var/db/node_exporter"
service node_exporter start
```

## Using Prometheus to store monitoring data

### Prometheus installation

```bash
pkg install prometheus
```
### Configure and start Prometheus

```bash
sysrc prometheus_enable="YES"
sysrc prometheus_args="--storage.tsdb.retention.time=30d" # 30 days data retention
service prometheus start
```

Default Prometheus configuration at __*/usr/local/etc/prometheus.yml*__ should work out of the box.

