/* Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText = '';
var currentFilterText = '';

var previousFilterText2 = '';
var currentFilterText2 = '';

var previousFilterText3 = '';
var currentFilterText3 = '';

function filterConfigDetails(text, treeSelector) {

    // Filter only the first section of the TOC
    var tocRoot = $(treeSelector).children("li:first");

    // Make sure "All functions" container after each search (even if empty results)
    // TODO: Figure out how to directly call the "toggler" method from the treeview code rather than using this
    //       implementation-specific stuff

    loadAllSubSections(tocRoot);

    if (tocRoot.hasClass("fullyLoaded"))
      searchTOC(text, tocRoot);
    else
      waitToSearch(text, tocRoot);

    expandSubTree(tocRoot);
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
            } else {
                /*
                removeHighlightToText($(this));
                */
                $(this).addClass("hide-detail");
            }
        }            
    });
}

// This logic is essentially duplicated from the treeview plugin...bad, I know
function expandSubTree(li) {
  if (li.children().is("ul")) {
    li.removeClass("expandable").addClass("collapsable");//.addClass("open");
    if (li.is(".lastExpandable"))
      li.removeClass("lastExpandable").addClass("lastCollapsable");
    li.children("div").removeClass("expandable-hitarea").addClass("collapsable-hitarea");
    if (li.is(".lastExpandable-hitarea"))
      li.children("div").removeClass("lastExpandable-hitarea").addClass("lastCollapsable-hitarea");
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
    loadTocSection(index,this);
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



function loadAllSubSections(tocRoot) {
  if (!tocRoot.hasClass("startedLoading")) {
    tocRoot.children("ul").children("li").each(loadTocSection);
    tocRoot.addClass("startedLoading");
  }
}

function loadTocSection(index, tocSection) {
  var $tocSection = $(tocSection);
  if ($tocSection.hasClass("hasChildren"))
    $tocSection.find(".hitarea").trigger("click");
}


function initializeTOC() {
  // Load the TOC section for the current page
  var tocSection = $(tocSectionLinkSelector).parent();
  loadTocSection(0,tocSection);

  waitToInitialize(tocSection);
}

function waitToInitialize(tocSection) {
  // Repeatedly check to see if the TOC section has finished loading
  // Once it has, highlight the current page
  if (tocSection.hasClass("loaded")) {
    var current = tocSection.find("a").filter(function() {
      return this.href.toLowerCase() == location.href.toLowerCase();
    });

    if (current.length) showInTOC(current);

    // Also show the currentPage link (possibly distinct from guide fragment link)
    $("#sub a[href=" + window.location.pathname + "]").addClass("currentPage");

    // Fallback in case a bad fragment ID was requested
    if ($("#sub a.selected").length === 0) {
      showInTOC($("#sub a.currentPage"))
    }

    if (!tocSection.hasClass("initialized")) {
      bindFragmentLinkTocActions(tocSection);
      tocSection.addClass("initialized");
    }

    scrollTOC();
    
    clearTimeout(waitToInitialize);
  }
  else
    setTimeout(function(){ waitToInitialize(tocSection) }, 100);
}


function bindFragmentLinkTocActions(context) {
  // Link bindings for updating the TOC state when navigating inside a user guide
  $(context).find("a[href^='" + window.location.pathname + "#']").add("a[href^='#']").not(".tab_link").click(function() {
    $("#sub a.selected").removeClass("selected");

    // IE doesn't include the "/" at the beginning of the pathname...
    //var fullLink = this.pathname + this.hash;
    var fullLink = (this.pathname.indexOf("/") == 0 ? this.pathname : "/" + this.pathname) + this.hash;

    showInTOC($("#sub a[href='" + fullLink + "']"));

    scrollTOC();
  });
}


// For when someone clicks an intra-document link outside of the TOC itself
function showInTOC(a) {
  var items = a.addClass("selected").parents("ul, li").add( a.nextAll("ul") ).show();

  loadTocSection(0,a.parent()); // If this is a TOC section that needs loading, then load it

  items.each(function(index) {
    expandSubTree($(this));
  });

  // Switch to the tab of the first instance
  var tab_index = a.first().parents(".tabbed_section").prevAll(".tabbed_section").length;
  $("#toc_tabs").tabs('select',tab_index);
}


function updateTocOnTabChange(ui) {
  if (ui.tab.innerHTML == "Categories" && typeof functionPageBucketId !== "undefined") {
    var tocSection = $("#" + functionPageBucketId, ui.panel);
    loadTocSection(0, tocSection);
    waitToInitialize(tocSection);
  };
  if (ui.tab.innerHTML == "API") {
    var tocSectionLink = $(tocSectionLinkSelector, ui.panel);
    var tocSection = tocSectionLink.parent();
    if (tocSection.length) {
      loadTocSection(0, tocSection);
      waitToInitialize(tocSection);
    }
  };
  scrollTOC();
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

function scrollTOC() {
  var scrollTo = $('#sub a.selected').filter(':visible');

  scrollTo.each(function() {
    var container = $(this).parents('.scrollable_section'),
        extra = 80,
        currentTop = container.scrollTop(),
        headerHeight = 165, /* in CSS for .scrollable_section */
        scrollTargetDistance = $(this).offset().top,
        scrollTarget = currentTop + scrollTargetDistance,
        scrollTargetAdjusted = scrollTarget - headerHeight - extra,
        minimumSpaceAtBottom = 10,
        minimumSpaceAtTop = 10;

  /*
  console.log(this);
  console.log(container);
  alert("currentTop: " + currentTop);
  alert("headerHeight: " + headerHeight);
  alert("scrollTargetDistance: " + scrollTargetDistance);
  alert("scrollTarget: " + scrollTarget);
  alert("scrollTargetAdjusted: " + scrollTargetAdjusted);
  */

    // Only scroll if necessary
    if (scrollTarget < currentTop + headerHeight + minimumSpaceAtTop
     || scrollTarget > currentTop + (container.height() - minimumSpaceAtBottom)) {
      container.animate({scrollTop: scrollTargetAdjusted}, 500);
    }
  });
}



