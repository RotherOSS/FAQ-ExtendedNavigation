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

package Kernel::Output::HTML::Layout::FAQExtendedNavigation;

use strict;
use warnings;

# core modules
use List::Util   qw(none);
use MIME::Base64 qw(decode_base64);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

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

Kernel::Output::HTML::Layout::FAQExtendedNavigation - all FAQExtendedNavigation-related HTML functions

=head1 DESCRIPTION

All FAQExtendedNavigation-related HTML functions

=head1 PUBLIC INTERFACE

=head2 FAQSideBar()

Shows a side bar to quick open FAQ articles.

    $LayoutObject->FAQSideBar(
        Mode            => 'Public',                   # (Agent, Customer, Public)
        Language        => $Self->{UserLanguage},
        Interface       => $Self->{Interface},
        UserID          => $Self->{UserID},
    );

=cut

sub FAQSideBar {
    my ( $Self, %Param ) = @_;

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

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $FAQObject    = $Kernel::OM->Get('Kernel::System::FAQ');

    # check if sidebar is enabled and subcategories should be expanded
    my $IsActive = $ConfigObject->Get("FAQSideBar::$Param{Mode}::Enabled") || 'No';
    my $Expand   = $ConfigObject->Get('FAQSideBar::ExpandSubcategories');

    $Self->AddJSData(
        Key   => 'ExpandSubcategories',
        Value => $Expand,
    );

    # set interface specific variables
    my $ZoomAction;
    my $InterfaceStates = {};
    if ( $Param{Mode} eq 'Agent' ) {
        $ZoomAction            = $Param{Action} eq 'AgentFAQExplorer' ? 'AgentFAQZoom' : $Param{Action};
        $Param{HomeAction}     = 'AgentFAQZoom';
        $Param{ExplorerAction} = 'AgentFAQExplorer';
    }
    elsif ( $Param{Mode} eq 'Customer' ) {
        $ZoomAction            = $Param{Action} eq 'CustomerFAQExplorer' ? 'CustomerFAQZoom' : $Param{Action};
        $Param{HomeAction}     = 'CustomerFAQZoom';
        $Param{ExplorerAction} = 'CustomerFAQExplorer';

        $InterfaceStates = $FAQObject->StateTypeList(
            Types  => $ConfigObject->Get('FAQ::Customer::StateTypes'),
            UserID => $Self->{UserID},
        );
    }
    elsif ( $Param{Mode} eq 'Public' ) {
        $ZoomAction            = $Param{Action} eq 'PublicFAQExplorer' ? 'PublicFAQZoom' : $Param{Action};
        $Param{HomeAction}     = 'PublicFAQZoom';
        $Param{ExplorerAction} = 'PublicFAQExplorer';

        $InterfaceStates = $FAQObject->StateTypeList(
            Types  => $ConfigObject->Get('FAQ::Public::StateTypes'),
            UserID => 1,
        );
    }

    # get the valid ids
    my @ValidIDs      = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my %ValidIDLookup = map { $_ => 1 } @ValidIDs;

    my $SidebarInit = 0;
    $Param{IsDefaultArticle}  ||= 0;
    $Param{HasDefaultArticle} ||= 0;

    if ( $IsActive eq 'Yes' ) {
        my %Data = %{ $ConfigObject->Get("$Param{Mode}FAQSideBar::Articles") // {} };

        CONFIG:
        for my $Config ( keys %Data ) {
            next CONFIG if $Data{$Config}->{Language} ne $Param{Language};

            my $QuickLinkConfig = $Data{$Config};

            my %FAQDataAll;
            my %QuickLinkStructure;
            my @Groups;
            my $Prio = 0;

            CONFIGENTRY:
            for my $ConfigEntry ( @{ $Data{$Config}->{"Articles"} // [] } ) {
                my @Element = split /::/, $ConfigEntry;

                my %FAQData = $FAQObject->FAQGet(
                    ItemID     => $Element[-1],
                    ItemFields => 0,
                    UserID     => 1,
                );

                # check category permission for agents and customers
                if ( !exists $Self->{CategoryPermission}{ $FAQData{CategoryID} } ) {
                    if ( $Param{Mode} eq 'Agent' ) {
                        $Self->{CategoryPermission}{ $FAQData{CategoryID} } = $FAQObject->CheckCategoryUserPermission(
                            UserID     => $Self->{UserID},
                            CategoryID => $FAQData{CategoryID},
                            Type       => 'ro',
                        );
                    }
                    elsif ( $Param{Mode} eq 'Customer' ) {
                        $Self->{CategoryPermission}{ $FAQData{CategoryID} } = $FAQObject->CheckCategoryCustomerPermission(
                            CustomerUser => $Self->{UserLogin},
                            CategoryID   => $FAQData{CategoryID},
                            UserID       => $Self->{UserID},
                        );
                    }
                    else {
                        # PublicFAQs are only restricted by state type
                        $Self->{CategoryPermission}{ $FAQData{CategoryID} } = 1;
                    }
                }

                next CONFIGENTRY unless $Self->{CategoryPermission}{ $FAQData{CategoryID} };

                # check faq state type permission for customers and public
                if (
                    $Param{Mode} ne 'Agent' && (
                        !$FAQData{Approved} ||
                        !$ValidIDLookup{ $FAQData{ValidID} } ||
                        !$InterfaceStates->{ $FAQData{StateTypeID} }
                    )
                    )
                {

                    next CONFIGENTRY;
                }

                $FAQDataAll{ $Element[-1] } = \%FAQData;

                # build nested QuickLinkStructure
                {
                    my $Structure = \%QuickLinkStructure;

                    # traverse through the layers, using existing or initializing new hash refs
                    for my $FAQItem (@Element) {
                        $Structure = $Structure->{Nested}{$FAQItem} ||= {Prio => $Prio++};
                    }
                }

                # prepare standard group order
                push @Groups, $Element[0];
            }

            if ( $QuickLinkConfig->{CustomGroupOrder} ) {
                @Groups = split /\,/, $QuickLinkConfig->{CustomGroupOrder};
                @Groups = map {s/^\s+|\s+$//gr} @Groups;
            }

            my $ProcessLevel;
            my $ExpandLevelName = '';
            $ProcessLevel = sub {
                my ( $HashRef, $LevelName ) = @_;

                return if !$HashRef || ref $HashRef ne 'HASH';

                if ( $HashRef->{ $Param{ItemID} } ) {
                    $ExpandLevelName = $LevelName;
                }

                ITEM:
                for my $Key ( sort { $HashRef->{$a}{Prio} <=> $HashRef->{$b}{Prio} } keys %{$HashRef} ) {
                    my $CurrentNode = $HashRef->{$Key};

                    if ( $CurrentNode->{Nested} ) {
                        $LayoutObject->Block(
                            Name => 'Header',
                            Data => {
                                Header      => $Key,
                                Class       => $QuickLinkStructure{Nested}{$Key} ? 'oooFAQSidebarHeader Collapsed' : 'oooFAQSidebarSubHeader Collapsed',
                                Arrow       => '<i class="fa fa-caret-right oooIconSubHeader"></i>',
                                Subcategory => $Key
                            }
                        );

                        $ProcessLevel->( $CurrentNode->{Nested}, $Key );
                    }
                    else {
                        $LayoutObject->Block(
                            Name => 'ArticleLink',
                            Data => {
                                Icon   => $FAQDataAll{$Key}{Icon} ? decode_base64( $FAQDataAll{$Key}{Icon} ) : '',
                                ID     => $Key,
                                Title  => $FAQDataAll{$Key}{Title},
                                Action => $ZoomAction,
                                Class  => $QuickLinkStructure{Nested}{$LevelName} ? '' : 'oooFAQSubHeaderSpacing'
                            },
                        );
                    }
                }
            };

            if ( keys %QuickLinkStructure ) {
                if ( !$SidebarInit ) {
                    $LayoutObject->Block(
                        Name => 'SideBar',
                        Data => \%Param
                    );

                    if ( $Param{Mode} eq 'Agent' ) {
                        $LayoutObject->Block(
                            Name => 'HeaderTitle',
                            Data => {}
                        );
                    }
                    $SidebarInit++;
                }

                GROUP:
                for my $Group (@Groups) {
                    $Group =~ s/^\s+|\s+$//g;

                    next GROUP if !$QuickLinkStructure{Nested}{$Group};

                    $ProcessLevel->( { $Group => $QuickLinkStructure{Nested}{$Group} }, $Group );
                }
            }

            $Self->AddJSData(
                Key   => 'LevelName',
                Value => $ExpandLevelName,
            );

        }

        if ( $Param{ItemID} ) {
            $LayoutObject->Block(
                Name => 'FAQExplorerLink',
                Data => \%Param
            );
        }

        if (
            ( $ZoomAction ne 'CustomerFAQZoom' && $ZoomAction ne 'PublicFAQZoom' && $ZoomAction ne 'AgentFAQZoom' )
            || ( $Param{Action} eq 'CustomerFAQZoom' || $Param{Action} eq 'PublicFAQZoom' || $Param{Action} eq 'AgentFAQZoom' ) && !$Param{IsDefaultArticle}
            )
        {
            if ( $Param{HasDefaultArticle} ) {
                $LayoutObject->Block(
                    Name => 'FAQBackHomeLink',
                    Data => \%Param
                );
            }
        }

        if ( ( $Param{Action} eq 'CustomerFAQExplorer' || $Param{Action} eq 'PublicFAQExplorer' || $Param{Action} eq 'AgentFAQExplorer' ) && $Param{HasDefaultArticle} )
        {
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

    return unless @TOCFields;

    my $SingleFieldMode = 0;

    # Identify if we are in single field mode
    SINGLEFIELD:
    for my $Field (@TOCFields) {
        my $FieldConfig = $Kernel::OM->Get('Kernel::Config')->Get( 'FAQ::Item::' . $Field );
        next SINGLEFIELD if !$FieldConfig;
        next SINGLEFIELD if $FieldConfig->{Show} eq 'internal' && $Param{Mode} ne 'Agent';

        if ( $Data{$Field} ) {
            $SingleFieldMode++;
        }
    }

    $LayoutObject->Block(
        Name => 'ArticleField',
        Data => {}
    );

    FIELD:
    for my $Field (@TOCFields) {
        my $FieldConfig = $Kernel::OM->Get('Kernel::Config')->Get( 'FAQ::Item::' . $Field );
        next FIELD if !$FieldConfig;
        next FIELD if $FieldConfig->{Show} eq 'internal' && $Param{Mode} ne 'Agent';

        my @SubAnchors = $Data{$Field} =~ m|<h([1-6])[^>]*>(.*?)</h[1-6]>|gi;

        return unless ( $SingleFieldMode != 1 || @SubAnchors );

        if ( $SingleFieldMode > 1 ) {
            $LayoutObject->Block(
                Name => 'ArticleFieldParent',
                Data => {
                    Caption => $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $FieldConfig->{Caption} ),
                    Field   => $Field
                }
            );
        }

        if (@SubAnchors) {
            my $Count = 1;

            NESTED:
            while ( my ( $Level, $Content ) = splice( @SubAnchors, 0, 2 ) ) {
                next NESTED if $Level > $MaxDepth;

                my $Padding = 0;

                if ( $SingleFieldMode == 1 && $Count == 1 ) {
                    $Padding = 0;
                }
                elsif ( ( $SingleFieldMode == 1 && $Count > 1 ) || $SingleFieldMode != 1 ) {
                    $Padding = ( $Level - 1 ) * 15;
                }

                $LayoutObject->Block(
                    Name => $SingleFieldMode > 1 ? 'ArticleAnchor' : 'ArticleAnchorSingle',
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
