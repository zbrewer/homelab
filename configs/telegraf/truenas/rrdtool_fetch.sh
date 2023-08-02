#!/bin/bash

# influx measurement name. I used "net" so stats show up in the same place as other Telegraf-collected data. 
measurementName="net"
# host tag for influx measurement. Set to your hostname. 
host="truenas"

# Host path in Telegraf Docker container to localhost rrd directory
# This is /var/db/collectd/rrd (follow symlink to real location) on the TrueNAS host
# Browse to /host/var/db/system, dig into the rrd-*** folder, then localhost, then look for interfaces. 
path="/hostfs/rrd"

# Array of interfaces 
# example for multiples: interfaces=("interface-enp4s0" "interface-enp7s0")
interfaces=("interface-enp4s0")

# Iterate over the interfaces array
for interface in "${interfaces[@]}"
do
  # Run rrdtool fetch and store the multiline result in a variable. 300 seconds seems to be enough to get frequent updates. 
  output=$(rrdtool fetch "$path"/"$interface"/if_octets.rrd LAST -s -300s)
  
  echo "${output}" | while IFS= read -r line; do
    # Check if the line is valid (contains numeric values)
    if [[ $line =~ [0-9.e+-]+[[:space:]]+[0-9.e+-]+ ]]; then
	
  # Extract timestamp and values from each line 
  grab_time=$(echo "$line" | awk -F':' '{print $1}' )
  rx_val=$(echo "$line" | awk -F' ' '{print $2}' )
  tx_val=$(echo "$line" | awk -F' ' '{print $3}')
  
  # add a bunch of zeros to get timestamps in influxdb precision. 
  influx_precision="000000000"
  timestamp="${grab_time}${influx_precision}"
  
  # Print Influx Line Protocol format
  # https://docs.influxdata.com/influxdb/cloud/reference/syntax/line-protocol/
  # measurement,tag1=val1,tag2=val2 field1="v1",field2=1i 0000000000000000000  
  # possibly want to use bytes_recv and bytes_sent as influx fields for consistentcy
  echo "$measurementName,interface=$interface,host=$host rx=${rx_val},tx=${tx_val} $timestamp"
fi
done 
done
