/* Copyright 2002-2015 MarkLogic Corporation.  All Rights Reserved. */

/*jslint node: true */
/* global $ */
/* global React */
/* global document */
/* global window */
'use strict';

var LOG = {
  DEBUG: false,
  debug: function() {
    if (!this.DEBUG) return;
    console.log.apply(console, arguments); },
  warn: function() {
    console.log.apply(console, arguments); }};

$(function() {
  var versionSelect = null;

  if (!versionSelect) versionSelect = $("#version_list");

  if (!versionSelect.length) {
    // This is ok - many pages do not have the version selector.
    //LOG.debug("No version_list!");
    return;
  }

  versionSelect.change(function(e) {
    LOG.DEBUG = true; // TODO
    var defaultVersion = versionSelect.attr('data-default');
    var version = versionSelect.children("option")
        .filter(":selected").val();
    LOG.debug('version select option changed', defaultVersion, version);
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
      LOG.debug("using default", defaultVersion);
      newPath = oldPath.replace(/^\/\d+\.\d+/, "");
    } else if (oldPath.match(/^\/\d+\.\d+/)) {
      LOG.debug("replacing old with", version);
      newPath = oldPath.replace(
          /^\/\d+\.\d+/, "/" + version);
    } else {
      LOG.debug("prepending", version);
      newPath = '/' + version + oldPath;
    }
    LOG.debug('old', oldPath, 'new', newPath);
    // Do not set query string, because it might set the version too.
    // Any old hash may be invalid, but set in anyway.
    window.location = window.location.origin +
      newPath + window.location.hash;
  });

  highlightInit();

  // If this seems to be a highlight page,
  // erase that param for a clean URL.
  var params = paramsMap(window.location.search);
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

  // reactjs multiselect component for search facets
  var facetSelectionWidgetContainer = document.getElementById(
    'facetSelectionWidget');
  LOG.debug(facetSelectionWidgetContainer);
  if (facetSelectionWidgetContainer) {
    var FacetSelectionWidget = React.createClass(
      {displayName: "FacetSelectionWidget",
       activeClassName: "current",
       getInitialState: function() {
         var constraints = this.props.initialConstraints;
         return {active:constraints.length < 2 ? "single" : "multi",
                 constraints:constraints}; },
       render: function() {
         LOG.debug("render", this.state);
         var className = "facetSelectionButton";
         var multi = this.state.active === "multi";
         var size = 16;
         return React.DOM.span(
           null,
           React.DOM.img(
             {onClick:this.handleClickSingle,
              src:"/images/i_database_plus.png",
              height:size, width:size,
              alt:"multiselect",
              title:"Enable selection of multiple facets.",
              className:(multi ? "hidden" : className)}),
           // TODO disable when search has not changed?
           React.DOM.img(
             {onClick: this.handleClickCancel,
              src:"/images/b_close.png",
              height:size, width:size,
              alt:"reset",
              title:"Reset any changes to facets.",
              className:(multi ? className : "hidden")}),
           React.DOM.img(
             {onClick:this.handleClickSearch,
              src:"/images/i_mag_glass1.png",
              height:size, width:size,
              alt:"search",
              title:"Apply any changes to selected facets.",
              className:(multi ? className : "hidden")})); },

       // After init or any update, push component state to the DOM facets.
       componentDidMount: function() {
         LOG.debug("componentDidMount");
         // First time: install click handlers to intercept href links.
         var fn = this.handleFacetClick;
         $('ul.categories li a').each(
           function(i, n) {
             $(n).on('click', fn); });
         this.propagateState(); },
       componentDidUpdate: function(prevProps, prevState) {
         // Use component state to update the DOM facets.
         this.propagateState(prevState.active); },

       handleClickCancel: function() {
         LOG.debug("handleClickCancel");
         // Restore initial state.
         this.setState(this.getInitialState()); },
       handleClickSearch: function() {
         LOG.debug("handleClickSearch");
         // Update search form and submit.
         var $form = $(".search-form").first();
         var $qInput = $form.find('input[name="q"]');
         var qu = $('#queryUnconstrained').text().trim();
         var qc = "";
         if (this.state.constraints.length &&
             this.state.constraints[0] !== "") {
           qc = "(" + this.state.constraints.join(" OR ") + ") ";
         }
         LOG.debug("handleClickSearch", this.state.constraints, qu, qc);
         var nextQ = qc + qu;
         var prevQ = $qInput.val().trim();
         if (nextQ === prevQ) {
           LOG.warn("handleClickSearch noop", prevQ, nextQ);
           return;
         }
         $qInput.val(qc + qu);
         // No need to setState because we are fetching a new page.
         $form.submit(); },
       handleClickSingle: function() {
         LOG.debug("handleClickSingle");
         this.setState({active:"multi"}); },

       handleFacetClick: function(evt) {
         LOG.debug("handleFacetClick", evt, this.state.active);
         // Defer to href and reload page.
         if (this.state.active == "single") { return true; }
         // multi
         var c = evt.target.dataset.constraint;
         var isChild = c.indexOf("/") >= 0;
         var nextConstraints = this.state.constraints.concat();
         var index = nextConstraints.indexOf(c);
         LOG.debug("handleFacetClick", c, isChild, nextConstraints, index);
         if (index < 0) {
           // Add new constraint, or do something else that makes sense.
           // "":All trumps everything else.
           if (c === "") {
             nextConstraints = [""];
           } else {
             // Avoid mixing "":All with anything else.
             if (nextConstraints[0] === "") {
               nextConstraints = [c];
             } else {
               // Remove any parents of a new child constraint.
               if (isChild) {
                 var cParent = c.split("/")[0];
                 var pIndex = nextConstraints.indexOf(cParent);
                 if (pIndex >= 0) { nextConstraints.splice(pIndex, 1); }
               } else {
                 // Remove any children of a new parent constraint.
                 var cChild = c + "/";
                 nextConstraints = $.map(
                   nextConstraints,
                   function(n,i) {
                     // Fake String.startsWith
                     if (n.lastIndexOf(cChild, 0) === 0) { return null; }
                     return n; });
               }
               // Append the new constraint.
               nextConstraints.push(c);
             }
           }
         } else {
           // Remove existing constraint.
           nextConstraints.splice(index, 1);
         }
         // Default "":All.
         if (typeof nextConstraints === 'undefined' ||
             !nextConstraints.length) {
           nextConstraints = [""];
         }
         LOG.debug("handleFacetClick final", c, index, nextConstraints);
         // Updating the state will re-render, then update the DOM facets.
         this.setState({constraints:nextConstraints});
         // Never follow href.
         return false; },

       // DOM facets are not part of this component,
       // but we update their state on every component state change.
       propagateState: function(prevActive) {
         LOG.debug("propagateState", this.state.constraints,
                   typeof this.state.constraints);
         var className = this.activeClassName;
         var constraints = this.state.constraints;
         $('ul.categories li').each(
           function(i, n) {
             var $n = $(n);
             var c = $n.find('a').data("constraint");
             var index = constraints.indexOf(c);
             var has = $n.hasClass(className);
             if (index < 0 && !has) { return; }
             if (index >= 0 && has) { return; }
             LOG.debug("propagateState", i, n, c, index, has);
             $n.toggleClass(className); }); }});

    // Initial constraints are supplied from DOM state.
    // If no contraints are selected this will be [""] = "All categories".
    var facetSelectionWidget = React.render(
      React.createElement(
        FacetSelectionWidget,
        {initialConstraints:$('ul.categories li.current > a').map(
          function(i,n) {
            return $(n).data("constraint"); }).toArray() }),
      facetSelectionWidgetContainer);
  }
});

