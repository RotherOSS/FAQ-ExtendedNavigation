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

package Kernel::Modules::AgentFAQSidebar;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

    # Permission check.
    if ( !$Self->{AccessRw} ) {
        return $LayoutObject->NoPermission(
            Message    => Translatable('You need rw permission!'),
            WithHeader => 'yes',
        );
    }

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Get parameters from web request.
    my %GetParam;
    for my $ParamName (qw(SidebarLanguage Language Interface DefaultItemID CustomGroupOrder ConfigID ArticleCount)) {
        $GetParam{$ParamName} = $ParamObject->GetParam( Param => $ParamName );
    }

    #Load defined Languages for the system
    my %SystemLanguages = %{ $ConfigObject->Get('DefaultUsedLanguages') };

    #Load language descriptions
    my %SystemLanguagesNative = %{ $ConfigObject->Get('DefaultUsedLanguagesNative') };

    #Fill hash data for language Dropdown
    for my $Language ( keys %SystemLanguages ) {
        $SystemLanguages{$Language} = "($Language) - $SystemLanguagesNative{$Language}";
    }

    $GetParam{SidebarLanguagesStrg} = $LayoutObject->BuildSelection(
        Data         => \%SystemLanguages,
        Name         => 'SidebarLanguage',
        SelectedID   => $GetParam{SidebarLanguage},
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required ',
        Translatable => 0
    );

    my %Interfaces = (
        'Agent'    => 'Agent',
        'Customer' => 'Customer',
        'Public'   => 'Public'
    );

    $GetParam{InterfacesStrg} = $LayoutObject->BuildSelection(
        Data         => \%Interfaces,
        Name         => 'Interface',
        SelectedID   => $GetParam{Interface},
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required ',
        Translatable => 0
    );

    # ------------------------------------------------------------ #
    # Change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $Self->_Edit(
            Action    => 'Change',
            Languages => \%SystemLanguages,
            %GetParam
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentFAQSidebar',
            Data         => \%Param,
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # Change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        for my $ParamName (qw(Language Interface)) {
            if ( !defined $GetParam{$ParamName} ) {

                return $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate( 'Need %s!', $ParamName ),
                );
            }
        }

        $GetParam{ConfigID} = sprintf( "%03d", $GetParam{ConfigID} );

        my $SettingName = "$GetParam{Interface}FAQSideBar::Articles###$GetParam{ConfigID}";
        my %Error;
        my @Articles;

        my %Config = (
            Language         => $GetParam{Language},
            DefaultItemID    => $GetParam{DefaultItemID},
            CustomGroupOrder => $GetParam{CustomGroupOrder}
        );

        for my $ArticleCount ( 1 .. $GetParam{ArticleCount} ) {
            my $ArticleGroup  = $ParamObject->GetParam( Param => "Article_" . $ArticleCount ) || '';
            my $ArticleItemID = $ParamObject->GetParam( Param => "ItemID_" . $ArticleCount )  || '';

            if ($ArticleGroup) {
                push @Articles, $ArticleGroup . "::" . $ArticleItemID;
            }
        }

        $Config{Articles} = \@Articles;

        my @DeploySettings;

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            Name   => $SettingName,
            Force  => 1,
            UserID => 1,
        );

        return unless $ExclusiveLockGUID;

        my %UpdateResult = $SysConfigObject->SettingUpdate(
            Name              => $SettingName,
            IsValid           => 1,
            EffectiveValue    => \%Config,
            ExclusiveLockGUID => $ExclusiveLockGUID,
            UserID            => 1,
        );

        if ( $UpdateResult{Success} ) {
            push @DeploySettings, $SettingName;
        }

        my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
            Comments      => 'Sidebar setting ' . $SettingName . ' modified by: ' . $Self->{UserLogin},
            UserID        => 1,
            Force         => 1,
            DirtySettings => \@DeploySettings,
        );

        if ( !$DeploymentResult{Success} ) {
            $Error{ $DeploymentResult{Error} } = ' ServerError';
        }

        if (%Error) {

            $Self->_Edit(
                Action    => 'Change',
                Languages => \%SystemLanguages,
                %GetParam,
                %Error,
            );
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AgentFAQSidebar',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();

            return $Output;
        }

        return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Update" );
    }

    # ------------------------------------------------------------ #
    # Delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        for my $ParamName (qw(Language Interface)) {
            if ( !defined $GetParam{$ParamName} ) {

                return $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate( 'Need %s!', $ParamName ),
                );
            }
        }

        $GetParam{ConfigID} = sprintf( "%03d", $GetParam{ConfigID} );

        my $SettingName = "$GetParam{Interface}FAQSideBar::Articles###$GetParam{ConfigID}";

        my @DeploySettings;

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            Name   => $SettingName,
            Force  => 1,
            UserID => 1,
        );

        my $Result = $SysConfigObject->SettingReset(
            Name              => $SettingName,
            ExclusiveLockGUID => $ExclusiveLockGUID,
            UserID            => 1,
        );

        if ($Result) {
            push @DeploySettings, $SettingName;
        }

        my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
            Comments      => 'Sidebar setting ' . $SettingName . ' deleted by: ' . $Self->{UserLogin},
            UserID        => 1,
            Force         => 1,
            DirtySettings => \@DeploySettings,
        );

        my %Error;

        if ( !$DeploymentResult{Success} ) {
            $Error{ $DeploymentResult{Error} } = ' ServerError';
        }

        if (%Error) {

            $Self->_Edit(
                Action    => 'Change',
                Languages => \%SystemLanguages,
                %GetParam,
                %Error,
            );
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AgentFAQSidebar',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();

            return $Output;
        }

        return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Reset" );
    }

    # ---------------------------------------------------------- #
    # Overview
    # ---------------------------------------------------------- #
    else {

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        my $Notification     = $ParamObject->GetParam( Param => 'Notification' ) || '';
        my %NotificationText = (
            Update => Translatable('Settings successfully updated!'),
            Reset  => Translatable('Settings successfully reset!'),
        );
        if ( $Notification && $NotificationText{$Notification} ) {
            $Output .= $LayoutObject->Notify( Info => $NotificationText{$Notification} );
        }

        $Self->_Overview(
            %Param,
            %GetParam,
            SystemLanguages => \%SystemLanguages
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentFAQSidebar',
            Data         => {
                %Param,
                %GetParam,
            },
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %AgentData    = %{ $ConfigObject->Get('AgentFAQSideBar::Articles') };
    my %CustomerData = %{ $ConfigObject->Get('CustomerFAQSideBar::Articles') };
    my %PublicData   = %{ $ConfigObject->Get('PublicFAQSideBar::Articles') };

    my %SelectedData = $Param{Interface} eq 'Agent'
        ? %AgentData
        : $Param{Interface} eq 'Customer' ? %CustomerData
        :                                   %PublicData;

    my %InterfaceData;
    my $ConfigID;
    my $ConfigLimit = int( keys %SelectedData );
    my $ConfigCount = 0;
    my $NextConfig  = 0;
    $Param{SidebarLanguage} ||= '';

    CONFIG:
    for my $Config ( sort keys %SelectedData ) {

        # Collect the count of configurations with language defined
        if ( $SelectedData{$Config}->{Language} ) {
            $ConfigCount++;
        }
        else {
            $NextConfig = $NextConfig == 0 ? int($Config) : $NextConfig;
        }

        next CONFIG if $SelectedData{$Config}->{Language} ne $Param{SidebarLanguage};

        %InterfaceData = %{ $SelectedData{$Config} };
        $InterfaceData{Language} ||= $Param{SidebarLanguage};
        $ConfigID = int($Config);
        last CONFIG;
    }

    if ( $ConfigCount == $ConfigLimit && !$ConfigID ) {
        return $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Language configuration limit reached for the interface: %s!', $Param{Interface} ),
        );
    }
    elsif ( $ConfigCount < $ConfigLimit && !$ConfigID ) {
        $ConfigID = $NextConfig;
    }

    my @CustomGroupOrder;

    if ( $InterfaceData{CustomGroupOrder} ) {
        @CustomGroupOrder = split /,/, $InterfaceData{CustomGroupOrder};
    }
    else {
        my %OrderItems;

        for my $Article ( @{ $InterfaceData{Articles} } ) {
            my @Content = split /::/, $Article;
            $OrderItems{ $Content[0] } = 1;
        }

        @CustomGroupOrder = sort keys %OrderItems;
    }

    @CustomGroupOrder = map {s/^\s+|\s+$//gr} @CustomGroupOrder;
    my $Action = 'Edit';

    if ( !$InterfaceData{Language} ) {
        $Action = 'Add';
        $InterfaceData{Language} = $Param{SidebarLanguage};
    }

    my %FAQSearchParameter;
    my $SearchLimit = $ConfigObject->Get('FAQ::KeywordArticeList::SearchLimit');
    my @Languages   = keys %{ $Param{Languages} };

    my @LanguageIDs;
    my %FAQArticles;

    LANGUAGENAME:
    for my $LanguageName (@Languages) {
        next LANGUAGENAME if !$LanguageName;

        my $LanguageID = $Kernel::OM->Get('Kernel::System::FAQ')->LanguageLookup(
            Name => $LanguageName,
        );

        next LANGUAGENAME if !$LanguageID;
        push @LanguageIDs, $LanguageID;
    }

    if (@Languages) {
        $FAQSearchParameter{LanguageIDs} = \@LanguageIDs;
    }

    # Get the relevant FAQ articles.
    my @FAQArticleIDs = $Kernel::OM->Get('Kernel::System::FAQ')->FAQSearch(
        %FAQSearchParameter,
        OrderBy          => ['FAQID'],
        OrderByDirection => ['Down'],
        Limit            => $SearchLimit,
        UserID           => 1,
    );

    for my $ItemID (@FAQArticleIDs) {
        my %FAQ = $Kernel::OM->Get('Kernel::System::FAQ')->FAQGet(
            ItemID        => $ItemID,
            ItemFields    => 0,
            DynamicFields => 0,
            UserID        => 1,
        );

        $FAQArticles{$ItemID} = "[$FAQ{Language}] $FAQ{Title}";
    }

    $Param{DefaultItemIDStrg} = $LayoutObject->BuildSelection(
        Data         => \%FAQArticles,
        Name         => 'DefaultItemID',
        SelectedID   => $InterfaceData{DefaultItemID},
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required ',
        Translatable => 0
    );

    $Param{ItemNextIDStrg} = $LayoutObject->BuildSelection(
        Data         => \%FAQArticles,
        Name         => 'ItemID_NextID',
        SelectedID   => 0,
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required ',
        Translatable => 0
    );

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );
    $LayoutObject->Block(
        Name => 'ActionList',
        Data => {},
    );
    $LayoutObject->Block(
        Name => 'ActionOverview',
        Data => \%Param
    );
    $LayoutObject->Block(
        Name => 'Hint',
        Data => {},
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %InterfaceData,
            ArticleCount => int( @{ $InterfaceData{Articles} } ) || 1,
            ConfigID     => $ConfigID                            || ''
        },
    );

    if (@CustomGroupOrder) {
        my $CountOrder = 1;

        for my $GroupName (@CustomGroupOrder) {
            $LayoutObject->Block(
                Name => 'CustomGroupOrderItems',
                Data => {
                    Order   => $CountOrder,
                    Content => $GroupName
                },
            );
            $CountOrder++;
        }
    }

    my $Count = 1;

    if ( @{ $InterfaceData{Articles} } > 0 ) {
        for my $Article ( @{ $InterfaceData{Articles} } ) {

            my @Content = $Article =~ /^(.*)::(\d+)$/;

            $Param{ItemIDStrg} = $LayoutObject->BuildSelection(
                Data         => \%FAQArticles,
                Name         => 'ItemID_' . $Count,
                SelectedID   => $Content[1],
                PossibleNone => 1,
                Class        => 'Modernize Validate_Required ',
                Translatable => 0
            );

            $LayoutObject->Block(
                Name => 'OverviewRowArticle',
                Data => {
                    Count      => $Count,
                    Content    => $Content[0],
                    ItemIDStrg => $Param{ItemIDStrg}
                },
            );
            $Count++;
        }
    }
    else {

        $Param{ItemIDStrg} = $LayoutObject->BuildSelection(
            Data         => \%FAQArticles,
            Name         => 'ItemID_1',
            SelectedID   => 0,
            PossibleNone => 1,
            Class        => 'Modernize Validate_Required ',
            Translatable => 0
        );

        $LayoutObject->Block(
            Name => 'OverviewRowArticle',
            Data => {
                Count      => 1,
                Content    => "",
                ItemIDStrg => $Param{ItemIDStrg}
            },
        );
    }

    $LayoutObject->Block(
        Name => 'Header',
        Data => {
            Action => $Action || '',
        },
    );

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %AgentData    = %{ $ConfigObject->Get('AgentFAQSideBar::Articles') };
    my %CustomerData = %{ $ConfigObject->Get('CustomerFAQSideBar::Articles') };
    my %PublicData   = %{ $ConfigObject->Get('PublicFAQSideBar::Articles') };
    my @Data;

    my %SystemLanguages = %{ $Param{SystemLanguages} };

    CONFIG_AGENT:
    for my $Interface (qw(Agent Customer Public)) {
        my %SelectedData = $Interface eq 'Agent'
            ? %AgentData
            : $Interface eq 'Customer' ? %CustomerData
            :                            %PublicData;

        CONFIG:
        for my $Config ( sort keys %SelectedData ) {
            next CONFIG if !$SelectedData{$Config}->{Language};

            my %FAQ;

            if ( $SelectedData{$Config}->{DefaultItemID} ) {
                %FAQ = $Kernel::OM->Get('Kernel::System::FAQ')->FAQGet(
                    ItemID        => $SelectedData{$Config}->{DefaultItemID},
                    ItemFields    => 0,
                    DynamicFields => 0,
                    UserID        => 1,
                );
            }

            push @Data, {
                Interface           => $Interface,
                ConfigID            => int($Config),
                Language            => $SelectedData{$Config}->{Language},
                LanguageDescription => $SystemLanguages{ $SelectedData{$Config}->{Language} },
                DefaultItemID       => $SelectedData{$Config}->{DefaultItemID},
                FAQTitle            => $FAQ{Title} || ''
            };
        }
    }

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {},
    );
    $LayoutObject->Block(
        Name => 'Filter',
        Data => {},
    );
    $LayoutObject->Block(
        Name => 'ActionList',
        Data => {},
    );
    $LayoutObject->Block(
        Name => 'ActionLanguage',
        Data => \%Param
    );
    $LayoutObject->Block(
        Name => 'HintOverview',
        Data => \%Param
    );
    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param
    );

    if (@Data) {
        for my $Setting (@Data) {
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    %{$Setting}
                }
            );
        }
    }

    # Otherwise a no data found message is displayed.
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
        );
    }

    return 1;
}

1;
