# iperf3_bandwidth_exporter
Using iperf3 for bandwidth monitoring and creating Prometheus textfile exporter.

The solution is based on
* sh - Bourne Shell - default shell in FreeBSD
* jq - Command-line JSON processor
* bc - arbitrary-precision decimal arithmetic language and calculator - default software in FreeBSD
* iperf3 - perform network throughput tests

## Instalation on FreeBSD
Install required FreeBSD packages

```code
pkg install iperf3 jq
```

Copy bandwidth monitoring script to production location 

```code
cp ./iperf3_bandwidth_exporter.sh /usr/local/bin/iperf3_bandwidth_exporter.sh
```

Verify script works as expected

```code
/usr/local/bin/iperf3_bandwidth_exporter.sh
cat /var/db/node_exporter/iperf3/iperf3.prom
```

Setup cron entry

```code
cat <<EOF > /etc/cron.d/iperf3_bandwidth_exporter
*/10 * * * * root /usr/local/bin/iperf3_bandwidth_exporter.sh
EOF

chmod 644 /etc/cron.d/iperf3_bandwidth_exporter
```

Verify cron en try exists

```code
crontab -l
```