function mapParams(o) {
  return $.map(o,
               function(v,k) {
                 if (typeof v === 'string') {
                   return k + '=' + encodeURIComponent(v);
                 }
                 // handle repeated params
                 return v.forEach(
                   function(n,i) {
                     return k + '=' + encodeURIComponent(n); }); })
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

function scrollIntoView(selector, containerSelector) {
  LOG.debug("scrollIntoView", selector, containerSelector);
  var $n = $(selector).first();
  // was anything highlighted?
  if (!$n.length) {
    LOG.warn("scrollIntoView", "nothing to scroll", $n);
    return;
  }

  var $container = $(containerSelector).first();
  if (!$container.length) {
    LOG.warn("scrollIntoView no container", containerSelector);
    return;
  }

  // Scroll the first match into view.
  LOG.debug("scrollIntoView", $n, $container);
  // The DOM offsetTop is relative to the offsetParent,
  // while the jQuery .offset().top is relative to document.
  // Neither one is entirely suitable.
  var offsetTop = Math.ceil($n.offset().top - $container.offset().top);
  var margin = 3 * $n.height();
  var containerTop = $container.scrollTop();
  var containerHeight = $container.height();
  var minVisible = containerTop + margin;
  var maxVisible = containerTop + containerHeight - margin;
  var willScroll = offsetTop < minVisible || offsetTop > maxVisible;
  var scrollTop = offsetTop - minVisible;
  LOG.debug("scrollIntoView",
            "n", offsetTop, margin,
            "container", containerTop, containerHeight,
            "visible", minVisible, maxVisible,
            "scroll", willScroll, scrollTop);
  if (!willScroll) {
    LOG.debug("scrollIntoView noop");
    return;
  }
  $container.animate({scrollTop:scrollTop});
}

function highlightInit() {
  LOG.debug("highlightInit");

  var className = "hit_highlight";
  var selector = "." + className;
  var $widget = $('#highlightWidget');
  if (!$widget.length) { return; }
  $widget.on('click', function(evt) {
    $(selector).removeClass(className);
    // Also remove the widget container
    $(".highlightWidget").remove();
    return false; });

  // Scroll the first match into view.
  scrollIntoView(selector, '#page_content');
}

// rundmc_init.js
