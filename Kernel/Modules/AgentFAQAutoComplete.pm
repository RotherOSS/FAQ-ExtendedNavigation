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
use URI::Escape                   qw(uri_unescape);

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

        # fetch params
        my %GetParam;
        for my $Param (qw(Query Marker)) {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param );
        }

        my %SearchParams;
        my @Items;

        if ( !defined $GetParam{Query} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need: Query!"
            );

            return @Items;
        }

        for my $Needed (qw(Marker)) {
            if ( !$GetParam{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need: $Needed!"
                );

                return @Items;
            }
        }

        $SearchParams{What}  = '*' . uri_unescape( $GetParam{Query} ) . '*';
        $SearchParams{Valid} = 1;

        my $Marker = uri_unescape( $GetParam{Marker} );
        my $Hook   = $ConfigObject->Get('FAQ::FAQHook');

        # Get UserCategoryGroup Hash.
        # This returns a Hash of the following sample data structure:
        #
        # $UserCatGroup = {
        #   '1' => {
        #          '3' => 'MiscSub'
        #        },
        #   '3' => {},
        #   '0' => {
        #            '1' => 'Misc',
        #            '2' => 'secret'
        #          },
        #   '2' => {}
        # };
        #
        # Keys of the outer hash inform about subcategories.
        #   0 Shows top level CategoryIDs.
        #   1 Shows the SubcategoryIDs of Category 1.
        #   2 and 3 are empty hashes because these categories don't have subcategories.
        #
        # Keys of the inner hashes are CategoryIDs a user is allowed to have ro access to.
        # Values are the Category names.
        my $UserCatGroup = $FAQObject->GetUserCategories(
            Type   => 'ro',
            UserID => $Self->{UserID},
        );

        # Find CategoryIDs the current User is allowed to view.
        my %AllowedCategoryIDs = ();

        if ( $UserCatGroup && ref $UserCatGroup eq 'HASH' ) {

            # So now we have to extract all Category ID's of the "inner hashes"
            #   -> Loop through the outer category ID's.
            for my $Level ( sort keys %{$UserCatGroup} ) {

                # Check if the Value of the current hash key is a hash ref.
                if ( $UserCatGroup->{$Level} && ref $UserCatGroup->{$Level} eq 'HASH' ) {

                    # Map the keys of the inner hash to a TempIDs hash.
                    # Original Data structure:
                    #   {
                    #       '1' => 'Misc',
                    #       '2' => 'secret'
                    #   }
                    #
                    #   after mapping:
                    #
                    #   {
                    #       '1' => 1,
                    #       '2' => 1'
                    #   }
                    my %TempIDs = map { $_ => 1 } keys %{ $UserCatGroup->{$Level} };

                    # Put the TempIDs over the formally found AllowedCategories to produce a hash
                    #   that holds all CategoryID as keys and the number 1 as values.
                    %AllowedCategoryIDs = (
                        %AllowedCategoryIDs,
                        %TempIDs
                    );
                }
            }
        }

        # For the database query it's necessary to have an array of CategoryIDs.
        my @CategoryIDs = ();

        if (%AllowedCategoryIDs) {
            @CategoryIDs = sort keys %AllowedCategoryIDs;
        }

        # Just search if we do have categories, we have access to.
        # If we don't have access to any category, a search with no CategoryIDs
        #   would result in finding all categories.
        #
        # It is not possible to create FAQ's without categories
        #   so at least one category has to be present

        my @IDs;
        if (@CategoryIDs) {
            @IDs = $FAQObject->FAQSearch(
                %SearchParams,
                CategoryIDs => \@CategoryIDs,
                UserID      => $Self->{UserID},
            );
        }

        for my $ID (@IDs) {
            my %FAQ = $FAQObject->FAQGet(
                ItemID        => $ID,
                ItemFields    => 1,
                DynamicFields => 0,
                UserID        => $Self->{UserID},
            );

            push @Items,
                {
                    id      => $Marker . "$Hook $FAQ{Number} - $FAQ{Title}",             #ID Must contain marker
                    text    => "$Hook $FAQ{Number} - $FAQ{Title}",
                    item_id => $ID,
                    link    => "/otobo/index.pl?Action=AgentFAQZoom;ItemID=$ID;Nav=;",
                };
        }

        my $JSON = $LayoutObject->JSONEncode(
            Data => \@Items,
        );

        # return data to frontend
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
