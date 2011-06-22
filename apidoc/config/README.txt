source-database.xml
  This file contains the name of the source database containing the raw API docs.
  The setup scripts in /apidoc/setup get their data from this database.

document-list.xml
  This file configures what guides are displayed on the /docs page, as well
  as their order and descriptions. This is used by both the (build-time) setup
  code and the (run-time) rendering code. See the file for more detailed info.

namespace-mappings.xml
  This file lists all the extension and library module namespaces with their
  customary prefixes. It's used by the setup code for the function reference.

server-versions.xml
  This file configures what versions of the documents (4.1, 4.2, etc.) are to
  be displayed on the website, as well as which version is the default (should
  normally be the latest).

category-mappings.xml
  This file is used by the setup code. It lists exceptions to the automated
  mappings of function reference categories to resulting (friendlier, more
  concise) URLs.

title-aliases.xml
  This file contains some alternative titles for certain user guides, in order
  to facilitate the automatic rendering of italicized text in the source to
  a link to the corresponding guide.

template.xhtml
  This file contains the HTML wrapper that's used on all the pages of the site.
