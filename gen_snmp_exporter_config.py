#!/usr/bin/env python
"""Generate an snmp_exporter configuration file for M-Lab's Juniper switches"""

import argparse
import json
import logging
import string
import sys


def parse_options(args):  # pragma: no cover
    """Parses the options passed to this script.

    Args:
        args: list of options passed on command line

    Returns:
        An argparse.ArgumentParser object containing the passed options and
        their values.
    """
    parser = argparse.ArgumentParser(
        description='Generates an snmp_exporter config M-Lab QFX5100 switches.')
    parser.add_argument('--output_file',
                        dest='output_file',
                        default='mlab.yml',
                        help='Filename where output will be written.')
    parser.add_argument('--juniper_template_path',
                        dest='juniper_template_path',
                        default='juniper-snmp_exporter-template',
                        help='Path to the Juniper config template file.')
    parser.add_argument('--other_template_path',
                        dest='other_template_path',
                        default='other-snmp_exporter-template',
                        help='Path to config template file for HPs and Ciscos.')

    args = parser.parse_args(args)

    return args


# TODO: the contents of this function are hopefully temporary. At the time of
# this writing, M-Lab does not have a centralized data store where site
# configuration data can be stored, retrieved and updated. In this particular
# example, the current canonical source of information for default switch SNMP
# communities and uplink ports is a file (switch-details.json) in the
# switch-config repository. In a better future, this function will consult some
# sort of centralized data store.
def read_switch_details():  # pragma: no cover
    """Retrieves switch details.

    Returns:
        A dict with all Juniper switch details
    """
    switch_details_path = 'switch-config/switch-details.json'

    with open(switch_details_path, 'r') as f:
        switch_details = json.load(f)

    return switch_details


def generate_config(site, details, config_template):  # pragma: no cover
    """Generates the full snmp_exporter config file.

    Args:
        site: str, short name of site (e.g., abc01).
        details: dict, switch configuration details.
        config_template: str, the string template for the switch.

    Returns:
        str, a valid snmp_exporter configuration for the passed site.
    """
    template = string.Template(config_template)

    template_vars = {'site': site, 'community': details['community']}

    try:
        site_config = template.safe_substitute(template_vars)
    except KeyError, e:
        logging.error(e)
        sys.exit(1)

    return site_config


def main():  # pragma: no cover
    args = parse_options(sys.argv[1:])
    switch_details = read_switch_details()
    exporter_config_file = open(args.output_file, 'w')

    try:
        juniper_template = open(args.juniper_template_path, 'r').read()
        other_template = open(args.other_template_path, 'r').read()
    except IOError, e:
        logging.error(e)
        sys.exit(1)

    for site, details in sorted(switch_details.iteritems()):
        if details['switch_make'] == 'juniper':
            config_template = juniper_template
        else:
            config_template = other_template

        site_config = generate_config(site, details, config_template)
        exporter_config_file.write(site_config)

    exporter_config_file.close()


if __name__ == '__main__':  # pragma: no cover
    main()
