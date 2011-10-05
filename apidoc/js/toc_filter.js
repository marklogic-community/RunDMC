/* Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText = '';
var currentFilterText = '';

var previousFilterText2 = '';
var currentFilterText2 = '';

var previousFilterText3 = '';
var currentFilterText3 = '';

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
    tocRoot.find(".hasChildren").each(loadTocSection);
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
  var tocSection = $(tocSectionLinkSelector).first().parent();

  // Switch to the relevant tab
  var current_tab_index = $("#toc_tabs").tabs('option', 'selected');
  var new_tab_index = tocSection.parents(".tabbed_section").prevAll(".tabbed_section").length;

  /*
  console.log(tocSectionLinkSelector);
  console.log(tocSection);
  console.log(current_tab_index);
  console.log(new_tab_index);
  */

  if (current_tab_index !== new_tab_index) {
    // this triggers updateTocOnTabChange for us
    $("#toc_tabs").tabs('select',new_tab_index);
  }
  else { // otherwise, we have to do it ourselves
    var tab = $("#toc_tabs .tab_link").eq(current_tab_index);
    var panel = $("#toc_tabs .ui-tabs-panel:visible");

    /*
    console.log(tab);
    console.log(panel);
    */

    updateTocForTab(tab, panel);
  }
}

function waitToInitialize(tocSection) {
  // Repeatedly check to see if the TOC section has finished loading
  // Once it has, highlight the current page
  if (tocSection.hasClass("loaded")) {

    clearTimeout(waitToInitialize);

    var current = tocSection.find("a").filter(function() {
      return this.href.toLowerCase() == location.href.toLowerCase();
    });

    // E.g., when hitting the Back button and reaching "All functions"
    $("#sub a.selected").removeClass("selected");

    if (current.length) showInTOC(current);

    // Also show the currentPage link (possibly distinct from guide fragment link)
    $("#sub a.currentPage").removeClass("currentPage");
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
  }
  else {
    setTimeout(function(){ waitToInitialize(tocSection) }, 100);
  }
}


function bindFragmentLinkTocActions(context) {
  // Link bindings for updating the TOC state when navigating inside a user guide
  $(context).find("a[href^='" + window.location.pathname + "#']").add("a[href^='#']").not(".tab_link")
            .click(function() { updateTocForUrlFragment(this.pathname, this.hash) });
}

function updateTocForUrlFragment(pathname, hash) {

  // IE doesn't include the "/" at the beginning of the pathname...
  //var fullLink = this.pathname + this.hash;
  var fullLink = (pathname.indexOf("/") == 0 ? pathname : "/" + pathname) + hash;

  showInTOC($("#sub a[href='" + fullLink + "']"));

  scrollTOC();
}


function showInTOC(a) {
  $("#sub a.selected").removeClass("selected");
  $("#sub a.currentPage").removeClass("currentPage"); // e.g., arriving via back button

  var items = a.addClass("selected").parents("ul, li").add( a.nextAll("ul") ).show();

  loadTocSection(0,a.parent()); // If this is a TOC section that needs loading, then load it
                                // e.g., when PJAX is enabled and the user clicks the link

  items.each(function(index) {
    expandSubTree($(this));
  });
}


function updateTocOnTabChange(ui) {
  updateTocForTab(ui.tab, ui.panel);
}

function updateTocForTab(tab, panel) {
  //console.log(functionPageBucketId);

  if (tab.innerHTML == "Categories" && functionPageBucketId !== "") {
    var tocSection = $("#" + functionPageBucketId, panel);

    //console.log(tocSection);

    loadTocSection(0, tocSection);
    waitToInitialize(tocSection);
  }
  else {
    var tocSectionLink = $(tocSectionLinkSelector, panel);
    var tocSection = tocSectionLink.parent();
    if (tocSection.length) {
      loadTocSection(0, tocSection);
      waitToInitialize(tocSection);
    }
  }
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
