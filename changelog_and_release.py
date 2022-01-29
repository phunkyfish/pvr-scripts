# -*- coding: utf-8 -*-
"""
    Copyright (C) 2021 TeamKodi

    This file is part of pvr-scripts

    SPDX-License-Identifier: GPL-3.0-only
    See LICENSES/GPL-3.0-only for more information.

    Update the changelog, news (optionally) and increment the version of a binary add-on.

    usage: changelog_and_release.py [-h] [-d] [-n] {micro,minor} changelog_text

    positional arguments:
      {micro,minor}      Increment "micro" or "minor" version
      changelog_text     Text to be added to the changelog (without version
                         number).

    optional arguments:
      -h, --help         show this help message and exit
      -d, --add-date     Add date to version number in changelog and news. ie.
                         "v1.0.1 (2021-7-17)"
      -n, --update-news  Add changes to news section of the addon.xml.in

"""

import argparse
import fnmatch
import os
import re

from datetime import date

TODAY = date.today().isoformat()
GET_VERSION = re.compile(r'''<addon.+?version="(?P<version>[0-9.]+)"''', re.DOTALL)


def increment_version(version, version_type='micro'):
    """
    Increment the provided version number
    :param version: version number to increment in format '1.0.0'
    :type version: str
    :param version_type: 'micro' / 'minor', type of version increment
    :type version_type: str
    :return: incremented version number
    :rtype: str
    """
    version = version.split('.')

    if version_type == 'micro':
        version[2] = str(int(version[2]) + 1)
    else:
        version[1] = str(int(version[1]) + 1)
        version[2] = '0'

    return '.'.join(version)


def walk(directory, pattern):
    """
    Generator to walk the provided directory and yield files matching the pattern
    :param directory: directory to recursively walk
    :type directory: str
    :param pattern: glob pattern, https://docs.python.org/3/library/fnmatch.html
    :type pattern: str
    :return: filenames (with path) matching pattern
    :rtype: str
    """
    for root, dirs, files in os.walk(directory):
        for basename in files:
            if fnmatch.fnmatch(basename, pattern):
                fname = os.path.join(root, basename)
                yield fname


def find_addon_xml():
    """
    Find the addon.xml.in path
    :return: path with filename to addon.xml.in
    :rtype: str
    """
    for filename in walk('.', 'addon.xml.in'):
        print('Found addon.xml.in:', filename)
        return filename


def find_changelog():
    """
    Find the changelog.txt path
    :return: path with filename to changelog.txt
    :rtype: str
    """
    for filename in walk('.', 'changelog.txt'):
        print('Found changelog.txt:', filename)
        return filename


def create_changelog_string(version, changelog_text, add_date=False):
    """
    Create the string that will be added to the changelog
    :param version: version number being created
    :type version: str
    :param changelog_text: string containing the changes for this version use '\n' and '\t' these will be replaced later
    :type changelog_text: str
    :param add_date: add date to the version number. ie. v1.0.0 (2021-7-19)
    :type add_date: bool
    :return: formatted string for the changelog
    :rtype: str
    """
    version_string = 'v{version}'.format(version=version)
    if add_date:
        version_string += ' ({today})'.format(today=TODAY)

    return '{version}\n{changelog_text}\n\n'.format(
        version=version_string,
        changelog_text=changelog_text
    )


def update_changelog(changelog, version, changelog_text, add_date=False):
    """
    Update the changelog.txt with a formatted version of the provided information
    :param changelog: path with filename to changelog.txt
    :type changelog: str
    :param version: version number being created
    :type version: str
    :param changelog_text: string containing the changes for this version use '\n' and '\t' these will be replaced later
    :type changelog_text: str
    :param add_date: add date to the version number. ie. v1.0.0 (2021-7-19)
    :type add_date: bool
    """

    changelog_string = create_changelog_string(version, changelog_text, add_date)

    with open(changelog, 'r') as f:
        content = f.read()

    return changelog_string + content


def write_changelog(changelog, contents):
    """
    Append contents to the top of the changelog
    :param changelog: path with filename to the changelog.txt
    :type changelog: str
    :param contents: contents to be appended to changelog.txt
    :type contents: str
    """
    print('Writing changelog.txt:\n\'\'\'\n{lines}\'\'\''.format(lines=contents))
    with open(changelog, 'w') as f:
        f.write(contents)


