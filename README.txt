LICENSE

  All original code in this repository is Copyright MarkLogic 2010-2011.  All Rights Reserved.  It is made available 
  for your use via an Apache 2.0 license (http://www.apache.org/licenses/LICENSE-2.0.html)


SETUP NOTES

  Main server:
    App server root should be set to the root of this distribution, on 
    the filesystem.  The URL rewriter should be set to "/controller/url_rewrite.xqy".
    The error handler should be set to "/controller/error-handler.xqy".

  Draft server:
    This app server must have the word "Draft" in its name.

    On another port, same exact configuration as main server but
    with a different server name. "Draft" documents will be visible
    on this server. For "preview" to work in the Admin UI, update
    /config/server-urls.xml with the correct host name and corresponding
    draft server URL.  Default is same hostname, port 8004.

  Admin interface (CMS) server:
    This app server must have the word "Admin" in its name.

    For the Admin interface, set up a different HTTP app server,
    using the same content database and same server root. But set
    the URL rewriter to "/admin/controller/url_rewrite.xqy".
    Defa

  WebDAV server:
    If you want "view XML source" to work in the admin UI, set up
    a WebDAV server with root set to "/". Then add the server URL to
    /admin/config/navigation.xml.  Default is same hostname, port 8005.

  XDBC server:
    If you want to use the loading tools to copy a database from 
    the live developer site, you'll need an XDBC server.
    

  To copy a database from the staging site, use the script in the tools
  directory.


CODE NOTES

The three most important code directories are "model", "view",
and "controller":

  model
    Contains XQuery modules for data access and document filtering.

  view
    Contains the XSLT code for rendering the content of the site,
    including navigational behavior, widget rendering, implementation
    of the tag library, etc. The stylesheet "page.xsl" is the only
    top-level stylesheet that gets invoked. It imports or includes
    everything else.

  controller
    Contains the URL rewriter and XQuery scripts for handling HTTP
    requests and for invoking the (XSLT) view code (transform.xqy).


Another important directory is "config":

  config
    Contains the sitemap configuration, XHTML template configuration,
    server URL configuration, and widget configuration.


On the content management side:

  admin
    Contains a complete application for managing XML content via
    Web forms. Contains its own "model", "view", "controller", and
    "config" directories.


For more details, see the various README.txt files appearing in
sub-directories.


