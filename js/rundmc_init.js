/* Copyright 2002-2014 MarkLogic Corporation.  All Rights Reserved. */

var versionSelect = null;

$(function() {
    if (!versionSelect) versionSelect = $("#version_list");

    if (!versionSelect.length) {
        console.log("No version_list!");
        return;
    }

    versionSelect.change(function(e) {
        var defaultVersion = versionSelect.attr('data-default');
        var version = versionSelect.children("option")
            .filter(":selected").val();
        //console.log('version select option changed',
        //            defaultVersion, version);
        // TODO Redirect to an appropriate page.
        var oldPath = window.location.pathname;
        // Search pages are different, and use q=fubar&v=8.0 etc. in query string.
        if (oldPath == "/search"
           || oldPath == "/do-search") {
            var oldQuery = window.location.search;
            var newQuery = oldQuery.replace(/&v=\d+\.\d+/, "&v=" + version);
            if (newQuery == oldQuery) newQuery += "&v=" + version;

            window.location =
                window.location.protocol
                + "//"
                + window.location.host
                + window.location.pathname
                + newQuery
                + window.location.hash;
            return;
        }

        var newPath = oldPath;
        if (version == defaultVersion) {
            //console.log("using default", defaultVersion);
            newPath = oldPath.replace(/^\/\d+\.\d+/, "");
        } else if (oldPath.match(/^\/\d+\.\d+/)) {
            //console.log("replacing old with", version);
            newPath = oldPath.replace(
                    /^\/\d+\.\d+/, "/" + version);
        } else {
            //console.log("prepending", version);
            newPath = '/' + version + oldPath;
        }
        //console.log('old', oldPath, 'new', newPath);
        // Do not set query string, because it might set the version too.
        window.location =
            window.location.protocol
            + "//"
            + window.location.host
            + newPath
            + window.location.hash;
    });

});

// rundmc_init.js
