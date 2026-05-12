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

package Kernel::Modules::CustomerFAQZoom;

use strict;
use warnings;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

# Rother OSS / FAQ Extended Navigation Package
use MIME::Base64 qw(decode_base64 encode_base64);

# EO Rother OSS / FAQ Extended Navigation Package

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    if ( !defined $Self->{DoNotShowBrowserLinkMessage} ) {
        my %UserPreferences = $Kernel::OM->Get('Kernel::System::CustomerUser')->GetPreferences(
            UserID => $Self->{UserID},
        );

        if ( $UserPreferences{UserCustomerDoNotShowBrowserLinkMessage} ) {
            $Self->{DoNotShowBrowserLinkMessage} = 1;
        }
        else {
            $Self->{DoNotShowBrowserLinkMessage} = 0;
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    my %GetParam;
    $GetParam{ItemID} = $ParamObject->GetParam( Param => 'ItemID' );
    $GetParam{Rate}   = $ParamObject->GetParam( Param => 'Rate' );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Rother OSS / FAQ Extended Navigation Package
    #Get default ItemID if it's defined
    my $IsDefaultArticle  = 0;
    my $HasDefaultArticle = 0;
    my %Data              = %{ $Kernel::OM->Get('Kernel::Config')->Get('CustomerFAQSideBar::Articles') };
    $Self->{UserLanguage} ||= 'en';

    CONFIG:
    for my $Config ( keys %Data ) {
        next CONFIG if $Data{$Config}->{Language} ne $LayoutObject->{UserLanguage};

        if ( $Data{$Config}->{DefaultItemID} ) {
            if ( !$GetParam{ItemID} ) {
                $GetParam{ItemID} = $Data{$Config}->{DefaultItemID};
                $IsDefaultArticle = 1;
            }
            $HasDefaultArticle = 1;
            last CONFIG;
        }
    }

    # EO Rother OSS / FAQ Extended Navigation Package

    # save, if browser link message was closed
    if ( $Self->{Subaction} eq 'BrowserLinkMessage' ) {

        $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => 'UserCustomerDoNotShowBrowserLinkMessage',
            Value  => 1,
        );

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => 1,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # Rother OSS / FAQ Extended Navigation Package
    # Show message and link to FAQ Explorer if no default item is set and no ItemID provided
    my $Output;

    if ( !$GetParam{ItemID} ) {
        $Output = $LayoutObject->CustomerHeader();
        $Output .= $LayoutObject->CustomerNavigationBar();

        $Param{CssClassNoArticle} = 'Hidden';

        $LayoutObject->Block(
            Name => 'NoDefaultItem',
            Data => {%Param},
        );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'CustomerFAQZoom',
            Data         => {
                %GetParam,
                %Param,
            },
        );

        return $Output . $LayoutObject->CustomerFooter();
    }

    # EO Rother OSS / FAQ Extended Navigation Package

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    my %FAQData = $FAQObject->FAQGet(
        ItemID        => $GetParam{ItemID},
        ItemFields    => 1,
        UserID        => $Self->{UserID},
        DynamicFields => 1,
    );
    if ( !%FAQData ) {
        return $LayoutObject->CustomerFatalError();
    }

    # Rother OSS / FAQ Extended Navigation Package
    $FAQData{Icon} = $FAQData{Icon} ? decode_base64( $FAQData{Icon} ) : '';

    # EO Rother OSS / FAQ Extended Navigation Package

    # get the valid ids
    my @ValidIDs      = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my %ValidIDLookup = map { $_ => 1 } @ValidIDs;

    # check user permission
    my $Permission = $FAQObject->CheckCategoryCustomerPermission(
        CustomerUser => $Self->{UserLogin},
        CategoryID   => $FAQData{CategoryID},
        UserID       => $Self->{UserID},
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get interface state list
    my $InterfaceStates = $FAQObject->StateTypeList(
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
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # store the last screen in session
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenView',
        Value     => $Self->{RequestedURL},
    );

    # ---------------------------------------------------------- #
    # HTMLView Subaction
    # ---------------------------------------------------------- #
    if ( $Self->{Subaction} eq 'HTMLView' ) {

        # get params
        my $Field = $ParamObject->GetParam( Param => "Field" );

        for my $Needed (qw( ItemID Field )) {
            if ( !$Needed ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Needed Param: $Needed!",
                );
                return;
            }
        }

        # get the Field content
        my $FieldContent = $FAQObject->ItemFieldGet(
            ItemID => $GetParam{ItemID},
            Field  => $Field,
            UserID => $Self->{UserID},
        );

        # rewrite handle and action
        $FieldContent
            =~ s{ index[.]pl [?] Action=AgentFAQZoom }{customer.pl?Action=CustomerFAQZoom}gxms;

        # take care of old style before FAQ 2.0.x
        $FieldContent =~ s{
            index[.]pl [?] Action=AgentFAQ [&](amp;)? Subaction=Download [&](amp;)?
        }{customer.pl?Action=CustomerFAQZoom;Subaction=DownloadAttachment;}gxms;

        # build base URL for inline images
        my $SessionID = '';
        if ( $Self->{SessionID} && !$Self->{SessionIDCookie} ) {
            $SessionID = ';' . $Self->{SessionName} . '=' . $Self->{SessionID};
            $FieldContent =~ s{
                (Action=CustomerFAQZoom;Subaction=DownloadAttachment;ItemID=\d+;FileID=\d+)
            }{$1$SessionID}gmsx;
        }

        my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

        # convert content to HTML if needed
        if (
            $Kernel::OM->Get('Kernel::Config')->Get('FAQ::Item::HTML')
            && $LayoutObject->{BrowserRichText}
            && $FAQData{ContentType} ne 'text/html'
            )
        {
            $FieldContent = $HTMLUtilsObject->ToHTML(
                String => $FieldContent,
            ) || '';
        }

        # Detect all plain text links and put them into an HTML <a> tag.
        $FieldContent = $HTMLUtilsObject->LinkQuote(
            String => $FieldContent,
        );

        # Rother OSS / FAQ Extended Navigation Package
        # set target="_parent" for links to other articles via mention
        $FieldContent = $FAQObject->LinkQuoteMention(
            String => $FieldContent,
        );

        # EO Rother OSS / FAQ Extended Navigation Package

        # Set target="_blank" attribute to all HTML <a> tags the LinkQuote function needs to be
        #   called again
        $FieldContent = $HTMLUtilsObject->LinkQuote(
            String    => $FieldContent,
            TargetAdd => 1,
        );

        # add needed HTML headers
        $FieldContent = $HTMLUtilsObject->DocumentComplete(
            String            => $FieldContent,
            Charset           => 'utf-8',
            CustomerInterface => 1,
            CustomerUIStyles  => 1,
        );

        # Rother OSS / FAQ Extended Navigation Package
        my $Count = 0;
        $FieldContent =~ s{(<h([1-6])>.*?</h\2>)}{ $Count++; "<a id=\"$Field-$Count\">&nbsp;</a>$1"}ge;

        # EO FAQ Extended Navigation Package

        # return complete HTML as an attachment
        return $LayoutObject->Attachment(
            Type        => 'inline',
            ContentType => 'text/html',
            Content     => $FieldContent,
        );
    }

    # ---------------------------------------------------------- #
    # DownloadAttachment Subaction
    # ---------------------------------------------------------- #
    if ( $Self->{Subaction} eq 'DownloadAttachment' ) {

        # manage parameters
        $GetParam{FileID} = $ParamObject->GetParam( Param => 'FileID' );
        if ( !defined $GetParam{FileID} ) {
            return $LayoutObject->CustomerFatalError(
                Message => Translatable('Need FileID!'),
            );
        }

        # get attachments
        my %File = $FAQObject->AttachmentGet(
            ItemID => $GetParam{ItemID},
            FileID => $GetParam{FileID},
            UserID => $Self->{UserID},
        );
        if (%File) {
            return $LayoutObject->Attachment(%File);
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Message  => "No such attachment ($GetParam{FileID})! May be an attack!!!",
                Priority => 'error',
            );
            return $LayoutObject->CustomerFatalError();
        }
    }

    $Output .= $LayoutObject->CustomerHeader(
        Value => $FAQData{Title},
    );

    # AddJSData for ES
    my $ESActive = $ConfigObject->Get('Elasticsearch::Active');

    $LayoutObject->AddJSData(
        Key   => 'ESActive',
        Value => $ESActive,
    );

    $Output .= $LayoutObject->CustomerNavigationBar();

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => 'external',
        UserID => $Self->{UserID},
    );

    # get voting default option
    my $Voting = $ConfigObject->Get('FAQ::Voting');

    # get FAQ vote information
    my $VoteData;
    if ($Voting) {
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

    # Rother OSS / FAQ Extended Navigation Package
    my $VoteMessage;

    # EO Rother OSS / FAQ Extended Navigation Package

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

            # Rother OSS / FAQ Extended Navigation Package
            $VoteMessage = Translatable('The voting mechanism is not enabled!');

            # EO Rother OSS / FAQ Extended Navigation Package
        }

        # user can vote only once per FAQ revision
        if ($AlreadyVoted) {

            # Rother OSS / FAQ Extended Navigation Package
            $VoteMessage = Translatable('You have already voted!');

            # EO Rother OSS / FAQ Extended Navigation Package
        }

        # set the vote if any
        elsif ( defined $GetParam{Rate} ) {

            # get rates config
            my $VotingRates = $ConfigObject->Get('FAQ::Item::Voting::Rates');
            my $Rate        = $GetParam{Rate};

            # send error if rate is not defined in config
            if ( !$VotingRates->{$Rate} ) {

                # Rother OSS / FAQ Extended Navigation Package
                $VoteMessage = Translatable('The vote rate is not defined!');

                # EO Rother OSS / FAQ Extended Navigation Package
            }

            # otherwise add the vote
            else {
                $FAQObject->VoteAdd(
                    CreatedBy => $Self->{UserID},
                    ItemID    => $GetParam{ItemID},
                    IP        => $ParamObject->RemoteAddr(),
                    Interface => $Interface->{StateID},
                    Rate      => $GetParam{Rate},
                    UserID    => $Self->{UserID},
                );

                # do not show the voting form
                $AlreadyVoted = 1;

                # refresh FAQ item data
                %FAQData = $FAQObject->FAQGet(
                    ItemID     => $GetParam{ItemID},
                    ItemFields => 1,
                    UserID     => $Self->{UserID},
                );

                # Rother OSS / FAQ Extended Navigation Package
                $FAQData{Icon} = $FAQData{Icon} ? decode_base64( $FAQData{Icon} ) : '';

                # EO Rother OSS / FAQ Extended Navigation Package

                if ( !%FAQData ) {
                    return $LayoutObject->CustomerFatalError();
                }

                # Rother OSS / FAQ Extended Navigation Package
                $VoteMessage = Translatable('Thanks for your vote!');

                # EO Rother OSS / FAQ Extended Navigation Package
            }
        }

        # user is able to vote but no rate has been selected
        else {
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Info     => Translatable('No rate selected!'),
            );
        }
    }

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

    # set voting results
    $Param{VotingResultColor} = $LayoutObject->GetFAQItemVotingRateColor(
        Rate => $FAQData{VoteResult},
    );

    if ( !$Param{VotingResultColor} || $FAQData{Votes} eq '0' ) {
        $Param{VotingResultColor} = 'Gray';
    }

    # show back link
    $LayoutObject->Block(
        Name => 'Back',
        Data => \%Param,
    );

    # get multi-language default option
    my $MultiLanguage = $ConfigObject->Get('FAQ::MultiLanguage');

    # show language
    if ($MultiLanguage) {
        $LayoutObject->Block(
            Name => 'Language',
            Data => {%FAQData},
        );
    }

    # show FAQ path
    my $ShowFAQPath = $LayoutObject->FAQPathShow(
        FAQObject   => $FAQObject,
        CategoryID  => $FAQData{CategoryID},
        PathForItem => 1,
        UserID      => $Self->{UserID},
    );
    if ($ShowFAQPath) {
        $LayoutObject->Block(
            Name => 'FAQPathItemElement',
            Data => {%FAQData},
        );
    }

    # show message about links in iframes, if user didn't close it already
    if ( !$Self->{DoNotShowBrowserLinkMessage} ) {
        $LayoutObject->Block(
            Name => 'BrowserLinkMessage',
        );
    }

    # show FAQ Content
    $LayoutObject->FAQContentShow(
        FAQObject       => $FAQObject,
        InterfaceStates => $InterfaceStates,
        FAQData         => {%FAQData},
        UserID          => $Self->{UserID},

        # Rother OSS / FAQ Extended Navigation Package
        Zoom => 1

        # EO Rother OSS / FAQ Extended Navigation Package
    );

    # log access to this FAQ item
    $FAQObject->FAQLogAdd(
        ItemID    => $GetParam{ItemID},
        Interface => $Interface->{Name},
        UserID    => $Self->{UserID},
    );

    # get config of frontend module
    my $Config = $ConfigObject->Get("FAQ::Frontend::$Self->{Action}");

    #Rother OSS / FAQ Extended Navigation Package
    #Get Sidebar info
    $Param{SideBar} = $LayoutObject->FAQSideBar(
        Mode              => 'Customer',
        Language          => $Self->{UserLanguage},
        UserID            => $Self->{UserID},
        IsAllowed         => 1,
        ItemID            => $GetParam{ItemID},
        Action            => $Self->{Action},
        IsDefaultArticle  => $IsDefaultArticle,
        HasDefaultArticle => $HasDefaultArticle
    );

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

    # EO FAQ Extended Navigation Package

    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerFAQZoom',
        Data         => {
            %FAQData,
            %GetParam,
            %Param,
        },
    );
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

sub _FAQVoting {
    my ( $Self, %Param ) = @_;

    my %FAQData = %{ $Param{FAQData} };

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'FAQVoting',
        Data => {%FAQData},
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
