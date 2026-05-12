# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Language::de_FAQExtendedNavigation;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Table of Contents'} = 'Inhaltsverzeichnis';
    $Self->{Translation}->{'Back to FAQ Home'} = 'Zurück zur FAQ-Startseite';
    $Self->{Translation}->{'Back to top'} = 'Zurück nach oben';
    $Self->{Translation}->{'Icon (svg)'} = '';
    $Self->{Translation}->{'Upload Icon'} = 'Upload-Symbol';
    $Self->{Translation}->{'Select an icon in SVG format to upload it.'} = 'Wählen Sie ein Symbol im SVG-Format aus, um es hochzuladen.';

    $Self->{Translation}->{'Sidebar Settings'} = '';
    $Self->{Translation}->{'Filter for Settings'} = '';
    $Self->{Translation}->{'FAQ Sidebar Settings'} = '';
    $Self->{Translation}->{'Load Settings'} = '';
    $Self->{Translation}->{'Default FAQ Item'} = '';
    $Self->{Translation}->{'Custom Group Order'} = '';
    $Self->{Translation}->{'Move Up'} = '';
    $Self->{Translation}->{'Move Down'} = '';
    $Self->{Translation}->{'Quickstart Links'} = '';
    $Self->{Translation}->{'Settings for'} = '';
    $Self->{Translation}->{'Reset Setting'} = '';
    $Self->{Translation}->{'Restoring these settings will erase all data. Are you sure you want to proceed?'} = '';
    $Self->{Translation}->{'Settings successfully updated!'} = '';
    $Self->{Translation}->{'Settings successfully reset!'} = '';
    $Self->{Translation}->{'Language configuration limit reached for the interface: %s!'} = '';
    $Self->{Translation}->{'Configure the sidebar parameters according to the OTOBO language and interface'} = '';
    $Self->{Translation}->{'OTOBO interface where the sidebar will be displayed.'} = '';
    $Self->{Translation}->{'User\'s language in the OTOBO interface.'} = '';
    $Self->{Translation}->{'Select the default article that will be displayed in the zoom view when the FAQ loads.'} = '';
    $Self->{Translation}->{'Define the order in which the quick link groups in the FAQ will be displayed.'} = '';
    $Self->{Translation}->{'Definition of the links to the FAQ articles. They must be configured as follows:'} = '';
    $Self->{Translation}->{'In the text field: Name of the group to consolidate the links. Up to two levels of depth can be defined. Use the syntax "Group::Subgroup" when defining subgroups.'} = '';
    $Self->{Translation}->{'FAQ Article: Select the FAQ article from the list that will be displayed in the sidebar.'} = '';
    $Self->{Translation}->{'The "Reset settings" button only applies to the settings currently being edited.'} = '';
    $Self->{Translation}->{'Launch the Add/Edit Sidebar Settings screen by selecting:'} = '';
    $Self->{Translation}->{'No default item has been set yet! Start browsing articles in the'} = '';

    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Restoring these settings will erase all data. Are you sure you want to proceed?',
    );


}

1;
