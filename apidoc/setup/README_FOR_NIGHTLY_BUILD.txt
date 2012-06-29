The following instructions assume you have the databases
and app servers set up for either full RunDMC (see /setup/README.txt)
or the standalone API docs (see /setup/README_FOR_STANDALONE_APIDOC.md).

This document describes the steps needed to run a full build of the
API docs for a given server version (e.g., 4.1, 4.2, 5.0, 5.1, etc.). It
is meant to facilitate the creation of, for example, a shell script or Perl
script that makes HTTP requests to invoke the various stages of the build
process.


1-STEP BUILD

The simplest way to get a clean build for all documents for a particular
server version is to invoke a single GET request. For example:

  GET http://localhost:8008/apidoc/setup/build.xqy?version=5.0&srcdir=/Users/elenz/Desktop/api-rawdocs/b5_0_XML&staticdir=/Users/elenz/Desktop/MarkLogic_5_pubs&help-xsd-dir=/Users/elenz/Desktop/Config/5.0&clean=yes

The build.xqy script kicks off a complete build for the docs for
the specified server version.

Four request parameters are required, and one is optional:

   version
     the server version (e.g., 5.0)

   srcdir
     the filesystem directory containing the raw source XML
     (e.g., /space/elenz/api-rawdocs/b5_0_XML)

   staticdir
     the filesystem directory containing the "pubs" for this version,
     (e.g., /space/elenz/MarkLogic_5_pubs)

   help-xsd-dir
     the filesystem "Config" directory containing the XSD files for this version
     (for extracting the admin help content)

   clean=yes (optional)
     If specified, then all the database contents for the given
     server version docs will be deleted before running the build.

You can watch the server's ErrorLog to gauge the script's progress. If a full
(optionally clean) load-and-build is all you need, then there's no need to read
any further.

WARNING: clean builds (where everything is deleted first) will result
in minutes of service interruption. Specifying clean=yes should be done
rarely on the production machine.


MORE SELECTIVE BUILDS

For a visual overview and control center of every piece of the build process,
visit http://localhost:8008/apidoc/setup/setup-all.xqy (assuming your maintenance
server is at port 8008). This page uses AJAX triggered by button clicks to invoke
the various stages of the build process. One way to see exactly what's entailed
is to run a build for one version (e.g., click the "Load and set up all 4.2 docs"
button) and watch what HTTP requests are sent using your browser's debug console
(e.g. Chrome Developer Tools or Firebug). In this case, each subsequent button
corresponds to a single HTTP request which invokes one update transaction. Before
(automatically) moving to the next button, the AJAX response must be retrieved. In
other words, within the build for a given version, each step depends on the
successful completion of the steps before it.

This means that a master build script (e.g. that makes calls to cURL) should
wait for the successful response from one URL before moving onto the next. Also,
an HTTP error response should cause the script to fail.

If you are building more than one version, they could be done independently and
in parallel (no dependencies between them).


  BUILDING THE LIVE DOCS

  Here are the sequences of steps needed to build a version of the docs (4.2 in this case).
  Note that in each case, the URL contains the query string parameter "version=4.2"

  The step and sub-step numbers below re-use the same labels used in the setup page:


  Step 1 (Load raw docs)

    GET http://localhost:8008/apidoc/setup/load-raw-docs.xqy?version=4.2&srcdir=/Users/elenz/Desktop/api-rawdocs/b4_2_XML

    Note the "srcdir" parameter: it must point to the location on the filesystem that contains the raw source files


  Step 2a (Consolidate guides)

    GET http://localhost:8008/apidoc/setup/consolidate-guides.xqy?version=4.2


  Step 2b (Convert guides)

    GET http://localhost:8008/apidoc/setup/convert-guides.xqy?version=4.2


  Step 2c (Copy guide images)

    GET http://localhost:8008/apidoc/setup/copy-guide-images.xqy?version=4.2


  Step 3a (Pull function docs)

    GET http://localhost:8008/apidoc/setup/pull-function-docs.xqy?version=4.2


  Step 3b (Create XML TOC)

    GET http://localhost:8008/apidoc/setup/create-toc.xqy?version=4.2&help-xsd-dir=/Users/elenz/Desktop/Config/4.2

    Note the "help-xsd-dir" parameter: it must point to the location on the filesystem containing the XSD files


  Step 3c (Render HTML TOC)

    GET http://localhost:8008/apidoc/setup/render-toc.xqy?version=4.2


  Step 3d (Delete old TOC)

    GET http://localhost:8008/apidoc/setup/delete-old-toc.xqy?version=4.2


  Step 3e (Make list & help pages)

    GET http://localhost:8008/apidoc/setup/make-list-pages.xqy?version=4.2

  Step 3e (Insert admin help images)

    GET http://localhost:8008/apidoc/setup/insert-admin-images.xqy?version=4.2


  That completes the list of steps for a full build of a server version, except for the
  "static docs".


  BUILDING THE STATIC DOCS

  To publish the static PDF and HTML docs (javadoc and .NET docs), you must
  also run the following script:

    GET http://localhost:8008/apidoc/setup/load-static-docs.xqy?version=4.2&staticdir=/Users/elenz/Desktop/MarkLogic_4.2_pubs

    Note the "staticdir" parameter: it must point to the location on the filesystem that contains the static source files
    (Which sub-directories are loaded is configured in /apidoc/config/static-docs.xml)


  RUNNING THE CATEGORY TAGGER

  There is one final step that should be run after the build of any version. (See the
  "Run global category tagger" button at the bottom of that page.) This updates the
  collection tags for all documents so that their proper category facet values are
  reflected in search results.

    GET http://localhost:8008/setup/collection-tagger.xqy


  CREATING THE STANDALONE SEARCH PAGE

  If you're running the standalone API server, then you need to run one more step:

    GET http://localhost:8008/apidoc/setup/make-standalone-search-page.xqy


  DELETING BEFORE BUILDING (RUNNING CLEAN BUILDS)

  To run a "clean" build (not the usual scenario for the production machine,
  since it would result in minutes of service interruption), you would first
  delete the documents before running the above builds. There are four sets
  of documents to delete, the "raw docs" (result of Step 1 above), the "live docs"
  (results of the remaining steps), the "static docs" (result of load-static-docs.xqy),
  and the "doc images" (e.g. everything in /media/4.2/apidoc/).

  To delete the "raw docs":

    GET http://localhost:8008/apidoc/setup/delete-raw-docs.xqy?version=4.2

  To delete the "live docs":

    GET http://localhost:8008/apidoc/setup/delete-docs.xqy?version=4.2

  To delete the "static docs":

    GET http://localhost:8008/apidoc/setup/delete-static-docs.xqy?version=4.2

  To delete the "doc images":

    GET http://localhost:8008/apidoc/setup/delete-doc-images.xqy?version=4.2
