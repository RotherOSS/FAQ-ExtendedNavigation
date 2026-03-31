# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
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

package Kernel::Output::HTML::Layout::FAQImprovements;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

use Kernel::System::VariableCheck qw(:all);
use MIME::Base64                  qw(decode_base64 encode_base64);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::HTMLUtils',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Web::Request',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::FAQ',
    'Kernel::System::Valid'
);

=head1 NAME

Kernel::Output::HTML::Layout::FAQImprovements - all FAQImprovements-related HTML functions

=head1 DESCRIPTION

All FAQImprovements-related HTML functions

=head1 PUBLIC INTERFACE

=head2 FAQSideBar()

Shows a side bar to quick open FAQ articles.

    $LayoutObject->FAQSideBar(
        Mode            => 'Public',                   # (Agent, Customer, Public)
        Language        => $Self->{UserLanguage},
        Interface       => $Self->{Interface},
        UserID          => 1,
    );

=cut

sub FAQSideBar {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $ParamName (qw(Mode Language UserID)) {
        if ( !$Param{$ParamName} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $ParamName!",
            );
            return;
        }
    }

    # check mode
    if ( $Param{Mode} !~ m{ Agent | Customer | Public }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Mode must be either Agent, Customer or Public!',
        );
        return;
    }

    # check if sidebar is enabled
    my $IsActive = $ConfigObject->Get("FAQSideBar::$Param{Mode}::Enabled") || 'No';

    #Set Zoom Action
    my $ZoomAction = ( $Param{Mode} eq 'Agent' ) ? 'AgentFAQIndex' :
        ( $Param{Mode} eq 'Customer' ) ? 'CustomerFAQIndex' :
        ( $Param{Mode} eq 'Public' )   ? 'PublicFAQIndex' : '';

    #Set Home Action
    $Param{HomeAction} = ( $Param{Mode} eq 'Agent' ) ? 'AgentFAQIndex' :
        ( $Param{Mode} eq 'Customer' ) ? 'CustomerFAQIndex' :
        ( $Param{Mode} eq 'Public' )   ? 'PublicFAQIndex' : '';

    #Set Explorer Action
    $Param{ExplorerAction} = ( $Param{Mode} eq 'Agent' ) ? 'AgentFAQExplorer' :
        ( $Param{Mode} eq 'Customer' ) ? 'CustomerFAQExplorer' :
        ( $Param{Mode} eq 'Public' )   ? 'PublicFAQExplorer' : '';

    #Redirect screen
    if ( $Param{Mode} eq 'Customer' ) {
        $ZoomAction = $Param{Action} eq 'CustomerFAQExplorer' ? 'CustomerFAQZoom' : $Param{Action};
    }
    elsif ( $Param{Mode} eq 'Public' ) {
        $ZoomAction = $Param{Action} eq 'PublicFAQExplorer' ? 'PublicFAQZoom' : $Param{Action};
    }
    elsif ( $Param{Mode} eq 'Agent' ) {
        $ZoomAction = $Param{Action} eq 'AgentFAQExplorer' ? 'AgentFAQZoom' : $Param{Action};
    }

    my $Expand = $ConfigObject->Get('FAQSideBar::ExpandSubcategories');

    $Self->AddJSData(
        Key   => 'ExpandSubcategories',
        Value => $Expand,
    );

    # get the valid ids
    my @ValidIDs      = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my %ValidIDLookup = map { $_ => 1 } @ValidIDs;

    my $SidebarInit = 0;

    if ( $IsActive eq 'Yes' ) {
        my %Data = %{ $ConfigObject->Get('FAQSideBar::Articles') };

        CONFIG:
        for my $Config ( keys %Data ) {
            next CONFIG if $Data{$Config}->{Language} ne $Param{Language};

            my @ArticleData = @{ $Data{$Config}->{"Articles$Param{Mode}"} };
            my @Groups      = map { /^(.+?)::/; $1 } @ArticleData;

            if ( $Data{$Config}->{"CustomGroupOrder$Param{Mode}"} ) {    ## nofilter(TidyAll::Plugin::OTOBO::Perl::PerlCritic)
                @Groups = split /\,/, $Data{$Config}->{"CustomGroupOrder$Param{Mode}"};
                @Groups = map {s/^\s+|\s+$//gr} @Groups;
            }

            my %Nested;
            my $ExpandLevelName = '';

            for my $Item (@ArticleData) {
                my @Element = split /::/, $Item;
                my $Data    = \%Nested;

                for my $FAQItem (@Element) {
                    $Data = $Data->{$FAQItem} ||= {};
                }
            }

            my $ProcessLevel;
            $ProcessLevel = sub {

                my ( $HashRef, $LevelName ) = @_;
                return if !$HashRef || ref $HashRef ne 'HASH';

                if ( $HashRef->{ $Param{ItemID} } ) {
                    $ExpandLevelName = $LevelName;
                }

                ITEM:
                for my $Key ( sort keys %{$HashRef} ) {
                    my $CurrentNode = $HashRef->{$Key};

                    if ( keys %{$CurrentNode} ) {
                        $LayoutObject->Block(
                            Name => 'Header',
                            Data => {
                                Header      => $Key,
                                Class       => $Nested{$Key} ? 'oooFAQSidebarHeader' : 'oooFAQSidebarSubHeader',
                                Arrow       => $Nested{$Key} ? ''                    : '<i class="fa fa-chevron-right oooIconSubHeader"></i>',
                                Subcategory => $Key
                            }
                        );

                        $ProcessLevel->( $CurrentNode, $Key );
                    }
                    else {
                        my $ItemID = $Key;

                        my %FAQData = $Kernel::OM->Get('Kernel::System::FAQ')->FAQGet(
                            ItemID     => $ItemID,
                            ItemFields => 0,
                            UserID     => $Param{UserID},
                        );

                        next ITEM if !keys %FAQData;

                        if ( $Param{Mode} ne 'Public' ) {

                            # check user permission
                            my $Permission = $Kernel::OM->Get('Kernel::System::FAQ')->CheckCategoryCustomerPermission(
                                CustomerUser => $Self->{UserLogin},
                                CategoryID   => $FAQData{CategoryID},
                                UserID       => $Self->{UserID},
                            );

                            # get interface state list
                            my $InterfaceStates = $Kernel::OM->Get('Kernel::System::FAQ')->StateTypeList(
                                Types  => $ConfigObject->Get('FAQ::Customer::StateTypes'),
                                UserID => $Self->{UserID},
                            );

                            # permission check
                            if (
                                !$Permission
                                || !$FAQData{Approved}
                                || !$ValidIDLookup{ $FAQData{ValidID} }
                                || !$InterfaceStates->{ $FAQData{StateTypeID} }
                                )
                            {
                                next ITEM;
                            }
                        }
                        else {
                            # get interface state list
                            my $InterfaceStates = $Kernel::OM->Get('Kernel::System::FAQ')->StateTypeList(
                                Types  => $ConfigObject->Get('FAQ::Public::StateTypes'),
                                UserID => $Param{UserID},
                            );

                            # permission check
                            if (
                                !$FAQData{Approved}
                                || !$ValidIDLookup{ $FAQData{ValidID} }
                                || !$InterfaceStates->{ $FAQData{StateTypeID} }
                                )
                            {
                                next ITEM;
                            }
                        }

                        $LayoutObject->Block(
                            Name => 'ArticleLink',
                            Data => {
                                Icon   => $FAQData{Icon} ? decode_base64( $FAQData{Icon} ) : '',
                                ID     => $ItemID,
                                Title  => $FAQData{Title},
                                Action => $ZoomAction,
                                Class  => $Nested{$LevelName} ? '' : 'oooFAQSubHeaderSpacing'
                            },
                        );
                    }
                }
            };

            if ( keys %Nested ) {
                if ( !$SidebarInit ) {
                    $LayoutObject->Block(
                        Name => 'SideBar',
                        Data => \%Param
                    );
                    $SidebarInit++;
                }

                my @TopLevel = $Data{$Config}->{"CustomGroupOrder$Param{Mode}"}
                    ? split( /,/, $Data{$Config}->{"CustomGroupOrder$Param{Mode}"} )
                    : sort keys %Nested;

                GROUP:
                for my $Group (@TopLevel) {
                    $Group =~ s/^\s+|\s+$//g;
                    next GROUP if !$Nested{$Group};
                    $ProcessLevel->( { $Group => $Nested{$Group} }, $Group );
                }
            }

            $Self->AddJSData(
                Key   => 'LevelName',
                Value => $ExpandLevelName,
            );

        }

        if ( $Param{IsAllowed} && $Param{ItemID} ) {
            $LayoutObject->Block(
                Name => 'FAQExplorerLink',
                Data => \%Param
            );
        }

        if ( $ZoomAction ne 'CustomerFAQIndex' && $ZoomAction ne 'PublicFAQIndex' && $ZoomAction ne 'AgentFAQIndex' ) {
            $LayoutObject->Block(
                Name => 'FAQBackHomeLink',
                Data => \%Param
            );
        }

        if ( $Param{Action} eq 'CustomerFAQExplorer' || $Param{Action} eq 'PublicFAQExplorer' || $Param{Action} eq 'AgentFAQExplorer' ) {
            $LayoutObject->Block(
                Name => 'FAQBackHomeBlock',
                Data => \%Param
            );
        }

    }

    my $Output = $LayoutObject->Output(
        TemplateFile => 'FAQ/FAQSideBar',
        Data         => {
            %Param
        },
    );

    return $Output;
}

