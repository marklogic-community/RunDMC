The code inside this "apidoc" directory is used exclusively for the
Docs/API server (e.g., docs.marklogic.com). It contains analogous directories
to its parent (the root of the code distro). Specifically, it contains
the following directories:

config
  Includes configuration information including the XHTML template
  for the docs server, function library namespace URI mappings,
  a list of documents for the home page, config info for the Help
  page hierarchy, and other configuration info relating to the
  docs build process. See /apidoc/config/README.txt for more details.

controller
  Contains url_rewrite.xqy and transform.xqy (analogous to those in 
  /controller), as well as docapp-redirector.xqy which uses JavaScript
  to redirect legacy docapp URLs to the new apidoc URLs.

images & js
  Contains image and JavaScript files specific to the apidoc server.

model
  Contains an apidoc-specific data-access.xqy module. This is analogous to
  /model/data-access.xqy which it also imports.

setup
  Contains the code responsible for running the docs build. Note that
  some of this code has dependencies on other modules (via importing or
  including XQuery and XSLT scripts outside this directory).
  See /apidoc/setup/README.txt for more details.

view
  Contains the apidoc-specific page.xsl (the XSLT script invoked to
  generate pages on the Docs server). This is analogous to the top-level
  /view/page.xsl which it also imports. See /apidoc/view/README.txt for
  more details.


HOW TO RUN THE APP
  Set up an app server with the same settings as the "Main server", except 
  using a different URL rewriter: 

  /apidoc/controller/url_rewrite.xqy

  Point your browser to the app server you just set up. If it doesn't work yet,
  it's because you need to load and setup the content first. 
  See /apidoc/setup/README.txt.
