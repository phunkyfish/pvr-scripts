# -*- coding: utf-8 -*-
"""
    Copyright (C) 2021 TeamKodi

    This file is part of sync_addon_metadata_translations

    SPDX-License-Identifier: GPL-3.0-only
    See LICENSES/GPL-3.0-only for more information.

"""

import os
import pytest
import sys

sys.path.append('..')

import changelog_and_release as target

FIXTURES_PATH = os.path.join(os.getcwd(), 'tests', 'fixtures')
CHANGELOG_STRING_TEMPLATE = '{version}\n{changelog_text}\n\n'


@pytest.fixture(scope='class')
def staging(request):
    with open(os.path.join(FIXTURES_PATH, 'pvr.binary.example',
                           'pvr.binary.example', 'addon.xml.in'), 'r') as open_file:
        request.cls.addon_xml = open_file.read()

    with open(os.path.join(FIXTURES_PATH, 'pvr.binary.example',
                           'pvr.binary.example', 'changelog.txt'), 'r') as open_file:
        request.cls.changelog = open_file.read()


@pytest.mark.usefixtures('staging')
class TestChangelogAndRelease:

    def test_increment_version(self):
        initial_version = '1.0.0'
        expected_micro_version = '1.0.1'
        expected_minor_version = '1.1.0'

        micro_version = target.increment_version(initial_version, version_type='micro')
        assert micro_version == expected_micro_version, \
            'Micro Version mismatch: Expected: {expected}, Actual: {actual}' \
                .format(expected=expected_micro_version, actual=micro_version)

        minor_version = target.increment_version(initial_version, version_type='minor')
        assert minor_version == expected_minor_version, \
            'Minor Version mismatch: Expected: {expected}, Actual: {actual}' \
                .format(expected=expected_minor_version, actual=minor_version)

    def test_walk(self):
        base_path = os.path.join(FIXTURES_PATH, 'pvr.binary.example', 'pvr.binary.example')

        expected_files_xml = [
            os.path.join(base_path, 'addon.xml.in')
        ]
        expected_files_txt = [
            os.path.join(base_path, 'changelog.txt')
        ]

        result_files_xml = list(target.walk(FIXTURES_PATH, '*.xml.in'))
        result_files_txt = list(target.walk(FIXTURES_PATH, '*.txt'))

        assert expected_files_xml == result_files_xml, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected_files_xml, actual=result_files_xml)
        assert expected_files_txt == result_files_txt, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected_files_txt, actual=result_files_txt)

    def test_find_addon_xml(self):
        expected_path = os.path.join('pvr.binary.example', 'pvr.binary.example', 'addon.xml.in')
        addon_xml_path = target.find_addon_xml()
        assert addon_xml_path.endswith(expected_path) is True, \
            'Expected actual to end with: {expected}, Actual: {actual}' \
                .format(expected=expected_path, actual=addon_xml_path)

    def test_find_changelog(self):
        expected_path = os.path.join('pvr.binary.example', 'pvr.binary.example', 'changelog.txt')
        addon_xml_path = target.find_changelog()
        assert addon_xml_path.endswith(expected_path) is True, \
            'Expected actual to end with: {expected}, Actual: {actual}' \
                .format(expected=expected_path, actual=addon_xml_path)

    def test_create_changelog_string(self):
        version = '1.0.0'
        version_string = 'v' + version
        changelog_text = 'Testing'

        expected = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )

        actual = target.create_changelog_string(version, changelog_text, add_date=False)
        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

        version_string += ' ({today})'.format(today=target.TODAY)

        expected = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )

        actual = target.create_changelog_string(version, changelog_text, add_date=True)
        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

    def test_read_addon_xml(self):
        expected = self.addon_xml
        actual = target.read_addon_xml(target.find_addon_xml())
        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

    def test_current_version(self):
        expected = '7.19.1'
        actual = target.current_version(self.addon_xml)
        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

    def test_update_xml_version(self):
        version_template = 'version="{version}"'
        old_version = '7.19.1'
        new_version = '7.19.2'
        expected = self.addon_xml.replace(version_template.format(version=old_version),
                                          version_template.format(version=new_version))
        actual = target.update_xml_version(self.addon_xml, old_version, new_version)
        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

    def test_update_changelog(self):
        changelog = os.path.join(FIXTURES_PATH, 'pvr.binary.example',
                                 'pvr.binary.example', 'changelog.txt')
        version = '7.19.2'
        version_string = 'v' + version
        changelog_text = 'Testing'

        expected = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )
        expected += self.changelog
        actual = target.update_changelog(changelog, version, changelog_text, add_date=False)

        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

        version_string += ' ({today})'.format(today=target.TODAY)

        expected = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )
        expected += self.changelog
        actual = target.update_changelog(changelog, version, changelog_text, add_date=True)

        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

    def test_update_news(self):
        version = '7.19.2'
        version_string = 'v' + version
        changelog_text = 'Testing'

        changelog_string = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )

        expected = self.addon_xml.replace('<news>', '<news>\n{lines}'.format(
            lines=changelog_string
        ))
        expected = expected.replace('\n\n\n', '\n\n')
        actual = target.update_news(self.addon_xml, version, changelog_text, add_date=False)

        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)

        version_string += ' ({today})'.format(today=target.TODAY)

        changelog_string = CHANGELOG_STRING_TEMPLATE.format(
            version=version_string,
            changelog_text=changelog_text
        )

        expected = self.addon_xml.replace('<news>', '<news>\n{lines}'.format(
            lines=changelog_string
        ))
        expected = expected.replace('\n\n\n', '\n\n')
        actual = target.update_news(self.addon_xml, version, changelog_text, add_date=True)

        assert expected == actual, 'Expected: {expected}, Actual: {actual}' \
            .format(expected=expected, actual=actual)
