This directory contains all the scripts used at build time for preparing
and optimizing the Docs content. See README_FOR_NIGHTLY_BUILD.txt for
instructions on running them.

setup-all.xqy
  This script generates an HTML form which you can use to selectively run
  parts of the build process. This is very useful for development. Rather
  than have to wait for the entire build to run to test your changes, you
  can just pick and choose which steps you want to run. See the
  "MORE SELECTIVE BUILDS" section in README_FOR_NIGHTLY_BUILD.txt for more
  details.

build.xqy
  This is the top-level script used for the nightly build. It invokes
  everything in /apidoc/setup that needs to be invoked to load & prepare
  the docs for a specific version. See README_FOR_NIGHTLY_BUILD.txt for
  details on how to run the build.

  Here are the scripts invoked in turn by build.xqy:

  delete-raw-docs.xqy
    When running a clean build, this script deletes all of the raw
    API & guide documents in the "raw docs" database
    (named "RunDMC-api-rawdocs" by default).

  delete-docs.xqy
    When running a clean build, this script deletes all of the primary
    doc content--every doc URI starting with "/apidoc/5.0/", for example,
    if you're running the build with version=5.0.

  delete-doc-images.xqy
    When running a clean build, this script deletes all of the image
    docs referred to by other docs (especially guides).

  load-static-docs.xqy
    This script loads all of the "static" docs, which include PDFs,
    JavaDocs, .NET docs, and C++ docs. These are loaded straight into
    the live database (bypassing the "raw docs" database).

  load-raw-docs.xqy
    This script loads all of the raw function, REST resource, and guide docs
    into the "raw docs" database (RunDMC-api-rawdocs), so they'll be ready
    for processing by subsequent scripts.

  setup-guides.xqy
    This script grabs all the guide content from the "raw docs" database,
    and assembles and prepares all the final guide content in the live database.
    It does this in three steps (sub-scripts, which can also be invoked
    independently):

    consolidate-guides.xqy
      Re-organizes guide chapters into the desired URI structure (but still in
      the "raw docs" database for the time being). Also creates a chapter list
      for the guide home page.

    convert-guides.xqy
      Grabs the consolidated guide content from the "raw docs" database and
      converts it to its final form. The heavy-lifting in this step is done in:

      convert-guide.xsl
        Implements a multi-stage transformation for converting the Frame-outputted
        XML to HTML, including a hierarchy of <div> (section) elements and 
        captured numbered and bulleted lists.
  
    copy-guide-images.xqy
      Finds all the guide image references and copies the reference docs from
      the "raw docs" database to the appropriate place in the live database.

  setup.xqy
    This script invokes multiple sub-scripts (which can also be invoked independently)
    to prepare function/REST docs, create the TOC, and generate the various
    function/resource library index pages:

    pull-function-docs.xqy
      This script pulls all the function/REST content from the "raw docs" database
      into the live database using the following XSLT:
      
      extract-functions.xsl 
        This script extracts individual function/REST documents (one doc for each
        function or resource) to be inserted into the live database.

    create-toc.xqy
      This script generates an XML-based TOC file (stored at, for example,
      /media/apiTOC/6.0/toc.xml). The heavy lifting is done in toc.xsl and its includes:

      toc.xsl
        This script analyzes both the prepared function and guide documents to generate
        the XML TOC, which also includes all the library/category intro content inline
        (for index pages). This is also the file you edit to manually add or change parts of the
        TOC structure that aren't automatically generated (like the "Other Docs" tab).

        tocByCategory.xsl
          Imported by toc.xsl to handle generation of the category-based hierarchy
          ("Functions by category" and the REST API TOC).

        toc-help.xsl
          This script analyzes /apidoc/config/help-config.xml and extracts data
          from the designated XSD files on the file system to generate the
          "Admin Interface Help" portion of the TOC.

    render-toc.xqy
      This script takes the XML TOC and generates the final static HTML TOC.
      Heavy lifting is done here:

      render-toc.xsl
        This script generates the final JavaScript and HTML structure of the
        TOC and its tabs--everything in the sidebar. No manual configuration
        is included here. It's purely about rendering what's in toc.xml (the
        result of toc.xsl).

        NOTE: In addition to generating the main HTML TOC, it also generates all
        of the sub-TOC files (also static HTML) which are lazily-loaded using the
        Ajax-based lazy-loading feature of the (slightly modified) jQuery Tree plugin
        that we're using.

    delete-old-toc.xqy
      We generate a new HTML URL for the TOC each time we run a build (to avoid
      browsers caching an older TOC). This script ensures that we clean up the
      old TOCs.

    make-list-pages.xqy
      This script generates all the index pages for function libraries, categories,
      and REST resource categories, including the "all functions" page. The XML
      TOC is the input and provides all the content for these pages.

  [/setup/collection-tagger.xqy]
    Not in this directory, but this is invoked at the end of the build to ensure
    all the documents (including both docs and DMC) are tagged with the appropriate
    "category" tag so that faceting will work in search results.

  make-standalone-search-page.xqy
    This inserts a simple XML doc at /apidoc/do-search.xml specific to the "standalone"
    version of the site. (Normally, in non-standalone, the search page is on the
    DMC server; on docs, "/search" is already taken; that's why we use "/do-search")

MISCELLANEOUS SCRIPTS
      
common.xqy
  This script is used by all the individual XQuery scripts that perform
  a single step in the build process. It defines common variables such
  as where to store the resulting TOC.

REST-common.xsl
  This script includes some rules for mapping between internal/external REST
  resource doc URIs and their display names. It is included by some of the
  setup scripts in this directory (and, perhaps less than ideally, by
  /apidoc/view/page.xsl).

do-consolidate-guides.xqy
  Does the dirty work for consolidate-guides.xqy (as it's run in the "raw docs" database).

fixup.xsl
  Rewrites links, etc. in the input so they'll work correctly in the output.
  Used by both toc.xsl and extract-functions.xsl.

optimize-js.sh & optimize-js-requests.xsl
  See README.js-optimization.txt

raw-docs-access.xqy
  Defines variables for easily accessing the various parts of the "raw docs" database.
  Used by a number of the setup scripts. 
