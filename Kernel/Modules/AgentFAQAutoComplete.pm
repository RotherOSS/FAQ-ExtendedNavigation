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

package Kernel::Modules::AgentFAQAutoComplete;

use strict;
use warnings;
use Kernel::System::VariableCheck qw(:all);
use URI::Escape                   qw(uri_escape_utf8 uri_unescape);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $FAQObject    = $Kernel::OM->Get('Kernel::System::FAQ');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( $Self->{Subaction} eq 'GetFAQItems' ) {
        my %SearchParams;
        my @Items;

        for my $Needed (qw(Query UserID Marker)) {
            if ( !$ParamObject->GetParam( Param => $Needed ) ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need: $Needed!"
                );

                return @Items;
            }
        }

        $SearchParams{What}   = '*' . uri_unescape( $ParamObject->GetParam( Param => 'Query' ) ) . '*';
        $SearchParams{UserID} = $ParamObject->GetParam( Param => 'UserID' );
        $SearchParams{Valid}  = 1;

        my $Marker = uri_unescape( $ParamObject->GetParam( Param => 'Marker' ) );
        my $Hook   = $ConfigObject->Get('FAQ::FAQHook');

        my @IDs = $FAQObject->FAQSearch(
            %SearchParams
        );

        for my $ID (@IDs) {
            my %FAQ = $FAQObject->FAQGet(
                ItemID        => $ID,
                ItemFields    => 1,
                DynamicFields => 0,
                UserID        => 1,
            );

            push @Items,
                {
                    id      => $Marker . "$Hook $FAQ{Number} - $FAQ{Title}",             #ID Must contain marker
                    text    => "$Hook $FAQ{Number} - $FAQ{Title}",
                    item_id => $ID,
                    link    => "/otobo/index.pl?Action=AgentFAQZoom;ItemID=$ID;Nav=;",
                };
        }

        #Codifica la respuesta a devolver via AJAX
        my $JSON = $LayoutObject->JSONEncode(
            Data => \@Items,
        );

        #Retorna respuesta
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset='
                . $LayoutObject->{Charset},
            Content => $JSON,
            Type    => 'inline',
            NoCache => 1,
        );
    }

}

1;
