/* Copyright 2002-2014 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText = '';
var currentFilterText = '';

function toc_init() {
    var tocPartsDir = $("#tocPartsDir").text();
    var tocTrees = $(".treeview");

    tocTrees.treeview({
        prerendered: true,
        url: tocPartsDir });

    // Set up the filter
    $("#config-filter").keyup(function(e) {
        currentFilterText = $(this).val();

        // TODO what about a confirmation alert?
        if (e.which == 13) // Enter key pressed
            window.location = "/do-do-search?q=" + $(this).val();

        var closeButton = $("#config-filter" + "-close-button");
        if ($(this).val() === "") closeButton.hide();
        else closeButton.show();

        setTimeout(function() {
            if (previousFilterText !== currentFilterText) {
                //console.log("toc filter event", currentFilterText);
                previousFilterText = currentFilterText;
                filterConfigDetails(currentFilterText,
                                    "#apidoc_tree"); } },
                   350);
        $("#config-filter" + "-close-button").click(function() {
            $(this).hide();
            $("#config-filter").val("").keyup().blur();
        });
    });

    // default text, style, etc.
    formatFilterBoxes($(".config-filter"));

    // delay this work until the DOM is ready
    $(document).ready(function(){

        $('#splitter')
            .attr({'unselectable': 'on'})
            .css({
                "z-index": 100,
                cursor: "e-resize",
                position: "absolute",
                "user-select": "none",
                "-webkit-user-select": "none",
                "-khtml-user-select": "none",
                "-moz-user-select": "none"
            })
            .mousedown(splitterMouseDown);

        // If this was a deep link, load and scroll.
        updateTocForTab();
    });
}

// This logic is essentially duplicated from the treeview plugin...bad, I know
function expandSubTree(li) {
  if (li.children().is("ul")) {
    li.removeClass("expandable").addClass("collapsible");//.addClass("open");
    if (li.is(".lastExpandable"))
      li.removeClass("lastExpandable").addClass("lastCollapsible");
    li.children("div").removeClass("expandable-hitarea").addClass("collapsible-hitarea");
    if (li.is(".lastExpandable-hitarea"))
      li.children("div").removeClass("lastExpandable-hitarea").addClass("lastCollapsible-hitarea");
    li.children("ul").css("display","block");
  }
}

function filterConfigDetails(text, treeSelector) {

    var tocRoot = $(treeSelector);

    // Make sure "All functions" container after each search (even if empty results)
    // TODO: Figure out how to directly call the "toggler" method from the treeview code rather than using this
    //       implementation-specific stuff

    loadAllSubSections(tocRoot);

    if (tocRoot.hasClass("fullyLoaded"))
      searchTOC(text, tocRoot);
    else
      waitToSearch(text, tocRoot);

    expandSubTree(tocRoot.children("li"));
}

var waitToSearch = function(text, tocRoot) {
  // Repeatedly check for the absence of the "placeholder" class
  // Once they're all gone, run the text search and cancel the timeout
  var placeholders = tocRoot.find(".placeholder");
  if (placeholders.size() == 0) {
    tocRoot.addClass("fullyLoaded");
    searchTOC(text, tocRoot);
    clearTimeout(waitToSearch);
  }
  else
    setTimeout(function(){ waitToSearch(text, tocRoot) }, 350);
}
    
function searchTOC(filter, tocRoot) {
    tocRoot.find("li").each(function() {
        $(this).removeClass("hide-detail");
        $(this).find(">a >.function_count").show();
        /*
        if (filter == '') {
            removeHighlightToText($(this));
        } else {
        */
        if (filter !== '') {
            if (hasText($(this),filter)) {
                    /* Temporarily disable highlighting as it's too slow (particularly when removing the highlight).
                     * Also, buggy in its interaction with the treeview control: branches may no longer respond to clicks
                     * (presumably due to the added spans).
                /*
                if ($(this).find("ul").length == 0)
                    "do nothing"
                    addHighlightToText($(this),filter); // then this is a leaf node, so u can perform highlight
                else {
                    */
                    // Expand the TOC sub-tree
                    expandSubTree($(this));
                    $(this).find(">a >.function_count").hide();
            } else {
                /*
                removeHighlightToText($(this));
                */
                $(this).addClass("hide-detail");
            }
        }
    });
    if (filter == '') scrollTOC(); // re-orient the TOC after done searching
}

function loadAllSubSections(tocRoot) {
  //console.log('loadAllSubSections', tocRoot);
  if (tocRoot.hasClass("startedLoading")) return;

  tocRoot.find(".hasChildren").each(loadTocSection);
  tocRoot.addClass("startedLoading");
}

// We may ignore index, but it's necessary as part of the signature expected by .each()
function loadTocSection(index, tocSection) {
  var $tocSection = $(tocSection);
  console.log("loadTocSection", index, tocSection.length);
  if ($tocSection.hasClass("hasChildren"))
    $tocSection.find(".hitarea").trigger("click");
}


