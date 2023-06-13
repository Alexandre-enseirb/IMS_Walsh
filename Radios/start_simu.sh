#! /bin/bash

bash start_tx.sh &
bash start_rx.sh &

watch rx_logs.txt
