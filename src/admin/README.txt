See ../README.txt for some setup notes.

CODE NOTES

The three most important code directories are "model", "view",
and "controller":

  model
    Contains XSLT code for translating back and forth between XML content
    and XML-based form specifications. Much of the heavy-lifting happens
    here.

  view
    Contains the XSLT code for rendering the XML-based form specs,
    as well as admin-specific tag library additions. As with the
    main website application, a module named "page.xsl" is the top-level
    stylesheet that gets invoked. In fact, it reuses much of the
    main website application's code by importing /view/page.xsl.

  controller
    Contains the URL rewriter and XQuery scripts for handling HTTP
    requests, for invoking the (XSLT) model and view code, and for
    inserting and replacing documents in the database.


Another important directory is "config":

  config
    Contains the sitemap configuration and XHTML template configuration,
    as well as a config file for each type of content that can be
    edited. See README.txt in the "/admin/config/forms" sub-directory.
