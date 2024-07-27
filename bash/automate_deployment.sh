#!/bin/bash
servers=("server1" "server2" "server3")
for server in "${servers[@]}"; do
    scp "app.tar.gz" "user@$server:/path/to/destination/"
    ssh "user@$server" "tar -xzvf /path/to/destination/app.tar.gz -C /path/to/app"
    # Additional deployment steps here
done