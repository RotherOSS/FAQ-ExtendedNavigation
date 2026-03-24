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

package Kernel::Modules::PublicFAQIndex;

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

    # set UserID to root because in public interface there is no user
    $Self->{UserID} = 1;

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

    # AddJSData for ES
    my $ESActive = $ConfigObject->Get('Elasticsearch::Active');

    $LayoutObject->AddJSData(
        Key   => 'ESActive',
        Value => $ESActive,
    );

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
        next CONFIG if $Data{$Config}->{Language} ne $LayoutObject->{UserLanguage};

        $ItemID = $ParamObject->GetParam( Param => 'ItemID' ) || $Data{$Config}->{DefaultItemID};
        last CONFIG;
    }

    # Render default ItemID
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

    my $Output = $LayoutObject->CustomerHeader(
        Value => $FAQData{Title},
    );

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => 'external',
        UserID => $Self->{UserID},
    );

    # get the valid ids
    my @ValidIDs      = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    my %ValidIDLookup = map { $_ => 1 } @ValidIDs;

    # get interface state list
    my $InterfaceStates = $FAQObject->StateTypeList(
        Types  => $ConfigObject->Get('FAQ::Public::StateTypes'),
        UserID => $Self->{UserID},
    );

    # permission check
    if (
        (
            !$FAQData{Approved}
            || !$ValidIDLookup{ $FAQData{ValidID} }
            || !$InterfaceStates->{ $FAQData{StateTypeID} }
        )
        && $ItemID
        )
    {
        return $LayoutObject->CustomerNoPermission(
            WithHeader => 'yes',
        );
    }
    else {
        $IsAllowed = 1;
    }

    #Get Sidebar info
    $Param{SideBar} = $LayoutObject->FAQSideBar(
        Mode      => 'Public',
        Language  => $LayoutObject->{UserLanguage},
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
            Mode    => 'Public',
            FAQData => \%FAQData
        );

        #Render Addional data widget
        $Param{AdditionalData} = $LayoutObject->FAQAdditionalData(
            Mode        => 'Public',
            FAQData     => \%FAQData,
            UserID      => $Self->{UserID} || 1,
            VoteMessage => '',
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

    # # get the dynamic fields for this screen
    # my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
    #     Valid       => 1,
    #     ObjectType  => 'FAQ',
    #     FieldFilter => $Config->{DynamicField} || {},
    # );

    # my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # DYNAMICFIELD:
    # for my $DynamicFieldConfig ( @{$DynamicField} ) {
    #     next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

    #     my $Value = $DynamicFieldBackendObject->ValueGet(
    #         DynamicFieldConfig => $DynamicFieldConfig,
    #         ObjectID           => $FAQData{ItemID},
    #     );

    #     # get print string for this dynamic field
    #     my $ValueStrg = $DynamicFieldBackendObject->DisplayValueRender(
    #         DynamicFieldConfig => $DynamicFieldConfig,
    #         Value              => $Value,
    #         ValueMaxChars      => 250,
    #         LayoutObject       => $LayoutObject,
    #     );

    #     my $Label = $DynamicFieldConfig->{Label};

    #     $LayoutObject->Block(
    #         Name => 'FAQDynamicField',
    #         Data => {
    #             Label => $Label,
    #             Value => $ValueStrg->{Value},
    #             Title => $ValueStrg->{Title},
    #         },
    #     );

    #     # example of dynamic fields order customization
    #     $LayoutObject->Block(
    #         Name => 'FAQDynamicField_' . $DynamicFieldConfig->{Name},
    #         Data => {
    #             Label => $Label,
    #             Value => $ValueStrg->{Value},
    #             Title => $ValueStrg->{Title},
    #         },
    #     );
    # }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'PublicFAQIndex',
        Data         => {
            %Param,
            %FAQData
        },
    );

    # add footer
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

1;
