// --
// OTOBO is a web-based ticketing system for service organisations.
// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
// --
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
// --

"use strict";

var FAQ = FAQ || {};
FAQ.ExtendedNavigation = FAQ.ExtendedNavigation || {};

/**
 * @namespace
 * @exports TargetNS as FAQ.ExtendedNavigation.FAQ
 * @description
 *      This namespace contains the special module functions for FAQ Extended Navigation Package.
 */
FAQ.ExtendedNavigation.FAQ = (function (TargetNS) {

    /**
     * @name Init
     * @memberof FAQ.ExtendedNavigation.FAQ
     * @function
     * @description
     *      This function initialize the Tags ExtendedNavigation FAQ Module.
     */
    TargetNS.Init = function() {

        /* SVG Icon upload for FAQ articles */
        const FileInput = document.getElementById('IconUpload');

        if ( FileInput !== null ) {

            $("#BtnUploadIcon").bind("click", function() {
                $("#IconUpload").trigger("click");
                $("#BtnUploadIcon").trigger("blur");
            });

            $("#BtnDeleteIcon").bind("click", function() {
                $("#Icon").val("");
                $("#IconPreview").css("background-image", "none");
            });

            FileInput.addEventListener('change', function(e) {
                const File = e.target.files[0];

                if (File && File.type === "image/svg+xml") {
                    const Lector = new FileReader();

                    Lector.onload = function(evt) {
                        const contentSVG = evt.target.result;             
                        loadIconFile(contentSVG);
                    };

                    Lector.readAsText(File);
                }
            });    

            // Load existing icon if available
            const ExistingIconValue = $("#Icon").val();
            
            if ( ExistingIconValue.length > 0 ) {
                const svgText = atob(ExistingIconValue);
                loadIconFile(svgText);
            }

        }

        $(".BackTop").bind("click", function() {
            window.scrollTo({top: 0, behavior: 'smooth'})
        });

        // Create observer to check if Navbar and FAQ Sidebar overlaps

        const targetNode = document.querySelector('#oooNavigation');

        if ( targetNode ) {
            const observer = new MutationObserver((mutationsList) => {
                for (let mutation of mutationsList) {
                    if (mutation.attributeName === 'class') {
                        const isExpanded = targetNode.classList.contains('oooExpanded');
        
                        if (isExpanded) {
                            setTimeout(function() {
                                let OverLap = checkOverlap(targetNode, document.querySelector('.SidebarArea'));

                                if ( OverLap ) {
                                    $("#FAQSidebar").css("opacity", "0.1");
                                }
                            }, 100);
                        } else {
                                $("#FAQSidebar").css("opacity", "1");
                        }
                    }
                }
            });

            observer.observe(targetNode, { attributes: true });
        }

        document.querySelectorAll('.oooFAQSidebarSubHeader').forEach(header => {
            header.addEventListener('click', () => {
                header.classList.toggle('Expanded');
                header.classList.toggle('Collapsed');
                $("i.oooIconSubHeader", $(header)).toggleClass('fa-caret-right fa-caret-down');
                
                let next = header.nextElementSibling;
                while (next && next.classList.contains('oooFAQSidebarArticle')) {
                    next.classList.toggle('ooo-is-visible');
                    next = next.nextElementSibling;
                }
            });
        });

        $( document ).ready(function() {
            if ( Core.Config.Get('ExpandSubcategories') == "Yes" ) {
                $("oooFAQSidebar .fa-chevron-right").trigger("click");
            } else if ( Core.Config.Get('LevelName') != "" ) {
                $('[data-name="'+ escapeString(Core.Config.Get('LevelName')) + '"]').trigger("click");
            }
        });
       
    };

    /**
     * @name escapeString
     * @memberof FAQ.ExtendedNavigation.FAQ
     * @function
     * @description
     *      This function escape string content for Jquery fields.
     */

    function escapeString(str) {
        if ( typeof str == 'undefined' ) {
            return '';
        }

        return str.replace(/[!"#$%&'()*+,.\/:;<=>?@[\\\]^`{|}~]/g, "\\$&");
    }

    /**
     * @name loadIconFile
     * @memberof FAQ.ExtendedNavigation.FAQ
     * @function
     * @description
     *      This function load icon file in container.
     */

    function loadIconFile(svgText) {
        const IconPreview = document.getElementById('IconPreview');
        const base64SVG = btoa(svgText);
        $("#Icon").val(base64SVG);
        IconPreview.style.backgroundImage = `url('data:image/svg+xml;base64,${base64SVG}')`;
    }

    /**
     * @name getFAQArticles
     * @memberof FAQ.ExtendedNavigation.FAQ
     * @function
     * @description
     *      This function return FAQ articles allowed to be mentioned for the current user.
     */
    TargetNS.getFAQArticles = function(queryText) {
        
        return new Promise((resolve) => {
            const Data = { 
                Action:    'AgentFAQAutoComplete',
                Subaction: 'GetFAQItems',
                Query:     encodeURIComponent(queryText),
                Marker:    encodeURIComponent('#'),
                UserID:    1,
                Limit:     20, 
            };

            const URL = Core.Config.Get('Baselink');

            Core.AJAX.FunctionCall(URL, Data, function (Result) {
                if (Result && Result.length > 0) {
                    resolve(Result);
                } else {
                    resolve([]);
                }
            });
        })
        .then((Result) => {
            const ValueData = [];
            
            $.each(Result, function () {
                ValueData.push({
                    id:      this.id,
                    text:    this.text,
                    item_id: this.item_id,  // eslint-disable-line camelcase
                    link:    this.link
                });
            });

            return ValueData;
        });        
    };

    /**
     * @name anchorFrameScroll
     * @memberof FAQ.ExtendedNavigation.FAQ
     * @function
     * @description
     *      This function do scroll to Iframe anchor.
     */
    TargetNS.anchorFrameScroll = function(FieldID, ID) {
        document.getElementById(FieldID).contentWindow.document.getElementById(ID).scrollIntoView();
    }    

    /**
     * @private
     * @name checkOverlap
     * @memberof Core.Customer
     * @function
     * @returns {Boolean} Returns true.
     * @description
     *      This function check if two elements overlaps (for checking sidebar overlapping).
     */
    function checkOverlap(el1, el2) {
        const coord1 = el1.getBoundingClientRect();
        const coord2 = el2.getBoundingClientRect();

        const overlap = !(
            coord1.right < coord2.left || 
            coord1.left > coord2.right || 
            coord1.bottom < coord2.top || 
            coord1.top > coord2.bottom
        );

        return overlap;
    }    

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(FAQ.ExtendedNavigation.FAQ || {}));
