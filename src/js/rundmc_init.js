/* Copyright 2002-2015 MarkLogic Corporation.  All Rights Reserved. */

var DEBUG = false;
var LOG = {};
LOG.debug = function() {
    if (!DEBUG) return;
    console.log.apply(console, arguments);
};

LOG.warn = function() {
    console.log.apply(console, arguments);
};

$(function() {
  var versionSelect = null;

  if (!versionSelect) versionSelect = $("#version_list");

  if (!versionSelect.length) {
    // This is ok - many pages do not have the version selector.
    //console.log("No version_list!");
    return;
  }

  versionSelect.change(function(e) {
    var defaultVersion = versionSelect.attr('data-default');
    var version = versionSelect.children("option")
        .filter(":selected").val();
    //console.log('version select option changed',
    //            defaultVersion, version);
    // Redirect to an appropriate page.
    var oldPath = window.location.pathname;
    // Search pages are different, and use q=fubar&v=8.0 etc. in query string.
    if (oldPath == "/search" ||
        oldPath == "/do-search") {
      var oldQuery = window.location.search;
      // Handle different positioning of version strings.
      var newQuery = oldQuery
          .replace(/\?v=\d+\.\d+/, "?v=" + version)
          .replace(/&v=\d+\.\d+/, "&v=" + version);
      // Handle no version string.
      if (newQuery == oldQuery) newQuery += "&v=" + version;

      window.location = window.location.origin + window.location.pathname +
        newQuery + window.location.hash;
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
    // Any old hash may be invalid, but set in anyway.
    window.location = window.location.origin +
      newPath + window.location.hash;
  });

  highlightInit();

  // If this seems to be a highlight page,
  // erase that param for a clean URL.

  params = paramsMap(window.location.search);
  if (params.hq) {
    // Requires modern browser.
    if (window.history.replaceState) {
      // Rebuild without hq
      delete params.hq;
      var newSearch = mapParams(params);
      if (newSearch) { newSearch = '?' + newSearch; }
      window.history.replaceState(
        null, "",
        window.location.origin + window.location.pathname +
          newSearch + window.location.hash);
    }
  }
});

function mapParams(o) {
  return $.map(o,
               function(v,k) {
                 if (typeof v === 'string') {
                   return k + '=' + v;
                 }
                 // handle repeated params
                 return v.forEach(
                   function(n,i) {
                     return k + '=' + n; }); })
    .join('&');
}

function paramsMap(loc) {
  if (!loc) { return {}; }
  var h = {};
  loc.substr(1).split('&').forEach(
    function(n,i) {
      var p = n.split('=');
      var k = p[0];
      // handle repeated params
      if (typeof h[k] === 'undefined') { h[k] = p[1]; }
      else { h[k].push(p[1]); } });
  return h;
}

function highlightInit() {
  LOG.debug("highlight_init");

  var className = "hit_highlight";
  var selector = "." + className;
  var $widget = $('.highlightWidget');
  if (!$widget.length) { return; }
  $widget.on('click', function(evt) {
    $(selector).removeClass(className);
    // Also remove the widget container
    $(".highlightWidget").remove();
    return false; });

  // was anything highlighted?
  var offset = $(selector).offset();
  LOG.debug("highlight_init", offset);
  if (!offset) {
    LOG.debug("highlight_init", "nothing to highlight");
    return;
  }
  if (offset.top < $(window).height()) {
    LOG.debug("highlight_init", "already in view");
    return;
  }

  // Scroll the first match into view.
  // This needs a shim to account for hidden content.
  $('#page_content').animate({
    scrollTop: offset.top - tocHeaderHeightPX,
    scrollLeft: offset.left
  });
}

// rundmc_init.js
