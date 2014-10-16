page.xsl
  The top-level stylesheet that gets invoked directly by
  the controller script (transform.xqy). It includes or
  imports all the rest of the XSLT in this directory (whether
  directly or indirectly). It contains rules for rendering
  the custom tags in template.xhtml
  
  E.g., match="page-content" and match="page-title"


tag-library.xsl
  This contains rules for rendering the plethora of custom
  tags supported in the XML source documents for pages
  themselves. Each template rule in the unnamed mode
  is an implementation of a custom tag.

  E.g., match="tabbed-features" and match="top-threads"


navigation.xsl
  This is where all the rules for rendering the navigational
  components of the site reside (e.g., breadcrumbs, top- and
  sub-level navigation menus, conditional CSS classes
  based on position in the hierarchy, etc.)

  E.g., match="top-nav" and match="sub-nav"


widgets.xsl
  The rules in this stylesheet process the widget configuration,
  inserting content into the sidebar of the site.

  Specifically, match="widgets"


xquery-imports.xsl
  This stylesheet collects the extension elements for importing
  XQuery code (from the "model" directory) into our XSLT so that
  its functions and variables are globally available in the XSLT.
