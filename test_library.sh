#!/bin/bash -ex

ANSIBLE_LIBRARY=./library ansible -vvv -m kaia_topology -a 'num_cn=1 num_pn=1 num_en=1' localhost
ANSIBLE_LIBRARY=./library ansible -vvv -m kaia_topology -a 'num_cn=4 num_pn=0 num_en=4' localhost  # kaia v3: ENs to CNs

TOPOLOGY='{"cn-1":["cn-1"],"en-1":["pn-1","pn-1"],"pn-1":["cn-1","pn-1"]}'
ANSIBLE_LIBRARY=./library ansible -vvv -m kaia_static_nodes -a "homi_output_dir=cache/homi-output topology=$TOPOLOGY" localhost

ANSIBLE_LIBRARY=./library ansible -vvv -m kaia_validator -a 'homi_output_dir=cache/homi-output node_type=pn node_index=0 public_ip=1.1.1.1 private_ip=10.0.0.0' localhost

ANSIBLE_LIBRARY=./library ansible -vvv -m kaia_main_bridges -a 'homi_output_dir=cache/homi-output node_type=en node_num=1' localhost
