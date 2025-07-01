#!/usr/bin/python

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: kaia_topology
short_description: This module generates Kaia network topology
'''

import json
import os.path
from urllib.parse import urlparse, parse_qsl, urlencode, urlunparse

from ansible.module_utils.basic import AnsibleModule


def node_name(node_type, node_index):
    return '{}-{}'.format(node_type, (node_index + 1))


def split_node_name(node_name):
    node_type, node_num = node_name.split('-')
    return node_type, int(node_num)


class ModuleRunner(object):

    def __init__(self, module):
        self.module = module
        self.result = dict(
            changed=False,
            topology={},
        )

        self.num_cn = module.params['num_cn']
        self.num_pn = module.params['num_pn']
        self.num_en = module.params['num_en']
        self.use_default = module.params['use_default']
        self.custom_topology = module.params['custom_topology']

        self.validate_params()


    def validate_params(self):
        result = self.result

        if not self.use_default and not self.custom_topology:
            self.module.fail_json(msg='custom_topology is mandatory if use_default == False', **result)


    def default_topology(self):
        topology = {}

        # Handle case where num_cn is 0
        if self.num_cn == 0:
            pn_per_cn = 0
        else:
            pn_per_cn = self.num_pn / self.num_cn
        
        pn_per_en = 2

        # full mesh for CNs
        cn_list = [node_name('cn', i) for i in range(self.num_cn)]

        for i in range(self.num_cn):
            cn_name = node_name('cn', i)
            topology[cn_name] = cn_list

        # pn_per_cn
        for i in range(self.num_pn):
            pn_name = node_name('pn', i)
            if self.num_cn > 0:
                cn_index = int(i / pn_per_cn)
                topology[pn_name] = []
                topology[pn_name].append(node_name('cn', cn_index))
            else:
                topology[pn_name] = []

        # pn_per_pn
        for i in range(self.num_pn):
            pn_name = node_name('pn', i)

            if (i % 2) == 0:
                pn_index = int(i + self.num_pn - 1) % self.num_pn
            else:
                pn_index = int(i + 1) % self.num_pn

            topology[pn_name].append(node_name('pn', pn_index))

        # pn_per_en
        for i in range(self.num_en):
            en_name = node_name('en', i)

            topology[en_name] = []
            if self.num_pn > 0 and pn_per_en > 0:
                pn_index = i
                for _ in range(pn_per_en):
                    pn_index = (pn_index + int(self.num_pn / pn_per_en)) % self.num_pn
                    topology[en_name].append(node_name('pn', pn_index))

        return topology


    def read_file(self, path):
        with open(path, 'r') as f:
            content = f.read()

        return content


    def run(self):
        result = self.result

        if self.use_default:
            topology = self.default_topology()
        else:
            topology = self.custom_topology

        result['topology'] = topology

        return result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            num_cn=dict(type='int', required=True),
            num_pn=dict(type='int', required=True),
            num_en=dict(type='int', required=True),
            use_default=dict(type='bool', default=True),
            custom_topology=dict(type='dict'),
        ),
        supports_check_mode=False
    )

    runner = ModuleRunner(module)
    result = runner.run()

    module.exit_json(**result)


if __name__ == '__main__':
    main()