=head2 FAQTableOfContents()

Shows a table of contents to quick jump to relevant article information.

    $LayoutObject->FAQTableOfContents(
        FAQData         => \%FAQData,
        Mode            => 'Agent'
    );

=cut

sub FAQTableOfContents {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $ParamName (qw(FAQData Mode)) {
        if ( !$Param{$ParamName} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $ParamName!",
            );
            return;
        }
    }

    # check mode
    if ( $Param{Mode} !~ m{ Agent | Customer | Public }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Mode must be either Agent, Customer or Public!',
        );
        return;
    }

    my $MaxDepth = $ConfigObject->Get('FAQTableOfContents::MaxDepth') || 3;
    my %Data     = %{ $Param{FAQData} };

    my @TOCFields = grep { $Data{$_} =~ /\S/ } qw(Field1 Field2 Field3 Field4 Field5 Field6);

    FIELD:
    for my $Field (@TOCFields) {
        my $FieldConfig = $Kernel::OM->Get('Kernel::Config')->Get( 'FAQ::Item::' . $Field );
        next FIELD if !$FieldConfig;
        next FIELD if $FieldConfig->{Show} eq 'internal' && $Param{Mode} ne 'Agent';

        my @SubAnchors = $Data{$Field} =~ m|<h([1-6])[^>]*>(.*?)</h[1-6]>|gi;

        $LayoutObject->Block(
            Name => 'ArticleField',
            Data => {
                Caption => $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $FieldConfig->{Caption} ),
                Field   => $Field
            }
        );

        if (@SubAnchors) {
            my $Count = 1;
            
            NESTED:
            while ( my ( $Level, $Content ) = splice( @SubAnchors, 0, 2 ) ) {
                next NESTED if $Level > $MaxDepth;

                my $Padding = ( $Level - 1 ) * 15; 

                $LayoutObject->Block(
                    Name => 'ArticleAnchor',
                    Data => {
                        Caption => $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $Content ),
                        Field   => $Field,
                        ID      => "$Field-$Count",
                        Level   => $Level,
                        Padding => $Padding,
                    }
                );
                $Count++;
            }
        }
    }    

    my $Output = $LayoutObject->Output(
        TemplateFile => 'FAQ/FAQTableOfContents',
        Data         => {
            %Param
        },
    );

    return $Output;
}

