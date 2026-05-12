.. toctree::
    :maxdepth: 2
    :caption: Contents

Sacrifice to Sphinx
===================

Description
===========
Packages for greater experience of use in the FAQ module.

System requirements
===================

Framework
---------
OTOBO 11.0.x

Packages
--------
FAQ 11.0.10

Third-party software
--------------------
\-

Usage
=====

Setup
-----

Configuration Reference
-----------------------

Frontend::Agent::ModuleRegistration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Frontend::Module###AgentFAQAutoComplete
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the agent interface.

Frontend::Module###AgentFAQSidebar
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the agent interface.

Frontend::Agent::ModuleRegistration::Loader
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Loader::Module::AgentFAQAdd###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the agent interface.

Loader::Module::AgentFAQEdit###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the agent interface.

Loader::Module::AgentFAQExplorer###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the agent interface.

Loader::Module::AgentFAQSidebar###002-FAQ
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the agent interface.

Loader::Module::AgentFAQZoom###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the agent interface.

Frontend::Agent::ModuleRegistration::MainMenu
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Frontend::Navigation###AgentFAQSidebar###002-FAQ
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Main menu item registration.

Frontend::Navigation###AgentFAQZoom###002-FAQ
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Main menu item registration.

Frontend::Base::FAQSideBar
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

AgentFAQSideBar::Articles###001
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the agent interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

AgentFAQSideBar::Articles###002
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the agent interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

AgentFAQSideBar::Articles###003
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the agent interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

AgentFAQSideBar::Articles###004
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the agent interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

AgentFAQSideBar::Articles###005
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the agent interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

CustomerFAQSideBar::Articles###001
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the customer interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

CustomerFAQSideBar::Articles###002
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the customer interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

CustomerFAQSideBar::Articles###003
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the customer interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

CustomerFAQSideBar::Articles###004
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the customer interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

CustomerFAQSideBar::Articles###005
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the customer interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

FAQSideBar::Agent::Enabled
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Determines if the sidebar is enabled for Agent Interface.

FAQSideBar::Customer::Enabled
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Determines if the sidebar is enabled for Customer Interface.

FAQSideBar::ExpandSubcategories
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Determines if the subcategories must be expandes on Sidebar init.

FAQSideBar::Public::Enabled
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Determines if the sidebar is enabled for Public Interface.

PublicFAQSideBar::Articles###001
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the public interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

PublicFAQSideBar::Articles###002
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the public interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

PublicFAQSideBar::Articles###003
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the public interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

PublicFAQSideBar::Articles###004
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the public interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

PublicFAQSideBar::Articles###005
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Configure the articles for the public interface sidebar, according to the language. Relevant fields: Language: Defines the language in which the sidebar will be displayed; DefaultItemID: ID of the FAQ article that will be displayed by default in the Zoom view; CustomGroupOrder: Custom order for displaying the article grouping categories; Articles: Definition of the grouping categories and the articles to display, up to 2 levels deep. For example: Service Desk::10 will display the link to the FAQ article with ID=10 for the "Service Desk" group, or Service Desk::Security::20 will display the "Service Desk > Security" group and within it the link to the FAQ article with ID=20.

Frontend::Base::FAQTableOfContents
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

FAQTableOfContents::MaxDepth
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Determines the maximum depth levels for each field in tht TOC.

Frontend::Base::Loader
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Loader::Agent::CommonCSS###210-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
List of CSS files to always be loaded for the agent interface.

Loader::Agent::CommonJS###210-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
List of JS files to always be loaded for the agent interface for FAQ.

Loader::Customer::CommonJS###210-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
List of JS files to always be loaded for the customer interface for FAQ.

Frontend::Customer::ModuleRegistration::Loader
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Loader::Module::CustomerFAQExplorer###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the customer interface.

Loader::Module::CustomerFAQZoom###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the customer interface.

Loader::Module::CustomerTicketMessage###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the customer interface.

Frontend::Public::ModuleRegistration::Loader
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Loader::Module::PublicFAQExplorer###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

Loader::Module::PublicFAQSearch###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

Loader::Module::PublicFAQZoom###003-FAQExtendedNavigation
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

About
=======

Contact
-------
| Rother OSS GmbH
| Email: hello@otobo.io
| Web: https://otobo.io

Version
-------
Author: |doc-vendor| / Version: |doc-version| / Date of release: |doc-datestamp|
