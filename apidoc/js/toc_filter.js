/* Copyright 2002-2014 MarkLogic Corporation.  All Rights Reserved. */
var breadcrumbNode = null;
var functionPageBucketId = null;
var isUserGuide = null;
var tocSectionLinkSelector = null;
var tocSelect = null;

$(function() {
    // When the DOM is ready, load the TOC into the TOC div.
    // Then finish with toc_init.
    $('#apidoc_toc').load($("#toc_url").val(), null, toc_init);

    colorizeExamples();

    // Don't use pjax on pdf, zip files, and printer-friendly links
    var selector = "#page_content .pjax_enabled"
        + " a:not(a[href$='.pdf'],a[href$='.zip'],a[target='_blank'])";
    $(selector).pjax({
        container: '#page_content',
        timeout: 4000,
        success: function() {
            // Update view when the pjax call originated from a link in the body
            console.log("pjax_enabled A fired ok", this);
            // The tocSectionLinkSelector may have changed.
            toc_init_globals();
            updateTocForSelection(); } });

    $("#api_sub .pjax_enabled a:not(.external)").pjax({
        container: '#page_content',
        timeout: 4000,
        success: function() {
            // Update view when a TOC link was clicked
            console.log("pjax_enabled B fired ok"); } });

    // Ensure that non-fragment TOC links highlight appropriate TOC links.
    $(document).on('pjax:end', function(event, options) {
        var target = $(event.relatedTarget);
        //console.log("pjax:end", event, options, target);
        if (target.parents("#api_sub").length) {
            console.log("Calling showInTOC via pjax:end handler.", target[0]);
            showInTOC(target); }});

    breadcrumbNode = $("#breadcrumbDynamic");
    if (!breadcrumbNode.length) console.log("No breadcrumb!");

    toc_init_globals();
});

function toc_init_globals() {
    console.log("toc_init_globals");

    // Initialize values from page.xsl content.
    functionPageBucketId = $("#functionPageBucketId");
    if (!functionPageBucketId.length) console.log("No functionPageBucketId!");
    functionPageBucketId = functionPageBucketId.val();

    isUserGuide = $("#isUserGuide");
    if (!isUserGuide.length) console.log("No isUserGuide!");
    isUserGuide = isUserGuide.val() === "true";

    tocSectionLinkSelector = $("#tocSectionLinkSelector");
    if (!tocSectionLinkSelector.length) console.log("No tocSectionLinkSelector!");
    tocSectionLinkSelector = tocSectionLinkSelector.val();
};

function toc_init() {
    console.log("toc_init");

    // This widget comes with the toc root via ajax, so init it here.
    var treeGlobal = $('#treeglobal');
    if (!treeGlobal.length) console.log("No treeglobal!");
    treeGlobal.show();
    treeGlobal.click(function(e) {
        var n = treeGlobal.children("span");
        var img = n.children("img");
        var label = n.children("span");
        var isExpand = label.text().trim() === "expand";
        // expand or collaps all
        var tree = $(".apidoc_tree:visible");
        if (isExpand) {
            label.text("collapse");
            expandAll(tree);
        } else {
            label.text("expand");
            collapseAll(tree);
        }
    });

    // Set up tree view select widget.
    var tocPartsDir = $("#tocPartsDir").text();
    tocSelect = $("#toc_select");
    if (!tocSelect) console.log("No tocSelect!");

    var tocTrees = $(".treeview");
    if (!tocTrees) console.log("No tocTrees!");
    // Be careful to init each tree individually, and only once!
    tocTrees.each(function(index, n) {
        $(n).treeview({
            prerendered: true,
            url: tocPartsDir }); });

    // Set up the select widget
    tocSelect.change(function(e) {
        console.log('TOC select option changed');
        // Hide the old TOC tree.
        $(".apidoc_tree:visible").hide()
        // Show the corresponding TOC tree.
        var n = tocSelect.children("option").filter(":selected");
        if (n.length == 0) console.log("tocSelect nothing selected!", n);
        if (n.length != 1) {
            console.log("tocSelect multiple selected!", n);
            // Continue with the first one.
            n = n.first();
        }

        var id = n.val();
        console.log("TOC select option changed to", n.val());
        var tree = $('#' + id);
        tree.show();
    });

    // Set up the filter
    var previousFilterText = '';
    $("#config-filter").keyup(function(e) {
        var currentFilterText = $(this).val();

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
                // The current TOC tree root should be visible.
                filterConfigDetails(currentFilterText,
                                    ".apidoc_tree:visible"); } },
                   350);
        $("#config-filter" + "-close-button").click(function() {
            $(this).hide();
            $("#config-filter").val("").keyup().blur();
        });
    });

    // default text, style, etc.
    formatFilterBoxes($(".config-filter"));

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
    updateTocForSelection();
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

