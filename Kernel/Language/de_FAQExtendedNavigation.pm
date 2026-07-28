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
    $Self->{Translation}->{'Icon (svg)'} = 'Icon (svg)';
    $Self->{Translation}->{'Upload Icon'} = 'Icon hochladen';
    $Self->{Translation}->{'Delete Icon'} = 'Icon löschen';
    $Self->{Translation}->{'Select an icon in SVG format to upload it.'} = 'Wählen Sie ein Symbol im SVG-Format aus, um es hochzuladen.';

    $Self->{Translation}->{'Quick Link Settings'} = 'Schnell-Link-Verwaltung';
    $Self->{Translation}->{'Filter for Settings'} = 'Filter für Einstellungen';
    $Self->{Translation}->{'FAQ Sidebar Settings'} = 'FAQ-Seitenleistenkonfiguration';
    $Self->{Translation}->{'Load Settings'} = 'Lade Konfiguration';
    $Self->{Translation}->{'Default FAQ Item'} = 'FAQ-Startseite';
    $Self->{Translation}->{'Custom Group Order'} = 'Kategoriensortierung';
    $Self->{Translation}->{'Move Up'} = 'Nach oben';
    $Self->{Translation}->{'Move Down'} = 'Nach unten';
    $Self->{Translation}->{'Quickstart Links'} = 'Schnell-Links';
    $Self->{Translation}->{'Settings for'} = 'Einstellungen für';
    $Self->{Translation}->{'Reset Setting'} = 'Einstellungen zurücksetzen';
    $Self->{Translation}->{'Restoring these settings will erase all data. Are you sure you want to proceed?'} = 'Wiederherstellen dieser Einstellungen wird alle Daten löschen. Trotzdem fortfahren?';
    $Self->{Translation}->{'Settings successfully updated!'} = 'Einstellungen erfolgreich geupdated!';
    $Self->{Translation}->{'Settings successfully reset!'} = 'Einstellungen erfolgreich zurückgesetzt!';
    $Self->{Translation}->{'Language configuration limit reached for the interface: %s!'} = 'Maximale Anzahl an Spracheinstellungen für das Interface %s erreicht!';
    $Self->{Translation}->{'Configure the sidebar parameters according to the OTOBO language and interface'} = 'Konfiguriere die Seitenleisten-Einstellungen abhängig von Interface und Sprache.';
    $Self->{Translation}->{'OTOBO interface where the sidebar will be displayed.'} = 'OTOBO-Interface auf dem die Seitenleiste angezeigt werden wird.';
    $Self->{Translation}->{'User\'s language in the OTOBO interface.'} = 'Sprache des Nutzers in OTOBO.';
    $Self->{Translation}->{'Select the default article that will be displayed in the zoom view when the FAQ loads.'} = 'Wähle den Standard-Artikel, der in der FAQ-Zoom angezeigt wird.';
    $Self->{Translation}->{'Define the order in which the quick link groups in the FAQ will be displayed.'} = 'Lege die Reihenfolge fest, in der die Kategorien der Schnell-Links dargestellt werden.';
    $Self->{Translation}->{'Definition of the links to the FAQ articles. They must be configured as follows:'} = 'Definition der FAQ-Links. Die Konfiguration ist wie folgt:';
    $Self->{Translation}->{'In the text field: Name of the group to consolidate the links. Up to two levels of depth can be defined. Use the syntax "Group::Subgroup" when defining subgroups.'} = 'Im Textfeld der Name unter dem Artikel gruppiert werden. Bis zu zwei Ebenen können festegelgt werden, die Syntax für Untergruppen ist "Gruppe::Untergruppe".';
    $Self->{Translation}->{'FAQ Article: Select the FAQ article from the list that will be displayed in the sidebar.'} = 'FAQ-Artikel: Wähle den FAQ-Artikel aus der Liste, der in der Seitenleiste angezeigt wird.';
    $Self->{Translation}->{'The "Reset settings" button only applies to the settings currently being edited.'} = 'Der "Einstellungen zurücksetzen"-Knopf betrifft ausschließlich die momentan bearbeitete Einstellung.';
    $Self->{Translation}->{'Launch the Add/Edit Sidebar Settings screen by selecting:'} = 'Öffne die Seite zum Zufügen und Bearbeiten durch Auswahl:';
    $Self->{Translation}->{'No default item has been set yet! Start browsing articles in the'} = 'Kein Einstiegsartikel gesetzt! Durchsuche die FAQs im';

    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Restoring these settings will erase all data. Are you sure you want to proceed?',
    );


}

1;
