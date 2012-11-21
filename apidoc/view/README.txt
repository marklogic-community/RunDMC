This directory contains the code for the run-time rendering of
pages on the Docs (apidoc) server.

Files in this directory:

page.xsl
  This is the top-level XSLT script which gets invoked to render pages
  on docs.marklogic.com. It imports the analogous /view/page.xsl (which
  is the top-level stylesheet for developer.marklogic.com), effectively
  reusing much of the XSLT code. Thus it's main purpose is to selectively
  override aspects of /view/page.xsl (and its includes). In addition, it
  imports or includes the other apidoc-specific XSLT scripts in this
  directory.

guide.xsl
  The template rules in this stylesheet are concerned with rendering
  user guides at run-time (included by page.xsl).

uri-translation.xsl
  This script is concerned with mapping to/from internal/external URIs, i.e.
  URIs that users see in the browser, and actual document URIs in the database.
  It selectively overrides function definitions in the analogous
  /view/uri-translation.xsl.

xquery-imports.xsl
  This script consolidates the XQuery imports (e.g., /apidoc/model/data-access.xqy).
  It is analagous to /view/xquery-imports.xsl.


WARNING: At least one script (REST-common.xsl) in /apidoc/setup is
imported by page.xsl, so, yes, /apidoc/view does have that one dependency on
/apidoc/setup. A good refactor might be to move that code to this
directory so the dependency between /apidoc/view and /apidoc/setup is
just one-way instead of two-way.

