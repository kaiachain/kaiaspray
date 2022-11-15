#!/usr/bin/python

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: klay_update_validator
short_description: This module generates validator files
version_added: "1.0.0"
'''

import re
import json
import os.path
from urllib.parse import urlparse, parse_qsl, urlencode, urlunparse

from ansible.module_utils.basic import AnsibleModule


class ModuleRunner(object):

    def __init__(self, module):
        self.module = module
        self.result = dict(
            changed=False,
            validator={},
        )

        self.path = module.params['path']
        self.node_type = module.params['node_type']
        self.port = module.params['port']
        self.bridge_port = module.params['bridge_port']
        self.public_ip = module.params['public_ip']
        self.private_ip = module.params['private_ip']

        self.validate_params()


    def validate_params(self):
        result = self.result

        if not os.path.exists(self.path):
            self.module.fail_json(msg='{} is missing'.format(self.path), **result)


    def read_file(self, path):
        with open(path, 'r') as f:
            content = f.read()

        return content


    def read_validator(self):
        data = json.loads(self.read_file(self.path))

        return data

    # This function extract ntype value
    # Example: cn > cn, scn > cn, spn > pn, sen > en
    def extract_node_type(self, node_type):
        return re.sub('^s', '', node_type)


    def get_node_info(self, node_info, ip, port):
        parts = urlparse(node_info)

        qs = dict(parse_qsl(parts.query))
        qs['ntype'] = self.extract_node_type(self.node_type)

        netloc = parts.netloc
        netloc = '{}@{}:{}'.format(netloc.split('@')[0], ip, port)

        parts = parts._replace(netloc=netloc, query=urlencode(qs))

        return urlunparse(parts)


    def run(self):
        result = self.result

        data = self.read_validator()

        data['NodeInfo'] = self.get_node_info(data['NodeInfo'], self.public_ip, self.port)
        data['PrivateNodeInfo'] = self.get_node_info(data['NodeInfo'], self.private_ip, self.port)
        data['BridgeInfo'] = self.get_node_info(data['NodeInfo'], self.public_ip, self.bridge_port)
        data['PrivateBridgeInfo'] = self.get_node_info(data['NodeInfo'], self.private_ip, self.bridge_port)

        result['validator'] = data

        return result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            path=dict(type='str', required=True),
            node_type=dict(type='str', required=True),
            port=dict(type='int', default=32323),
            bridge_port=dict(type='int', default=50505),
            public_ip=dict(type='str', required=True),
            private_ip=dict(type='str', required=True),
        ),
        supports_check_mode=False
    )

    runner = ModuleRunner(module)
    result = runner.run()

    module.exit_json(**result)


if __name__ == '__main__':
    main()

