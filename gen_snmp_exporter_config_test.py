#!/usr/bin/env python
#
# Copyright 2017 Measurement Lab
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# No docstrings required for tests, and tests need to be methods of classes to
# aid in organization of tests. Using the 'self' variable is not required.
#
# pylint: disable=missing-docstring, no-self-use, too-many-public-methods

import json
import logging
import os
import textwrap
import unittest

import gen_snmp_exporter_config
import mock

logging.disable(logging.CRITICAL)


class GenSnmpExporterConfigTest(unittest.TestCase):

    def setUp(self):

        self.output_file = '/tmp/test_gen_snmp_exporter_config'
        self.argv_good = ['rofl', '--output_file', self.output_file]
        self.argv_bad = ['rofl', '--juniper_template_path', '/lol/not_here.txt']
        self.sample_details_json = """{
            "lol01": {
                "auto_negotiation": "yes",
                "community": "ekEa00ClZZkTvEJqe0jU",
                "switch_make": "hp",
                "uplink_port": "48",
                "uplink_speed": "1g"
            },
            "brb02": {
                "auto_negotiation": "no",
                "community": "tyUenN0gEVF0LdbtbQmH",
                "switch_make": "juniper",
                "uplink_port": "xe-0/0/45",
                "uplink_speed": "10g"
            }
        }"""

        self.expected_output = textwrap.dedent("""\
            brb02:
              version: 2
              auth:
                community: tyUenN0gEVF0LdbtbQmH
              walk:
              - 1.3.6.1.2.1.2
              - 1.3.6.1.2.1.31.1.1
              - 1.3.6.1.4.1.2636.3.15.4.1
              metrics:
              - name: jnxCosQstatTotalDropPkts
                oid: 1.3.6.1.4.1.2636.3.15.4.1.53
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                - labelname: qNumber
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifInErrors
                oid: 1.3.6.1.2.1.2.2.1.14
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifOutErrors
                oid: 1.3.6.1.2.1.2.2.1.20
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCInOctets
                oid: 1.3.6.1.2.1.31.1.1.1.6
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCOutOctets
                oid: 1.3.6.1.2.1.31.1.1.1.10
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCInUcastPkts
                oid: 1.3.6.1.2.1.31.1.1.1.7
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCOutUcastPkts
                oid: 1.3.6.1.2.1.31.1.1.1.11
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
            lol01:
              version: 2
              auth:
                community: ekEa00ClZZkTvEJqe0jU
              walk:
              - 1.3.6.1.2.1.2
              - 1.3.6.1.2.1.31.1.1
              - 1.3.6.1.4.1.2636.3.15.4.1
              metrics:
              - name: ifInDiscards
                oid: 1.3.6.1.2.1.2.2.1.13
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifOutDiscards
                oid: 1.3.6.1.2.1.2.2.1.19
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifInErrors
                oid: 1.3.6.1.2.1.2.2.1.14
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifOutErrors
                oid: 1.3.6.1.2.1.2.2.1.20
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCInOctets
                oid: 1.3.6.1.2.1.31.1.1.1.6
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCOutOctets
                oid: 1.3.6.1.2.1.31.1.1.1.10
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCInUcastPkts
                oid: 1.3.6.1.2.1.31.1.1.1.7
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString
              - name: ifHCOutUcastPkts
                oid: 1.3.6.1.2.1.31.1.1.1.11
                type: counter
                indexes:
                - labelname: ifIndex
                  type: gauge
                lookups:
                - labels:
                  - ifIndex
                  labelname: ifDescr
                  oid: 1.3.6.1.2.1.2.2.1.2
                  type: DisplayString
                - labels:
                  - ifIndex
                  labelname: ifAlias
                  oid: 1.3.6.1.2.1.31.1.1.1.18
                  type: DisplayString\n""")

    @mock.patch.object(gen_snmp_exporter_config, 'read_switch_details')
    def test_main(self, mock_read_switch_details):
        mock_read_switch_details.return_value = json.loads(
            self.sample_details_json)
        gen_snmp_exporter_config.main(self.argv_good)
        actual_output = open(self.output_file).read()
        os.remove(self.output_file)
        self.assertEqual(actual_output, self.expected_output)

    def test_main_bad_template_path_raises_ioerror(self):
        with self.assertRaises(IOError):
            gen_snmp_exporter_config.main(self.argv_bad)

    @mock.patch.object(gen_snmp_exporter_config, 'read_switch_details')
    def test_generate_site_config_bad_tmpl_raises_keyerror(
            self, mock_read_switch_details):
        mock_read_switch_details.return_value = json.loads(
            self.sample_details_json)
        switch_details = gen_snmp_exporter_config.read_switch_details()
        some_detail = switch_details.popitem()
        with self.assertRaises(KeyError):
            gen_snmp_exporter_config.generate_site_config(
                some_detail[0], some_detail[1], '${lol}')


if __name__ == '__main__':  # pragma: no cover
    unittest.main()
