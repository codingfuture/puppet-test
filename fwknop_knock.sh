#!/bin/bash

IP=${IP:-$(ip route get 128.0.0.1 | awk 'NR==1 {print $NF}')}

echo fwknop --rc-file $(dirname $0)/.fwknoprc -a $IP -n router "$@"
fwknop --rc-file $(dirname $0)/.fwknoprc -a $IP -n router "$@"