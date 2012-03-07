Files in this directory:

  - README_FOR_STANDALONE_APIDOC.txt

    Step-by-step instructions for setting up the standalone apidoc application.

  - install.xqy

    Intended to auto-configure a server for use with RunDMC.
    This hasn't been updated for a while and is likely stale.

  - optimize-js.sh

    Run the optimize-js.sh script (from within this directory) to create
    /config/template.optimized.xhtml, which combines all the external JS <script>
    tags into one and creates a new file in /js/optimized called all-XXXXX.js
    (where "XXXX" is the current date/time).

    The server code (/view/page.xsl) checks to see if /config/template.optimized.xhtml
    is present and, if so, uses it. Otherwise, it uses /config/template.xhtml.
    On the production machine, we will want to run the optimization script every
    time we update the JavaScript to force browsers to download the latest JS.

    The script checks to see if the resulting combined JS has actually changed since
    the last time the script was run. If it has, then it creates a new all-XXXX.js file.
    If it hasn't, then it keeps using the previously generated one, so as not to
    force users to download a new JS file that hasn't actually changed.

    Note: this script requires Saxon to be installed on your machine as a script
    called "Transform". Download Saxon-HE from http://saxon.sf.net and read the
    comment at the top of optimize-js.sh for an example of how to set this up.

  - optimize-js-requests.xsl

    What optimize-js.sh invokes to do its work.
    
  - retroactively-create-comment-doc-infrastructure.xqy

    A one-time use script that allowed us to transition to using Disqus-based comments.
    See comments at top of the file for details.

  - collection-tagger.xqy

    This script handles the creation of collection tags on documents to support
    constrained-search/faceted-navigation functionality.
