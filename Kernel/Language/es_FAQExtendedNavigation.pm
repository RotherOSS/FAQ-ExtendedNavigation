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

package Kernel::Language::es_FAQExtendedNavigation;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Table of Contents'} = 'Tabla de Contenidos';
    $Self->{Translation}->{'Back to FAQ Home'} = 'Página inicial';
    $Self->{Translation}->{'Back to top'} = 'Volver al inicio';
    $Self->{Translation}->{'Icon (svg)'} = 'Icono (svg)';
    $Self->{Translation}->{'Upload Icon'} = 'Cargar Icono';
    $Self->{Translation}->{'Select an icon in SVG format to upload it.'} = 'Seleccione un icono en formato SVG para cargarlo.';
    $Self->{Translation}->{'Quicklink Management'} = 'Gestión de la Barra Lateral';
    $Self->{Translation}->{'Filter for Settings'} = 'Filtrar Configuraciones';
    $Self->{Translation}->{'FAQ Sidebar Settings'} = 'Gestión de la Barra Lateral del FAQ';
    $Self->{Translation}->{'Load Settings'} = 'Cargar Configuración';
    $Self->{Translation}->{'Default FAQ Item'} = 'Artículo del FAQ por defecto';
    $Self->{Translation}->{'Custom Group Order'} = 'Orden personalizado de los grupos';
    $Self->{Translation}->{'Move Up'} = 'Mover Arriba';
    $Self->{Translation}->{'Move Down'} = 'Mover Abajo';
    $Self->{Translation}->{'Quickstart Links'} = 'Enlaces de Acceso Rápido';
    $Self->{Translation}->{'Settings for'} = 'Configuración para';
    $Self->{Translation}->{'Reset Setting'} = 'Restablecer configuración';
    $Self->{Translation}->{'Restoring these settings will erase all data. Are you sure you want to proceed?'} = 'Al restablecer esta configuración, todos los datos se perderan. Esta seguro de proceder?';
    $Self->{Translation}->{'Settings successfully updated!'} = 'Configuración actualizada correctamente!';
    $Self->{Translation}->{'Settings successfully reset!'} = 'Configuración restablecida correctamente!';
    $Self->{Translation}->{'Language configuration limit reached for the interface: %s!'} = 'Limite de configuración de idiomas alcanzado para la interfaz: %s!';

    $Self->{Translation}->{'Configure the sidebar parameters according to the OTOBO language and interface'} = 'Configure los parámetros de la barra lateral según el idioma y la interfaz de OTOBO';
    $Self->{Translation}->{'OTOBO interface where the sidebar will be displayed.'} = 'Interfaz de OTOBO donde se mostrará la barra lateral.';
    $Self->{Translation}->{'User\'s language in the OTOBO interface.'} = 'Idioma del usuario en la interfaz de OTOBO.';
    $Self->{Translation}->{'Select the default article that will be displayed in the zoom view when the FAQ loads.'} = 'Seleccione el artículo por defecto que se mostrará en la vista de zoom cuando se cargue el FAQ.';
    $Self->{Translation}->{'Define the order in which the quick link groups in the FAQ will be displayed.'} = 'Defina el orden en el que se mostrarán los grupos de enlaces rápidos en el FAQ.';
    $Self->{Translation}->{'Definition of the links to the FAQ articles. They must be configured as follows:'} = 'Definición de los enlaces a los artículos del FAQ. Deben configurarse de la siguiente manera:';
    $Self->{Translation}->{'In the text field: Name of the group to consolidate the links. Up to two levels of depth can be defined. Use the syntax "Group::Subgroup" when defining subgroups.'} = 'En el campo de texto: Nombre del grupo para consolidar los enlaces. Se pueden definir hasta dos niveles de profundidad. Use la sintaxis "Grupo::Subgrupo" al definir subgrupos.';
    $Self->{Translation}->{'FAQ Article: Select the FAQ article from the list that will be displayed in the sidebar.'} = 'Artículo del FAQ: Seleccione el artículo del FAQ de la lista que se mostrará en la barra lateral.';
    $Self->{Translation}->{'The "Reset settings" button only applies to the settings currently being edited.'} = 'El botón "Restablecer configuración" solo aplica a los ajustes que se están editando.';
    $Self->{Translation}->{'Launch the Add/Edit Sidebar Settings screen by selecting:'} = 'Cargue la pantalla de Agregar/Editar Configuración de la Barra Lateral seleccionando:';
    $Self->{Translation}->{'No default item has been set yet! Start browsing articles in the'} = '¡No se ha establecido un artículo por defecto todavía! Comience a navegar los artículos en el';

    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Restoring these settings will erase all data. Are you sure you want to proceed?',
    );

}

1;