def update_news(xml_content, version, changelog_text, add_date=False):
    """
    Update the news element of the addon.xml.in with a formatted version of the provided information
    :param xml_content: contents of the addon.xml.in
    :type xml_content: str
    :param version: version number being created
    :type version: str
    :param changelog_text: string containing the changes for this version, use '\n' and '\t' these will be replaced later
    :type changelog_text: str
    :param add_date: add date to the version number. ie. v1.0.0 (2021-7-19)
    :type add_date: bool
    """
    changelog_string = create_changelog_string(version, changelog_text, add_date)

    print('Adding news to addon.xml.in:\n\'\'\'\n{lines}\'\'\''.format(lines=changelog_string))

    new_xml_content = xml_content.replace('<news>', '<news>\n{lines}'.format(
        lines=changelog_string
    ))

    new_xml_content = new_xml_content.replace('\n\n\n', '\n\n')

    return new_xml_content


def read_addon_xml(addon_xml):
    """
    Read the addon.xml.in
    :param addon_xml: path with filename to the addon.xml.in
    :type addon_xml: str
    :return: contents of the addon.xml.in
    :rtype: str
    """
    print('Reading {filename}'.format(filename=addon_xml))

    with open(addon_xml, 'r') as open_file:
        return open_file.read()


def current_version(xml_content):
    """
    Get the current version from the addon.xml.in
    :param xml_content: contents of the addon.xml.in
    :type xml_content: str
    :return: the current version
    :rtype: str
    """
    version_match = GET_VERSION.search(xml_content)
    if not version_match:
        print('Unable to determine current version... skipping.', '')
        return ''

    return version_match.group('version')


def update_xml_version(xml_content, old_version, new_version):
    """
    Update the version in the addon.xml.in contents
    :param xml_content: contents of the addon.xml.in
    :type xml_content: str
    :param old_version: the old/current version number
    :type old_version: str
    :param new_version: the new version number
    :type new_version: str
    """
    print('\tOld Version: {version}'.format(version=old_version))
    print('\tNew Version: {version}'.format(version=new_version))

    new_xml_content = xml_content.replace(
        'version="{version}"'.format(version=old_version),
        'version="{version}"'.format(version=new_version),
    )

    if xml_content == new_xml_content:
        print('XML was unmodified... skipping.', '')
        return ''

    return new_xml_content


def write_addon_xml(addon_xml, xml_content):
    """
    Write the provided xml to the addon.xml.in
    :param addon_xml: path with filename to the addon.xml.in
    :type addon_xml: str
    :param xml_content: contents of the addon.xml.in
    :type xml_content: str
    """
    print('Writing {filename}'.format(filename=addon_xml))
    with open(addon_xml, 'w') as open_file:
        open_file.write(xml_content)

    print('')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('version_type', type=str, choices=['micro', 'minor'],
                        help='Increment "micro" or "minor" version')

    parser.add_argument('changelog_text', type=str,
                        help='Text to be added to the changelog (without version number).')

    parser.add_argument('-d', '--add-date', action='store_true',
                        help='Add date to version number in changelog and news. ie. "v1.0.1 (2021-7-17)"')

    parser.add_argument('-n', '--update-news', action='store_true',
                        help='Add changes to news section of the addon.xml.in')

    args = parser.parse_args()

    print('')

    addon_xml = find_addon_xml()
    if not addon_xml:
        print('addon.xml.in not found. exiting...')
        exit(1)

    xml_content = read_addon_xml(addon_xml)

    old_version = current_version(xml_content)
    if not old_version:
        print('Unable to determine the current version. exiting...')
        exit(1)

    new_version = increment_version(old_version, version_type=args.version_type)

    changelog_text = args.changelog_text
    changelog_text = changelog_text.strip()
    changelog_text = changelog_text.replace(r'\n', '\n')
    changelog_text = changelog_text.replace(r'\t', '\t')

    xml_content = update_xml_version(xml_content, old_version, new_version)
    if not xml_content:
        print('Unable to update the current version in the addon.xml.in. exiting...')
        exit(1)

    write_addon_xml(addon_xml, xml_content)

    changelog = find_changelog()
    if changelog:
        changelog_content = update_changelog(changelog, new_version,
                                             changelog_text, args.add_date)
        write_changelog(changelog, changelog_content)

    if args.update_news:
        xml_content = update_news(xml_content, new_version, changelog_text, args.add_date)
        write_addon_xml(addon_xml, xml_content)

    print('')


if __name__ == '__main__':
    main()
