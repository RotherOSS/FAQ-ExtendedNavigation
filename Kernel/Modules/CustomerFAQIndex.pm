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

package Kernel::Modules::CustomerFAQIndex;

use strict;
use warnings;
use Kernel::Language qw(Translatable);
use MIME::Base64     qw(decode_base64 encode_base64);

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

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get("FAQ::Frontend::$Self->{Action}");
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $FAQObject    = $Kernel::OM->Get('Kernel::System::FAQ');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $CategoryID = 0;
    my $IsAllowed  = 0;

    # store the last screen overview in session
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    my $Output = $LayoutObject->CustomerHeader(
        Value => '',
    );

    # AddJSData for ES
    my $ESActive = $ConfigObject->Get('Elasticsearch::Active');

    $LayoutObject->AddJSData(
        Key   => 'ESActive',
        Value => $ESActive,
    );

    $Output .= $LayoutObject->CustomerNavigationBar();

    my %Search;
    my %FAQSearch;

    # show search results
    if ( $Self->{Subaction} && $Self->{Subaction} eq 'Search' ) {
        my $SearchName = Translatable("Search") . ":";
        for my $Mode (qw/Keyword What/) {
            my $String = $ParamObject->GetParam( Param => $Mode );
            if ($String) {
                $Search{$Mode}    = $String;
                $FAQSearch{$Mode} = "*$String*";
                my $ModeName = $Mode eq 'What' ? 'Fulltext' : $Mode;
                $SearchName .= " " . Translatable($ModeName) . " \"$String\";";
            }
        }

        # output category root ( done in LayoutObject for non searches )
        $LayoutObject->Block(
            Name => 'FAQPathCategoryElement',
            Data => {
                Name       => $ConfigObject->Get('FAQ::Default::RootCategoryName'),
                CategoryID => 0,
            },
        );

        # output search information
        $LayoutObject->Block(
            Name => 'FAQPathCategoryElementNoLink',
            Data => {
                Name => $SearchName,
            },
        );

        # disable category specific stuff
        $CategoryID = -1;
    }

    # show back link
    $LayoutObject->Block(
        Name => 'Back',
        Data => \%Param,
    );

    #Get default ItemID if it's defined
    my %Data   = %{ $ConfigObject->Get('FAQSideBar::Articles') };
    my $ItemID = '';
    my %FAQData;

    CONFIG:
    for my $Config ( keys %Data ) {
        next CONFIG if $Data{$Config}->{Language} ne $Self->{UserLanguage};

        $ItemID = $ParamObject->GetParam( Param => 'ItemID' ) || $Data{$Config}->{DefaultItemID};
        last CONFIG;
    }

    #Render default ItemID
    if ($ItemID) {
        %FAQData = $FAQObject->FAQGet(
            ItemID        => $ItemID,
            ItemFields    => 1,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );
    }

    #Render a default message if ItemID is invalid
    else {
        $LayoutObject->Block(
            Name => 'DefaultMessage',
            Data => \%Param,
        );
    }

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => 'external',
        UserID => $Self->{UserID},
    );

    # get voting default option
    my $Voting = $ConfigObject->Get('FAQ::Voting');
    $Param{Rate} = $ParamObject->GetParam( Param => 'Rate' );

    # get FAQ vote information
    my $VoteData;
    if ( $Voting && $FAQData{ItemID} ) {
        $VoteData = $FAQObject->VoteGet(
            CreateBy  => $Self->{UserID},
            ItemID    => $FAQData{ItemID},
            Interface => $Interface->{StateID},
            IP        => $ParamObject->RemoteAddr(),
            UserID    => $Self->{UserID},
        );
    }

    # check if user already voted this FAQ item
    my $AlreadyVoted;
    my $VoteMessage;

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

    # ---------------------------------------------------------- #
    # Vote Subaction
    # ---------------------------------------------------------- #
    if ( $Self->{Subaction} eq 'Vote' ) {

        # customer can't use this sub-action if is not enabled
        if ( !$Voting ) {
            $LayoutObject->CustomerFatalError(
                Message => Translatable('The voting mechanism is not enabled!'),
            );
        }

        # user can vote only once per FAQ revision
        if ($AlreadyVoted) {
            $VoteMessage = Translatable('You have already voted!');
        }

        # set the vote if any
        elsif ( defined $Param{Rate} ) {

            # get rates config
            my $VotingRates = $ConfigObject->Get('FAQ::Item::Voting::Rates');
            my $Rate        = $Param{Rate};

            # send error if rate is not defined in config
            if ( !$VotingRates->{$Rate} ) {
                $VoteMessage = Translatable('The vote rate is not defined!');
            }

            # otherwise add the vote
            else {
                $FAQObject->VoteAdd(
                    CreatedBy => $Self->{UserID},
                    ItemID    => $ItemID,
                    IP        => $ParamObject->RemoteAddr(),
                    Interface => $Interface->{StateID},
                    Rate      => $Param{Rate},
                    UserID    => $Self->{UserID},
                );

                # do not show the voting form
                $AlreadyVoted = 1;

                # refresh FAQ item data
                %FAQData = $FAQObject->FAQGet(
                    ItemID     => $ItemID,
                    ItemFields => 1,
                    UserID     => $Self->{UserID},
                );
                if ( !%FAQData ) {
                    return $LayoutObject->CustomerFatalError();
                }

                $VoteMessage = Translatable('Thanks for your vote!');
            }
        }

        # user is able to vote but no rate has been selected
        else {
            $VoteMessage = Translatable('No rate selected!');
        }
    }

    # get the valid ids
    my @ValidIDs      = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my %ValidIDLookup = map { $_ => 1 } @ValidIDs;

    # check user permission
    my $Permission;

    if ( $FAQData{CategoryID} ) {
        $Permission = $FAQObject->CheckCategoryCustomerPermission(
            CustomerUser => $Self->{UserLogin},
            CategoryID   => $FAQData{CategoryID},
            UserID       => $Self->{UserID},
        );
    }

    # get interface state list
    my $InterfaceStates = $FAQObject->StateTypeList(
        Types  => $ConfigObject->Get('FAQ::Customer::StateTypes'),
        UserID => $Self->{UserID},
    );

    # permission check
    if (
        (
            !$Permission
            || !$FAQData{Approved}
            || !$ValidIDLookup{ $FAQData{ValidID} }
            || !$InterfaceStates->{ $FAQData{StateTypeID} }
        )
        && $ItemID
        )
    {
        $IsAllowed = 0;

        #Render a default message if we dont have permission
        $LayoutObject->Block(
            Name => 'DefaultMessage',
            Data => \%Param,
        );
    }
    else {
        $IsAllowed = 1;
    }

    #Get Sidebar info
    $Param{SideBar} = $LayoutObject->FAQSideBar(
        Mode      => 'Customer',
        Language  => $Self->{UserLanguage},
        UserID    => $Self->{UserID},
        IsAllowed => $IsAllowed,
        ItemID    => $ItemID,
        Action    => $Self->{Action}
    );

    # prepare fields data (Still needed for PlainText)
    FIELD:
    for my $Field (qw(Field1 Field2 Field3 Field4 Field5 Field6)) {
        next FIELD if !$FAQData{$Field};

        # rewrite links to embedded images for customer interface
        if ( $Interface->{Name} eq 'external' ) {

            # rewrite handle and action
            $FAQData{$Field}
                =~ s{ index[.]pl [?] Action=AgentFAQZoom }{customer.pl?Action=CustomerFAQZoom}gxms;

            # take care of old style before FAQ 2.0.x
            $FAQData{$Field} =~ s{
                index[.]pl [?] Action=AgentFAQ [&](amp;)? Subaction=Download [&](amp;)?
            }{customer.pl?Action=CustomerFAQZoom;Subaction=DownloadAttachment;}gxms;
        }

        # no quoting if HTML view is enabled
        next FIELD if $ConfigObject->Get('FAQ::Item::HTML');

        # HTML quoting
        $FAQData{$Field} = $LayoutObject->Ascii2Html(
            NewLine        => 0,
            Text           => $FAQData{$Field},
            VMax           => 5000,
            HTMLResultMode => 1,
            LinkFeature    => 1,
        );
    }

    if ( $ItemID && keys %FAQData ) {

        # set voting results
        $Param{VotingResultColor} = $LayoutObject->GetFAQItemVotingRateColor(
            Rate => $FAQData{VoteResult},
        );
    }

    if ( !$Param{VotingResultColor} || $FAQData{Votes} eq '0' ) {
        $Param{VotingResultColor} = 'Gray';
    }

    # show FAQ path
    my $ShowFAQPath = $LayoutObject->FAQPathShow(
        FAQObject   => $FAQObject,
        CategoryID  => $FAQData{CategoryID} || -1,
        PathForItem => 1,
        UserID      => $Self->{UserID},
    );
    if ($ShowFAQPath) {
        $LayoutObject->Block(
            Name => 'FAQPathItemElement',
            Data => {%FAQData},
        );
    }

    # output attachments if any
    if ( $FAQData{ItemID} ) {
        my @AttachmentIndex = $FAQObject->AttachmentIndex(
            ItemID     => $FAQData{ItemID},
            ShowInline => 0,
            UserID     => $Self->{UserID},
        );

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
    }

    # show message about links in iframes, if user didn't close it already
    if ( !$Self->{DoNotShowBrowserLinkMessage} ) {
        $LayoutObject->Block(
            Name => 'BrowserLinkMessage',
        );
    }

    if ( $IsAllowed && keys %FAQData ) {

        #Render Table of Contents
        $Param{TOC} = $LayoutObject->FAQTableOfContents(
            Mode    => 'Customer',
            FAQData => \%FAQData
        );

        #Render Addional data widget
        $Param{AdditionalData} = $LayoutObject->FAQAdditionalData(
            Mode        => 'Customer',
            FAQData     => \%FAQData,
            UserID      => $Self->{UserID},
            VoteMessage => $VoteMessage || '',
            Action      => $Self->{Action},
            Config      => $Config
        );

        $FAQData{Icon} = $FAQData{Icon} ? decode_base64( $FAQData{Icon} ) : '';

        $LayoutObject->Block(
            Name => 'FAQItem',
            Data => {
                %Param,
                %FAQData
            }
        );

        # show FAQ Content
        $LayoutObject->FAQContentShow(
            FAQObject       => $FAQObject,
            InterfaceStates => $InterfaceStates,
            FAQData         => {%FAQData},
            UserID          => $Self->{UserID},
        );
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerFAQIndex',
        Data         => {
            %Param,
            %FAQData
        },
    );
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

1;