=head2 FAQAdditionalData()

Shows additional data for current item.

    $LayoutObject->FAQAdditionalData(
        FAQData         => \%FAQData,
        Mode            => 'Agent'
    );

=cut

sub FAQAdditionalData {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $FAQObject    = $Kernel::OM->Get('Kernel::System::FAQ');

    for my $ParamName (qw(FAQData Mode)) {
        if ( !$Param{$ParamName} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $ParamName!",
            );
            return;
        }
    }

    # check mode
    if ( $Param{Mode} !~ m{ Agent | Customer | Public }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Mode must be either Agent, Customer or Public!',
        );
        return;
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my %FAQData      = %{ $Param{FAQData} };

    $Param{ExplorerAction} = "$Param{Mode}FAQExplorer";

    # show keywords as search links
    if ( $FAQData{Keywords} ) {

        # replace commas and semicolons
        $FAQData{Keywords} =~ s/,/ /g;
        $FAQData{Keywords} =~ s/;/ /g;

        my @Keywords = split /\s+/, $FAQData{Keywords};
        for my $Keyword (@Keywords) {
            $LayoutObject->Block(
                Name => 'Keywords',
                Data => {
                    Keyword        => $Keyword,
                    ExplorerAction => $Param{ExplorerAction}
                },
            );
        }
    }

    # get voting default option
    my $Voting = $ConfigObject->Get('FAQ::Voting');

    my $TypeName = $Param{Mode} eq 'Public' ? 'public' : 'external';

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => $TypeName,
        UserID => $Param{UserID},
    );

    # get FAQ vote information
    my $VoteData;
    if ($Voting) {
        $VoteData = $FAQObject->VoteGet(
            CreateBy  => $Param{UserID},
            ItemID    => $FAQData{ItemID},
            Interface => $Interface->{StateID},
            IP        => $ParamObject->RemoteAddr(),
            UserID    => $Param{UserID},
        );

        # always displays Votes result even if its 0
        $LayoutObject->Block(
            Name => 'ViewVotes',
            Data => {%FAQData},
        );
    }

    # check if user already voted this FAQ item
    my $AlreadyVoted;
    if ($VoteData) {

        my $ItemChangedSystemTime = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $FAQData{Changed} || '',
            }
        )->ToEpoch();

        my $VoteCreatedSystemTime = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $VoteData->{Created} || '',
            }
        )->ToEpoch();

        if ( $ItemChangedSystemTime <= $VoteCreatedSystemTime ) {
            $AlreadyVoted = 1;
        }
    }

    # output rating stars
    if ($Voting) {

        # get voting config
        my $ShowVotingConfig = $ConfigObject->Get('FAQ::Item::Voting::Show');
        if ( $ShowVotingConfig->{ $Interface->{Name} } ) {

            # check if the user already voted after last change
            if ( !$AlreadyVoted ) {
                $Self->_FAQVoting(
                    FAQData => {%FAQData},
                    Action  => $Param{Action}
                );
            }
        }

        $LayoutObject->FAQRatingStarsShow(
            VoteResult => $FAQData{VoteResult},
            Votes      => $FAQData{Votes},
        );
    }

    # output attachments if any
    my @AttachmentIndex = $FAQObject->AttachmentIndex(
        ItemID     => $FAQData{ItemID},
        ShowInline => 0,
        UserID     => $Param{UserID},
    );

    my $Config = $Param{Config};

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => 'FAQ',
        FieldFilter => $Config->{DynamicField} || {},
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $Value = $DynamicFieldBackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $FAQData{ItemID},
        );

        # get print string for this dynamic field
        my $ValueStrg = $DynamicFieldBackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 250,
            LayoutObject       => $LayoutObject,
        );

        my $Label = $DynamicFieldConfig->{Label};

        $LayoutObject->Block(
            Name => 'FAQDynamicField',
            Data => {
                Label => $Label,
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'FAQDynamicField_' . $DynamicFieldConfig->{Name},
            Data => {
                Label => $Label,
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );
    }

    # output attachments
    if (@AttachmentIndex) {
        $LayoutObject->Block(
            Name => 'AttachmentHeader',
        );
        for my $Attachment (@AttachmentIndex) {
            $LayoutObject->Block(
                Name => 'AttachmentRow',
                Data => {
                    %FAQData,
                    %{$Attachment},
                },
            );
        }
    }

    my $Output = $LayoutObject->Output(
        TemplateFile => 'FAQ/FAQAdditionalData',
        Data         => {
            %Param,
            %FAQData
        },
    );

    return $Output;
}

sub _FAQVoting {
    my ( $Self, %Param ) = @_;

    my %FAQData = %{ $Param{FAQData} };

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'FAQVoting',
        Data => {
            %FAQData,
            Action => $Param{Action}
        },
    );

    # get Voting rates setting
    my $VotingRates = $Kernel::OM->Get('Kernel::Config')->Get('FAQ::Item::Voting::Rates');
    for my $RateValue ( sort { $a <=> $b } keys %{$VotingRates} ) {

        # create data structure for output
        my %Data = (
            Value => $RateValue,
            Title => $VotingRates->{$RateValue},
        );

        $LayoutObject->Block(
            Name => 'FAQVotingRateRow',
            Data => {%Data},
        );
    }

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTOBO project (L<https://otobo.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
