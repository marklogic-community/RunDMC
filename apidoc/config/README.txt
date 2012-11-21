REST-complexType-mappings.xml
  This file provides mappings between REST resource names and their corresponding
  XSD complex types. This is used in the apidoc setup scripts to generate part of
  the REST API doc content.

category-mappings.xml
  This file is used by the setup code. It lists exceptions to the automated
  mappings of function reference categories to resulting (friendlier, more
  concise) URLs.

document-list.xml
  This file configures what guides are displayed on the apidoc home page
  (e.g., docs.marklogic.com), as well as their order and descriptions. This is
  used by both the (build-time) setup code and the (run-time) rendering code.
  See the file for more detailed info.

help-config.xml
  This file configures the TOC for every version of the Help docs, as well
  as the data sources for all the Help content, principally identified by
  each element name in the hierarchy.

namespace-mappings.xml
  This file lists all the extension and library module namespaces with their
  customary prefixes. It's used by the setup code for the function reference.

source-database.xml
  This file contains the name of the source database containing the raw API docs.
  The /apidoc/setup directory includes scripts for both the loading of docs into
  this database and for reading them for subsequent processing and output into
  the live database.

static-docs.xml
  This file configures which subdirectories of "pubs" in the MarkLogic docs
  zip distribution should be loaded into the live database (again, using a script
  in /apidoc/setup).

template.xhtml
  This file contains the HTML wrapper that's used on all the pages of the docs site.
  This is analogous to the /config/template.xhtml, which is used for the "main"
  (non-docs) site, e.g. developer.marklogic.com.

title-aliases.xml
  This file contains some alternative titles for certain user guides, in order
  to facilitate the automatic rendering of italicized text in the source to
  a link to the corresponding guide.
