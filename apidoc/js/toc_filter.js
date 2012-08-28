/* Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText1 = '';
var currentFilterText1 = '';

var previousFilterText2 = '';
var currentFilterText2 = '';

var previousFilterText3 = '';
var currentFilterText3 = '';

var previousFilterText4 = '';
var currentFilterText4 = '';

var previousFilterText5 = '';
var currentFilterText5 = '';

var previousFilterText6 = '';
var currentFilterText6 = '';

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



function loadAllSubSections(tocRoot) {
  if (!tocRoot.hasClass("startedLoading")) {
    tocRoot.find(".hasChildren").each(loadTocSection);
    tocRoot.addClass("startedLoading");
  }
}

// We may ignore index, but it's necessary as part of the signature expected by .each()
function loadTocSection(index, tocSection) {
  var $tocSection = $(tocSection);
  if ($tocSection.hasClass("hasChildren"))
    $tocSection.find(".hitarea").trigger("click");
}


// Switches to the appropriate TOC tab
// Called when the initial TOC is loaded (full page load)
// and when a pjax load finishes (including via back button)
function changeToAppropriateTab() {
  // Load the TOC section for the current page
  var tocSection = $(tocSectionLinkSelector).first().parent();

  // Switch to the relevant tab
  var current_tab_index = $("#toc_tabs").tabs('option', 'selected');
  var new_tab_index = tocSection.parents(".tabbed_section").prevAll(".tabbed_section").length;

  //console.log(tocSectionLinkSelector);
  //console.log(tocSection);
  //console.log(current_tab_index);
  //console.log(new_tab_index);

  if (current_tab_index !== new_tab_index) {
    // this triggers updateTocForTab for us
    $("#toc_tabs").tabs('select',new_tab_index);
  }
  else { // otherwise, we have to do it ourselves
    var tab = $("#toc_tabs .tab_link").eq(current_tab_index)[0];
    var panel = $("#toc_tabs .ui-tabs-panel:visible")[0];

    //console.log(tab);
    //console.log(panel);

    //console.log("Calling updateTocForTab from changeToAppropriateTab");
    updateTocForTab(tab, panel);
  }
}

// Called only from updateTocForTab
function waitToShowInTOC(tocSection) {
  // Repeatedly check to see if the TOC section has finished loading
  // Once it has, highlight the current page
  if (tocSection.hasClass("loaded")) {

    clearTimeout(waitToShowInTOC);

    var current = tocSection.find("a").filter(function() {
      return this.href.toLowerCase() == location.href.toLowerCase();
    });

    // E.g., when hitting the Back button and reaching "All functions"
    $("#api_sub a.selected").removeClass("selected");

    if (current.length) {/*console.log("Calling showInTOC from waitToShowInTOC");*/ showInTOC(current);}

    // Also show the currentPage link (possibly distinct from guide fragment link)
    $("#api_sub a.currentPage").removeClass("currentPage");
    $("#api_sub a[href='" + window.location.pathname + "']").addClass("currentPage");

    // Fallback in case a bad fragment ID was requested
    if ($("#api_sub a.selected").length === 0) {
      //console.log("Calling showInTOC as fallback.");
      showInTOC($("#api_sub a.currentPage"))
    }

    /*
    if (!tocSection.hasClass("initialized")) {
      bindFragmentLinkTocActions(tocSection);
      tocSection.addClass("initialized");
    }
    */
  }
  else {
    setTimeout(function(){ waitToShowInTOC(tocSection) }, 100);
  }
}


/*
function bindFragmentLinkTocActions(context) {
  // Link bindings for updating the TOC state when navigating inside a user guide
  $(context).find("a[href^='" + window.location.pathname + "#']").add("a[href^='#']").not(".tab_link")
            .click(function() { updateTocForUrlFragment(this.pathname, this.hash) });
}
*/

// Called via (edited) pjax module on popstate
function updateTocForUrlFragment(pathname, hash) {
  // Only let fragment links update the TOC when this is a user guide
  if (isUserGuide) {
    // IE doesn't include the "/" at the beginning of the pathname...
    //var fullLink = this.pathname + this.hash;
    var fullLink = (pathname.indexOf("/") == 0 ? pathname : "/" + pathname) + hash;

    //console.log("Calling showInTOC from updateTocForUrlFragment");
    showInTOC($("#api_sub a[href='" + fullLink + "']"));
  }
}


// Expands and loads (if necessary) the part of the TOC containing the given link
// Also highlights the given link
// Called whenever a tab changes or a fragment link is clicked
function showInTOC(a) {
  //console.log(a);
  $("#api_sub a.selected").removeClass("selected");
  $("#api_sub a.currentPage").removeClass("currentPage"); // e.g., arriving via back button

  var items = a.addClass("selected").parents("ul, li").add( a.nextAll("ul") ).show();

  loadTocSection(0,a.parent()); // If this is a TOC section that needs loading, then load it
                                // e.g., when PJAX is enabled and the user clicks the link

  items.each(function(index) {
    expandSubTree($(this));
  });

  scrollTOC();
}


