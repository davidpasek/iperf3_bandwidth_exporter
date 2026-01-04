# iperf3_bandwidth_exporter
The intention of this solution is to use iperf3 for bandwidth monitoring and creating Prometheus textfile exporter.

The monitoring script requires
* sh - Bourne Shell - default shell in FreeBSD
* iperf3 - perform network throughput tests
* jq - Command-line JSON processor
* bc - arbitrary-precision decimal arithmetic language and calculator - default software in FreeBSD

The monitoring script generates iperf3 metrics into file __*/var/db/node_exporter/iperf3/iperf3.prom*__

## Monitoring Script Instalation on FreeBSD

### Install required FreeBSD packages

In this section we cover the installation of script providing bandwidth monitoring.

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
cat /var/db/node_exporter/iperf3/iperf3.prom
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

### Enable and start Node Exporter

```bash
sysrc node_exporter_enable="YES"
service node_exporter start
```
