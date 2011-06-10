/* Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText = '';
var currentFilterText = '';

var previousFilterText2 = '';
var currentFilterText2 = '';

var previousFilterText3 = '';
var currentFilterText3 = '';

function filterConfigDetails(text, treeSelector) {
    var filter = text;

    // Filter only the first section of the TOC
    var allFunctionsRoot = $(treeSelector).children("li:first");

    // Make sure "All functions" container after each search (even if empty results)
    // TODO: Figure out how to directly call the "toggler" method from the treeview code rather than using this
    //       implementation-specific stuff
    /*
    if (allFunctionsRoot.is(".expandable")) {
    */
console.log(allFunctionsRoot);
      expandSubTree(allFunctionsRoot);
      /*
      allFunctionsRoot.removeClass("expandable").addClass("collapsable");
      allFunctionsRoot.children("div").removeClass("expandable-hitarea").addClass("collapsable-hitarea");
      allFunctionsRoot.children("ul").css("display","block");
      */
    /*
    };
    */

    allFunctionsRoot.find("li").each(function() {
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
      shallowExpandAll($(this));
    });
}

function collapseAll(ul) {
  shallowCollapseAll(ul);
  if (ul.children("li").children().is("ul"))
    ul.children("li").children("ul").each(function() {
      shallowCollapseAll($(this));
    });
}

$(document).ready(function(){
  $(".shallowExpand").click(function(event){
    shallowExpandAll($(this).parent().nextAll("ul"));
  });
  $(".shallowCollapse").click(function(event){
    shallowCollapseAll($(this).parent().nextAll("ul"));
  });
  $(".expand").click(function(event){
    expandAll($(this).parent().nextAll("ul"));
  });
  $(".collapse").click(function(event){
    collapseAll($(this).parent().nextAll("ul"));
  });
});


/*
function expandAll(item) {
  item
}
*/



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


$(function() {

    $("#config-filter").keyup(function(e) {
        currentFilterText = $(this).val();
        setTimeout(function() {
            if (previousFilterText !== currentFilterText){
                previousFilterText = currentFilterText;
                filterConfigDetails(currentFilterText,"#apidoc_tree");
            }            
        },350);        
    });
});

$(function() {

    $("#config-filter2").keyup(function(e) {
        currentFilterText2 = $(this).val();
        setTimeout(function() {
            if (previousFilterText2 !== currentFilterText2){
                previousFilterText2 = currentFilterText2;
                filterConfigDetails(currentFilterText2,"#apidoc_tree2");
            }            
        },350);        
    });
    
});

$(function() {

    $("#config-filter3").keyup(function(e) {
        currentFilterText3 = $(this).val();
        setTimeout(function() {
            if (previousFilterText3 !== currentFilterText3){
                previousFilterText3 = currentFilterText3;
                filterConfigDetails(currentFilterText3,"#apidoc_tree3");
            }            
        },350);        
    });
    
});
