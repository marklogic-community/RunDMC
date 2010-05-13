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
