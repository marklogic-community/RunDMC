page.xsl
  The top-level XSLT module. Imports and overrides rules in 
  the main website's version: (../../view/page.xsl). Also
  imports tag-library.xsl and form.xsl.

tag-library.xsl
  Adds some admin-specific tags to the tag library, mostly for
  rendering lists of documents on each main section page of the
  Admin UI.

form.xsl
  Implements the rules for two tags:
    1. <ml:auto-form/>, which appears in the source XML for Admin pages.
    2. <ml:auto-form-scripts/>, which appears in the XHTML template file.

adminAddMedia.html
  Currently not used.

  It's a mock-up component of a future "Media upload" feature which
  could be added to the Admin UI. Some of the CSS has already been
  written for that. Search for the (disabled) "add_media" form field
  in form.xsl for a starting point for implementing this.