var functionsPanelId = "tabs-1";
var categoriesPanelId = "tabs-2";
var functionPanelIndex = 0;
var categoriesPanelIndex = 1;

// Called when a user changes the radio button
function toggleFunctionsView(input) {
  // Switch to the relevant tab
  var new_tab_index = (input.val() === 'by_name') ? functionPanelIndex : categoriesPanelIndex;
  $("#toc_tabs").tabs('select',new_tab_index);
  //console.log("Toggling function view...");
}

// Called whenever a tab changes; also called explicitly from changeToAppropriateTab
// when the initial tab is unchanged
function updateTocForTab(tab, panel) {
  //console.log(functionPageBucketId);
  //console.log("updateTocForTab called");

  // Hide the view toggle buttons if this isn't the functions or categories panel
  if (panel.id == categoriesPanelId || panel.id == functionsPanelId)
  {
    // Show the radio buttons
    $("#function_view_buttons").show();

    // Ensure the correct radio button is checked (e.g. when first loading a page that's only in the categories TOC)
    var correctRadioButtonValue = (panel.id == functionsPanelId) ? "by_name" : "by_category";
    var radioButton = $("input[name=function_view][value="+correctRadioButtonValue+"]");
    radioButton.attr("checked","checked");

    // Show the tab selected by the radio button; hide the other
    var functionsTab  = $("#tab_bar a[href=#"+ functionsPanelId+"]").parent("li");
    var categoriesTab = $("#tab_bar a[href=#"+categoriesPanelId+"]").parent("li");

    if (panel.id == functionsPanelId) {
      functionsTab.show();
      categoriesTab.hide();
    }
    else {
      functionsTab.hide();
      categoriesTab.show();
    }
  }
  else
    $("#function_view_buttons").hide();

  // When the user clicks on the "Categories" tab when on a function or list page
  if (panel.id == categoriesPanelId && functionPageBucketId !== "") {
    var tocSection = $("#" + functionPageBucketId, panel);

    //console.log(tocSection);

    loadTocSection(0, tocSection);
    waitToShowInTOC(tocSection);
  }
  else {
    var tocSectionLink = $(tocSectionLinkSelector, panel);
    var tocSection = tocSectionLink.parent();

    if (tocSection.length) {
      //console.log("Loading tocSection");
      //console.log(tocSection);
      loadTocSection(0, tocSection);
      waitToShowInTOC(tocSection);
    }
  }
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
  var scrollTo = $('#api_sub a.selected').filter(':visible');

  scrollTo.each(function() {
/*
    var container = $(this).parents('.scrollable_section'),
*/
    var container = $(this).parents('.treeview'),
        extra = 120,
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

function splitterMouseUp(evt) {
    // console.log("Splitter Mouse up: " + evt.pageX + " " + evt.pageY);
    $('#splitter').data("moving", false);
    $(document).off('mouseup', null, splitterMouseUp);
    $(document).off('mousemove', null, splitterMouseMove);

    $('#page_content').css("-webkit-user-select", "text");
    $('#tab_content').css("-webkit-user-select", "text");
    $('#content').css("-webkit-user-select", "text");
}

function splitterMouseMove(evt) {
    //console.log("Splitter Mouse move: " + evt.pageX + " " + evt.pageY);
    if ($('#splitter').data("moving")) {
        var m = 0 - $('#splitter').data('start-page_content');
        var d = Math.max(m, $('#splitter').data("start-x") - evt.pageX); 
        var w = $('#splitter').data("start-tab_content") - d;
        var init_w = 258; // TBD unhardcode

        if (w < init_w) {
            d -= init_w - w;
            w = init_w;
        }

        //console.log("Splitter Mouse move: " + d);
        $('#tab_content').css({'width': w + "px"});
        $('#page_content').css({'padding-right': ($('#splitter').data("start-page_content") + d) + "px"});
        $('#splitter').css({'left': ($('#splitter').data("start-splitter") - d) + "px"});
    }
}

function splitterMouseDown(evt) {
    //console.log("Splitter Mouse down: " + evt.pageX + " " + evt.pageY);
    $('#splitter').data("start-x", evt.pageX);
    $('#splitter').data("start-tab_content", parseInt($('#tab_content').css('width'), 10));
    $('#splitter').data("start-page_content", parseInt($('#page_content').css('padding-right'), 10));
    $('#splitter').data("start-splitter", parseInt($('#splitter').css('left'), 10));
    $('#splitter').data("moving", true);

    $(document).on('mouseup', null, splitterMouseUp);
    $(document).on('mousemove', null, splitterMouseMove);

    $('#tab_content').css("-webkit-user-select", "none");
    $('#page_content').css("-webkit-user-select", "none");
    $('#content').css("-webkit-user-select", "none");
}