// Called only from updateTocForTab
function waitToShowInTOC(tocSection, sleepMillis) {
  //console.log("waitToShowInTOC", tocSection[0].id, sleepMillis);
  if (!sleepMillis) sleepMillis = 125;

  // Repeatedly check to see if the TOC section has finished loading
  // Once it has, highlight the current page
  if (tocSection.hasClass("loaded")) {
    //console.log("waitToShowInTOC loaded", tocSection);

    clearTimeout(waitToShowInTOC);

    var currentHref = location.href.toLowerCase();
    //console.log("waitToShowInTOC", tocSection, "currentHref=" + currentHref);
    var stripChapterFragment = isUserGuide && currentHref.indexOf("#") == -1;

    // TODO needs special handling for /7.0/fn:abs vs /fn:abs ?

    var locationHref = location.href.toLowerCase();
    var current = tocSection.find("a").filter(function() {
      var thisHref = this.href.toLowerCase();
      var hrefToCompare = stripChapterFragment
            ? thisHref.replace(/#chapter/,"")
            : thisHref;
      var result = hrefToCompare == locationHref;
      //console.log("filtering", thisHref, hrefToCompare, locationHref, result);
      return result;
    });

    // E.g., when hitting the Back button and reaching "All functions"
    $("#api_sub a.selected").removeClass("selected");

    //console.log("waitToShowInTOC found", current.length, current);
    if (current.length) showInTOC(current);

    // Also show the currentPage link (possibly distinct from guide fragment link)
    $("#api_sub a.currentPage").removeClass("currentPage");
    $("#api_sub a[href='" + window.location.pathname + "']")
      .addClass("currentPage");

    // Fallback in case a bad fragment ID was requested
    if ($("#api_sub a.selected").length === 0) {
      console.log("waitToShowInTOC calling showInTOC as fallback.");
      showInTOC($("#api_sub a.currentPage"))
    }
  }
  else {
    console.log("waitToShowInTOC still waiting for",
                tocSection[0].id, sleepMillis);
    // back off and retry
    setTimeout(function(){ waitToShowInTOC(tocSection, 2 * sleepMillis) },
               sleepMillis);
  }
}

// Called via (edited) pjax module on popstate
function updateTocForUrlFragment(pathname, hash) {
  //console.log('updateTocForUrlFragment', pathname, hash);
  // Only let fragment links update the TOC when this is a user guide
  if (isUserGuide) {
    // IE doesn't include the "/" at the beginning of the pathname...
    //var fullLink = this.pathname + this.hash;
    var effective_hash = (hash == "") ? "#chapter" : hash;
    var fullLink = (pathname.indexOf("/") == 0 ? pathname : "/" + pathname) + effective_hash;

    console.log("Calling showInTOC from updateTocForUrlFragment");
    showInTOC($("#api_sub a[href='" + fullLink + "']"));
  }
}

// Expands and loads (if necessary) the part of the TOC containing the given link
// Also highlights the given link
// Called whenever a tab changes or a fragment link is clicked
function showInTOC(a) {
    console.log("showInTOC", a.href, a.length, a.parent().length);
    $("#api_sub a.selected").removeClass("selected");
    // e.g., arriving via back button
    $("#api_sub a.currentPage").removeClass("currentPage");

    var items = a.addClass("selected").parents("ul, li").add(
      a.nextAll("ul")).show();

    // If this is a TOC section that needs loading, then load it
    // e.g., when PJAX is enabled and the user clicks the link
    loadTocSection(0,a.parent());

    items.each(function(index) { expandSubTree($(this)); });

    scrollTOC();
}

// Called at init and whenever a tab changes.
// functionPageBucketId and tocSectionLinkSelector are from apidoc/view/page.xsl
function updateTocForTab() {
  console.log("updateTocForTab", functionPageBucketId, tocSectionLinkSelector);

  if (!functionPageBucketId) console.log(
      'no functionPageBucketId!');
  if (!tocSectionLinkSelector) console.log(
      'no tocSectionLinkSelector!');
  if (!functionPageBucketId && !tocSectionLinkSelector) return;

  var tocSectionLink = $(tocSectionLinkSelector);
  var tocSection = tocSectionLink.parent();
  //console.log("updateTocForTab", functionPageBucketId, tocSectionLinkSelector, tocSectionLink, tocSection);
  if (!tocSection.length) return;

  console.log("updateTocForTab loading to", tocSection);
  loadTocSection(0, tocSection);
  waitToShowInTOC(tocSection);
}

function hasText(item,text) {
    var fieldTxt = item.text().toLowerCase();
    if (fieldTxt.indexOf(text.toLowerCase()) !== -1)
        return true;
    else
        return false;
}

function addHighlightToText(element,filter) {
    this.removeHighlightToText(element);
    element.find('a').each(function(){
        var elemHTML = $(this).html();
        elemHTML = elemHTML.replace(new RegExp(filter, 'g'),'<span class="toc_highlight">' + filter + '</span>');
        $(this).html(elemHTML);                
    });

}

function removeHighlightToText(element) {
    var elemHTML = element.html();
    element.find('.toc_highlight').each(function() {                
        var pureText = $(this).text();
        elemHTML = elemHTML.replace(new RegExp('<span class="toc_highlight">' + pureText + '</span>', 'g'),pureText);
        element.html(elemHTML);          
    });
}

// called from hacked pjax script
function scrollContent(container, target) {
  var pageHeaderHeight = 71; // in CSS for #content
  var scrollTo = target.offset().top - pageHeaderHeight;
  container.scrollTop(scrollTo);
}

function scrollTOC() {
    //console.log("scrollTOC");
    var scrollTo = $('#api_sub a.selected').filter(':visible');
    //console.log("scrollTOC scrollTo", scrollTo);
    scrollTo.each(function() {
        var scrollableContainer = $(this).parents('.scrollable_section');
        //console.log("scrollTOC", scrollableContainer);
        var container = $(this).parents('.treeview'),
        extra = 120,
        currentTop = container.scrollTop(),
        headerHeight = 165, /* in CSS for .scrollable_section */
        scrollTarget = currentTop + $(this).offset().top,
        scrollTargetAdjusted = scrollTarget - headerHeight - extra,
        minimumSpaceAtBottom = 10,
        minimumSpaceAtTop = 10;

        // Only scroll if necessary
        var marginTop = currentTop + headerHeight + minimumSpaceAtTop;
        var marginBottom = currentTop + (
            container.height() - minimumSpaceAtBottom) ;
        if (scrollTarget < marginTop || scrollTarget > marginBottom) {
            container.animate({scrollTop: scrollTargetAdjusted}, 500);
        }
    });
}


function colorizeExamples() {
  $('#main div.example pre').each(function(i, me) {
      var editor = new CodeMirror(CodeMirror.replace(this), {
          path: "/js/CodeMirror-0.94/js/",
          parserfile: ["../contrib/xquery/js/tokenizexquery.js", 
                        "../contrib/xquery/js/parsexquery.js"],
          height: "dynamic",
          stylesheet: "/js/CodeMirror-0.94/contrib/xquery/css/xqcolors.css",
          readOnly: true,
          lineNumbers: false,
          content: $(this).text()
      });
  });
}

function formatFilterBoxes(filterBoxes) {
  var defaultFilterMsg = "Type to filter TOC...";

  filterBoxes.each(function() {
    // set the default message
    $(this).defaultvalue(defaultFilterMsg);
    // set the style
    if ($(this).val() == defaultFilterMsg) { $(this).addClass("default"); }
  });

  // set and remove the style based on user interaction
  filterBoxes.focus(function() {$(this).removeClass("default");} );
  filterBoxes.blur(function() {
    if ($(this).val() == defaultFilterMsg ||
        $(this).val() == "")
      $(this).addClass("default");
  });
}

function splitterMouseUp(evt) {
    //console.log("Splitter Mouse up: " + evt.pageX + " " + evt.pageY);
    $('#splitter').data("moving", false);
    $(document).off('mouseup', null, splitterMouseUp);
    $(document).off('mousemove', null, splitterMouseMove);

    $('#page_content').css("-webkit-user-select", "text");
    $('#toc_content').css("-webkit-user-select", "text");
    $('#content').css("-webkit-user-select", "text");
}

function splitterMouseMove(evt) {
    //console.log("Splitter Mouse move: " + evt.pageX + " " + evt.pageY);
    if ($('#splitter').data("moving")) {
        var m = 0 - $('#splitter').data('start-page_content');
        var d = Math.max(m, $('#splitter').data("start-x") - evt.pageX); 
        var w = $('#splitter').data("start-toc_content") - d;
        var init_w = 258; // TBD unhardcode

        if (w < init_w) {
            d -= init_w - w;
            w = init_w;
        }

        //console.log("Splitter Mouse move: " + d);
        $('#toc_content').css({'width': w + "px"});
        $('#page_content').css({'padding-right': ($('#splitter').data("start-page_content") + d) + "px"});
        $('#splitter').css({'left': ($('#splitter').data("start-splitter") - d) + "px"});
    }
}

function splitterMouseDown(evt) {
    //console.log("Splitter Mouse down: " + evt.pageX + " " + evt.pageY);
    $('#splitter').data("start-x", evt.pageX);
    $('#splitter').data("start-toc_content", parseInt($('#toc_content').css('width'), 10));
    $('#splitter').data("start-page_content", parseInt($('#page_content').css('padding-right'), 10));
    $('#splitter').data("start-splitter", parseInt($('#splitter').css('left'), 10));
    $('#splitter').data("moving", true);

    $(document).on('mouseup', null, splitterMouseUp);
    $(document).on('mousemove', null, splitterMouseMove);

    $('#toc_content').css("-webkit-user-select", "none");
    $('#page_content').css("-webkit-user-select", "none");
    $('#content').css("-webkit-user-select", "none");
}