function collapseSubTree(li) {
  if (li.children().is("ul")) {
    li.removeClass("collapsable").addClass("expandable");//.addClass("open");
    if (li.is(".lastCollapsable"))
      li.removeClass("lastCollapsable").addClass("lastExpandable");
    li.children("div").removeClass("collapsable-hitarea").addClass("expandable-hitarea");
    if (li.is(".lastCollapsable-hitarea"))
      li.children("div").removeClass("lastCollapsable-hitarea").addClass("lastExpandable-hitarea");
    li.children("ul").css("display","none");
  }
}

/* These functions implement the expand/collapse buttons */
function shallowExpandAll(ul) {
  ul.children("li").each(function(index) {
    loadTocSection(index, this);
    expandSubTree($(this));
  });
}

function shallowCollapseAll(ul) {
  ul.children("li").each(function(index) {
    collapseSubTree($(this));
  });
}

function expandAll(ul) {
  shallowExpandAll(ul);
  if (ul.children("li").children().is("ul"))
    ul.children("li").children("ul").each(function() {
      expandAll($(this));
    });
}

function collapseAll(ul) {
  shallowCollapseAll(ul);
  if (ul.children("li").children().is("ul"))
    ul.children("li").children("ul").each(function() {
      collapseAll($(this));
    });
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

// Called only from updateTocForSelection
function waitToShowInTOC(tocSection, sleepMillis) {
    console.log("waitToShowInTOC", tocSection[0].id, sleepMillis);
    if (!sleepMillis) sleepMillis = 125;

    // Repeatedly check to see if the TOC section has finished loading
    // Once it has, highlight the current page
    if (! tocSection.hasClass("loaded")) {
        console.log("waitToShowInTOC still waiting for",
                    tocSection[0].id, sleepMillis);
        // back off and retry
        setTimeout(function(){ waitToShowInTOC(tocSection, 2 * sleepMillis) },
                   sleepMillis);
        return;
    }

    console.log("waitToShowInTOC loaded", tocSection);

    clearTimeout(waitToShowInTOC);

    // Do not include query string. Do not include fragment.
    var locationHref = location.protocol+'//'+location.host+location.pathname;
    locationHref = locationHref.toLowerCase();
    //console.log("waitToShowInTOC", "locationHref=" + locationHref);
    var stripChapterFragment = isUserGuide && locationHref.indexOf("#") == -1;
    var stripMessage = isUserGuide && locationHref.indexOf('/messages/') != -1;
    var stripVersion = isUserGuide;

    // TODO needs special handling for /7.0/fn:abs vs /fn:abs ?

    //console.log("waitToShowInTOC", "stripMessage=" + stripMessage,
    //            "locationHref=" + locationHref);
    if (stripMessage) locationHref = locationHref.replace(
            /\/messages\/[a-z]+-[a-z]+\/[a-z]+-[a-z]+$/,
        '/guide/messages');

    //console.log("waitToShowInTOC", "stripVersion=" + stripVersion,
    //            "locationHref=" + locationHref);
    if (stripVersion) locationHref = locationHref.replace(
            /\/(\d+\.\d+)\/(\w+)\//,
            /guide/);

    console.log("waitToShowInTOC filtering for", locationHref);
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

    console.log("waitToShowInTOC found", current.length);
    if (current.length) showInTOC(current);

    // Also show the currentPage link (possibly distinct from guide fragment link)
    $("#api_sub a.currentPage").removeClass("currentPage");
    $("#api_sub a[href='" + window.location.pathname + "']")
        .addClass("currentPage");

    // Fallback in case a bad fragment ID was requested
    if ($("#api_sub a.selected").length === 0) {
        console.log("waitToShowInTOC: no selection. Calling showInTOC as fallback.");
        showInTOC($("#api_sub a.currentPage"))
    }
}

// Called via (edited) pjax module on popstate
function updateTocForUrlFragment(pathname, hash) {
    console.log('updateTocForUrlFragment', pathname, hash, isUserGuide);
    // Only let fragment links update the TOC when this is a user guide.
    // Or not! The back button should update the TOC for functions too.
    //if (!isUserGuide) return;

    // IE doesn't include the "/" at the beginning of the pathname...
    //var fullLink = this.pathname + this.hash;
    var effective_hash = (isUserGuide && hash == "") ? "#chapter" : hash;
    var fullLink = (pathname.indexOf("/") == 0 ? pathname : "/" + pathname)
        + effective_hash;

    console.log("Calling showInTOC from updateTocForUrlFragment", fullLink);
    showInTOC($("#api_sub a[href='" + fullLink + "']"));
}

// Expands and loads (if necessary) the part of the TOC containing the given link
// Also highlights the given link
// Called whenever TOC selection changes.
function showInTOC(a) {
    console.log("showInTOC", 'link', a.length, 'parent', a.parent().length);
    $("#api_sub a.selected").removeClass("selected");
    // e.g., arriving via back button
    $("#api_sub a.currentPage").removeClass("currentPage");

    if (a.length === 0) {
        console.log("showInTOC: no link!");
        return;
    }

    // If there is a different TOC section visible, hide it.
    var treeVisible = $(".apidoc_tree:visible");
    var treeForA = a.parents(".apidoc_tree");
    console.log("showInTOC",
                "visible", treeVisible.attr('id'),
                "a", treeForA.attr('id'));
    if (treeForA.length === 1
        && treeForA.attr('id') != treeVisible.attr('id')) {
        treeVisible.hide();
        // Update the selector to match.
        var options = tocSelect.children("option");
        //console.log(options.filter(":selected"));
        options.filter(":selected").removeAttr('selected');
        var id = treeForA.attr('id');
        var selector = "[value='" + id + "']";
        //console.log(options.filter(selector));
        options.filter(selector).attr('selected', 'true');
    }

    // Climb up to the section level.
    var li = a.parent().parent().parent();
    updateBreadcrumb(li);

    var items = a.addClass("selected").parents("ul, li").add(
      a.nextAll("ul")).show();

    // If this is a TOC section that needs loading, then load it
    // e.g., when PJAX is enabled and the user clicks the link
    loadTocSection(0,a.parent());

    items.each(function(index) { expandSubTree($(this)); });

    scrollTOC();
}

function breadcrumbChrome() {
    // Must create a new text node for each call.
    return document.createTextNode(' > ');
}

function breadcrumbBuilder(results, n) {
    var stage;
    var text;
    var links = n.children('a');
    if (links.length) {
        // Link to appropriate level.
        stage = $('<a>').attr('href', links.attr('href'));
        text = links.contents()[0];
    } else {
        // Display only, not linkable.
        stage = $('<span>');
        text = n.children("span").contents()[0];
    }
    //console.log('breadcrumbBuilder', stage, text);
    // Halt recursion if we did not find anything.
    if (!text) {
        console.log('breadcrumbBuilder: no text found', results.length);
        return results;
    }

    text = text.data.replace(/[:\.]$/, '').replace(/\s+\(\d+\)/, "");
    //console.log('breadcrumbBuilder', n[0], text);
    stage.text(text);
    results = results.concat(stage[0]).concat(breadcrumbChrome());
    //console.log('breadcrumbBuilder', text, results.length);

    // Climb the tree to the next li, if there is one.
    // The immediate parent should be a ul.
    var parent = n.parent().parent().filter("li");
    if (!parent.length) {
        //console.log('breadcrumbBuilder: no parent found', results.length);
        // This must be the top. Add a label for it and halt.
        return results.concat(
                document.createTextNode(
                    tocSelect.children("option:selected").text()))
            .concat(breadcrumbChrome());
    }

    // recurse
    return breadcrumbBuilder(results, parent);
}

function updateBreadcrumb(n)
{
    //console.log('updating breadcrumb', n.length ? n[0] : null);
    breadcrumbNode.empty();
    var breadcrumb = breadcrumbBuilder([], n).reverse();
    //console.log('updating breadcrumb', breadcrumb);
    if (!breadcrumb || !breadcrumb.length) return;
    breadcrumbNode.append(breadcrumb);
}

// Called at init and whenever TOC selection changes.
function updateTocForSelection() {
    console.log("updateTocForSelection",
                "functionPageBucketId", functionPageBucketId,
                "tocSectionLinkSelector", tocSectionLinkSelector);

    if (!tocSectionLinkSelector) {
        console.log('no tocSectionLinkSelector!');
        return;
    }

    var tocSectionLink = $(tocSectionLinkSelector);
    var tocSection = tocSectionLink.parent();
    if (0 == tocSection.length) {
        console.log("updateTocForSelection",
                    functionPageBucketId, tocSectionLinkSelector,
                    "nothing selected!");
        return;
    }
    if (1 != tocSection.length) {
        console.log("updateTocForSelection",
                    functionPageBucketId, tocSectionLinkSelector,
                    "multiple selected!", tocSection);
        // Continue with the first one.
        tocSection = tocSection.first();
    }

    updateBreadcrumb(tocSection);

    console.log("updateTocForSelection loading to", tocSection);
    loadTocSection(0, tocSection);
    waitToShowInTOC(tocSection);
}

function hasText(item,text) {
    var fieldTxt = item.text().toLowerCase();
    return (fieldTxt.indexOf(text.toLowerCase()) !== -1);
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
    console.log("scrollTOC scrollTo", scrollTo.length);
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

        var marginTop = currentTop + headerHeight + minimumSpaceAtTop;
        var marginBottom = currentTop + (
            container.height() - minimumSpaceAtBottom) ;
        container.animate({scrollTop: scrollTargetAdjusted}, 500);
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
        $('#page_content').css({'padding-right':
                                ($('#splitter').data("start-page_content") + d)
                                + "px"});
        $('#splitter').css({'left':
                            ($('#splitter').data("start-splitter") - d)
                            + "px"});
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

// toc_filter.js
