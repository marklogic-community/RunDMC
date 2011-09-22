There are three important configuration files in this directory:

template.xhtml
  This is the XHTML template that is used for every page of the site.
  Dynamic/variable parts of the template (such as page content) are
  designated using tags in the RunDMC namespace, e.g.: <ml:page-content/>

navigation.xml
  This is the sitemap configuration. It determines how the site is
  structured navigationally, including the top-level (horizontal)
  navigation links, the secondary (sidebar) sub-navigation links,
  and the breadcrumb links.

widgets.xml
  This file determines on what page(s) each widget will appear.

disqus-info.xml
  This file contains the user API key, forum API key, and forum ID
  for each Disqus forum. It also allows you to configure a different
  forum based on the current host type (development, staging, or
  production).

server-versions.xml
  This file configures what versions of the documents (4.1, 4.2, etc.) are to
  be displayed on the website, as well as which version is the default (should
  normally be the latest).
