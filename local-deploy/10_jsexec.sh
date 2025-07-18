#!/bin/bash
binary=${1}${2}/bin/k${1}
url=${1}${2}/data/klay.ipc
js_command=$3
if [ "$4" = "ws" ]; then
  WS_PORT=$(sed -n 's/^WS_PORT=\([0-9]*\)$/\1/p' ${1}${2}/conf/k${1}d.conf)
  url=ws://localhost:$WS_PORT
elif [ "$4" = "rpc" ]; then
  RPC_PORT=$(sed -n 's/^RPC_PORT=\([0-9]*\)$/\1/p' ${1}${2}/conf/k${1}d.conf)
  url=http://localhost:$RPC_PORT
elif [ $# -eq 1 ]; then
  binary=cn1/bin/kcn
  url=cn1/data/klay.ipc
fi

$binary --exec $js_command attach $url