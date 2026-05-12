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

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace FAQ.Agent.Sidebar
 * @memberof FAQ.Agent
 * @author
 * @description
 *      This namespace contains the special module functions for the FAQ Sidebar settings module.
 */
FAQ.Agent.Sidebar = (function (TargetNS) {

    let selectedElement = null;
    const list    = document.getElementById('ItemList');
    const btnUp   = document.getElementById('btnUp');
    const btnDown = document.getElementById('btnDown');

    /**
     * @name Init
     * @memberof FAQ.Agent.Sidebar
     * @function
     * @description
     *      This function initialize the module.
     */
    TargetNS.Init = function () {

        Core.UI.Table.InitTableFilter($('#Filter'), $('#Settings'));        

        $('.BtnEdit').bind('click', function (Event) {
            $("#LangSelection").submit();
            return false;
        });

        $(document).on('click', '.RemoveButton', function() {
            var ButtonID = $(this).attr('id');
            var RemoveID = ButtonID.split('_').pop();
           
            var MaxID = 0;

            $('[id^="Field_Article_"]').each(function() {
                var CurrentID = parseInt($(this).attr('id').split('_').pop());

                if (CurrentID > MaxID) {
                    MaxID = CurrentID;
                }
            });
          
            $("#ArticleCount").val(parseInt(MaxID - 1));

            $('#Field_Article_' + RemoveID).remove();
            $('label[for="Article_' + RemoveID + '"]').remove();           
            syncGroupOrder();
            RebuildListItems();
        });

        $('#BtnAddEntry').on('click', function() {
            AddNewArticle();
        }); 

        $('#btnUp').bind('click', function() {
            moveUp();
        }); 

        $('#btnDown').bind('click', function() {
            moveDown();
        }); 

        $('#BtnReset').bind('click', function() {
            Core.UI.Dialog.ShowDialog({
                Modal: true,
                Title: Core.Language.Translate('Warning'),
                HTML:  Core.Language.Translate('Restoring these settings will erase all data. Are you sure you want to proceed?'),
                PositionTop: '20%',
                PositionLeft: 'Center',
                CloseOnEscape: false,
                CloseOnClickOutside: false,
                Buttons: [
                    {
                        Label: Core.Language.Translate('Close'),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                        },
                        Class: 'CallForAction'
                    },
                    {
                        Label: Core.Language.Translate('Ok'),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                            $("#Subaction").val("Delete");
                            $("#SidebarSettingsForm").submit();
                        },
                        Class: 'CallForAction'
                    }                    
                ]
            });            
        });

        if ( typeof list !== 'undefined' && list ) {
            list.addEventListener('click', (e) => {
                if (e.target.classList.contains('ListItem')) {
                    if (selectedElement) {
                        selectedElement.classList.remove('selected');
                    }
                    
                    selectedElement = e.target;
                    selectedElement.classList.add('selected');
                    
                    updateButtons();
                }
            });        
        }

        GetGroupOrder();

        const observer = new MutationObserver(() => {
            syncGroupOrder();
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true
        });

        $(document).on('blur', 'input', function(e) {
            if (e.target.id && e.target.id.startsWith('Article_') && !e.target.id.includes('Error') && !e.target.id.includes('NextID')) {
                syncGroupOrder();
                RebuildListItems();
            }
        });        

        syncGroupOrder();      
    };

    function moveUp() {
        if (selectedElement && selectedElement.previousElementSibling) {
            list.insertBefore(selectedElement, selectedElement.previousElementSibling);
            updateButtons();
        }
    }

    function moveDown() {
        if (selectedElement && selectedElement.nextElementSibling) {
            list.insertBefore(selectedElement.nextElementSibling, selectedElement);
            updateButtons();
        }
    }

    function updateButtons() {
        if (!selectedElement) return;

        btnUp.disabled = !selectedElement.previousElementSibling;
        btnDown.disabled = !selectedElement.nextElementSibling;      

        selectedElement.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        GetGroupOrder();
    }    

    function GetGroupOrder() {
        const items = document.querySelectorAll('#ItemList .ListItem');
        
        const GroupOrder = Array.from(items)
            .map(item => item.textContent.trim().replace(/,/g, "")) 
            .join(",");

        $('#CustomGroupOrder').val(GroupOrder);
    }   
       
    function cleanName(text) {
        if (!text) return "";
        return text.split('::')[0].trim();
    }

    function syncGroupOrder() {
        const orderInput = document.getElementById('CustomGroupOrder');
        if (!orderInput) return;

        const allArticles = document.querySelectorAll('[id^="Article_"]');
        
        const validArticles = Array.from(allArticles).filter(el => {
            return !el.id.includes('Error'); 
            return !el.id.includes('NextID'); 
        });

        const currentNames = validArticles
            .map(el => cleanName(el.textContent || el.value))
            .filter(name => name !== "");

        let existingOrder = orderInput.value ? orderInput.value.split(',').map(s => s.trim()) : [];

        existingOrder = existingOrder.filter(name => currentNames.includes(name));

        currentNames.forEach(name => {
            if (!existingOrder.includes(name)) {
                existingOrder.push(name);
            }
        });

        orderInput.value = existingOrder.join(',');
    } 

    function RebuildListItems() {
        const orderInput = document.getElementById('CustomGroupOrder');
        const listContainer = document.getElementById('ItemList'); // El <ul> donde están los items
        
        if (!orderInput || !listContainer || !orderInput.value) return;
        const ordenNombres = orderInput.value.split(',').map(s => s.trim());

        const allArticles = Array.from(document.querySelectorAll('[id^="Article_"]'))
            .filter(el => !el.id.includes('Error')).filter(el => !el.id.includes('NextID'));
        listContainer.innerHTML = '';

        ordenNombres.forEach(nombreEnCSV => {
            const articuloEncontrado = allArticles.find(el => {
                const nombreLimpio = (el.textContent || el.value).split('::')[0].trim();
                return nombreLimpio === nombreEnCSV;
            });

            if (articuloEncontrado) {
                const li = document.body.appendChild(document.createElement('li'));
                li.className = 'ListItem';
                li.textContent = nombreEnCSV;
                li.dataset.id = articuloEncontrado.id;             
                listContainer.appendChild(li);
            }
        });

        allArticles.forEach(el => {
            const nombreLimpio = (el.textContent || el.value).split('::')[0].trim();
            if (!ordenNombres.includes(nombreLimpio)) {
                const li = document.createElement('li');
                li.className = 'ListItem';
                li.textContent = nombreLimpio;
                li.dataset.id = el.id;
                listContainer.appendChild(li);
            }
        });
    }

    /**
     * @private
     * @name AddNewArticle
     * @memberof FAQ.Agent.Sidebar
     * @function
     * @param 
     * @description
     *     Function for add new article line.
     */    
    function AddNewArticle() {
        var MaxID = 0;

        $('[id^="Field_Article_"]').each(function() {
            var CurrentID = parseInt($(this).attr('id').split('_').pop());

            if (CurrentID > MaxID) {
                MaxID = CurrentID;
            }
        });

        var NextID = parseInt(MaxID + 1);
        $("#ArticleCount").val(NextID);

        var TemplateHTML = $("#ArticleTemplate").html().replace(/NextID/g, NextID);
        var LastArticle = $('#Field_Article_' + parseInt(MaxID));
        LastArticle.after(TemplateHTML);

        Core.UI.InputFields.Activate("#SidebarSettings");
    }    

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(FAQ.Agent.Sidebar || {}));
