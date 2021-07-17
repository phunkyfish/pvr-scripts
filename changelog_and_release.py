# -*- coding: utf-8 -*-
import argparse
import fnmatch
import os
import re

from datetime import date

TODAY = date.today().isoformat()
GET_VERSION = re.compile(r'''<addon.+?version="(?P<version>[0-9.]+)"''', re.DOTALL)


def increment_version(version, version_type='micro'):
    version = version.split('.')

    if version_type == 'micro':
        version[2] = str(int(version[2]) + 1)
    else:
        version[1] = str(int(version[1]) + 1)
        version[2] = '0'

    return '.'.join(version)


def walk(directory, pattern):
    for root, dirs, files in os.walk(directory):
        for basename in files:
            if fnmatch.fnmatch(basename, pattern):
                fname = os.path.join(root, basename)
                yield fname


def find_addon_xml():
    for filename in walk('.', 'addon.xml.in'):
        print('Found addon.xml.in:', filename)
        return filename


def find_changelog():
    for filename in walk('.', 'changelog.txt'):
        print('Found changelog.txt:', filename)
        return filename


def create_changelog_string(version, changelog_text, add_date=False):
    version_string = 'v{version}'.format(version=version)
    if add_date:
        version_string += ' ({today})'.format(today=TODAY)

    return '{version}\n{changelog_text}\n\n'.format(
        version=version_string,
        changelog_text=changelog_text
    )


def update_changelog(version, changelog_text, add_date=False):
    changelog = find_changelog()
    if not changelog:
        return

    changelog_string = create_changelog_string(version, changelog_text, add_date)

    print('Writing changelog.txt:\n\'\'\'\n{lines}\'\'\''.format(lines=changelog_string))
    with open(changelog, 'r+') as f:
        content = f.read()
        f.seek(0, 0)
        f.write(changelog_string + content)


def update_news(addon_xml, version, changelog_text, add_date=False):
    xml_content = read_addon_xml(addon_xml)

    changelog_string = create_changelog_string(version, changelog_text, add_date)

    print('Writing news to addon.xml.in:\n\'\'\'\n{lines}\'\'\''.format(lines=changelog_string))

    new_xml_content = xml_content.replace('<news>', '<news>\n{lines}'.format(
        lines=changelog_string
    ))

    new_xml_content = new_xml_content.replace('\n\n\n', '\n\n')

    with open(addon_xml, 'w') as open_file:
        open_file.write(new_xml_content)

    print('')


def read_addon_xml(addon_xml):
    print('Reading {filename}'.format(filename=addon_xml))

    with open(addon_xml, 'r') as open_file:
        return open_file.read()


def current_version(xml_content):
    version_match = GET_VERSION.search(xml_content)
    if not version_match:
        print('Unable to determine current version... skipping.', '')
        return

    return version_match.group('version')


def update_xml_version(addon_xml, xml_content, old_version, new_version):
    print('\tOld Version: {version}'.format(version=old_version))
    print('\tNew Version: {version}'.format(version=new_version))

    new_xml_content = xml_content.replace(
        'version="{version}"'.format(version=old_version),
        'version="{version}"'.format(version=new_version),
    )

    if xml_content == new_xml_content:
        print('XML was unmodified... skipping.', '')
        return

    print('Writing {filename}'.format(filename=addon_xml))
    with open(addon_xml, 'w') as open_file:
        open_file.write(new_xml_content)

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

    xml_content = read_addon_xml(addon_xml)

    old_version = current_version(xml_content)
    new_version = increment_version(old_version, version_type=args.version_type)

    changelog_text = args.changelog_text
    changelog_text = changelog_text.strip()
    changelog_text = changelog_text.replace(r'\n', '\n')
    changelog_text = changelog_text.replace(r'\t', '\t')

    update_xml_version(addon_xml, xml_content, old_version, new_version)

    update_changelog(new_version, changelog_text, args.add_date)

    if args.update_news:
        update_news(addon_xml, new_version, changelog_text, args.add_date)

    print('')


if __name__ == '__main__':
    main()
