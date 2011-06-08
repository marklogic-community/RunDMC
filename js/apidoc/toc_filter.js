/* Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved. */
var previousFilterText = '';
var currentFilterText = '';

function filterConfigDetails(text) {
    var filter = text;

    // Filter only the first section of the TOC
    var allFunctionsRoot = $("#apidoc_tree").children("li:first");

    // Make sure "All functions" container after each search (even if empty results)
    // TODO: Figure out how to directly call the "toggler" method from the treeview code rather than using this
    //       implementation-specific stuff
    if (allFunctionsRoot.is(".expandable")) {
      allFunctionsRoot.removeClass("expandable").addClass("collapsable");
      allFunctionsRoot.children("div").removeClass("expandable-hitarea").addClass("collapsable-hitarea");
      allFunctionsRoot.children("ul").css("display","block");
    };

    allFunctionsRoot.find("li").each(function() {
        $(this).removeClass("hide-detail");
        /*
        if (filter == '') {
            removeHighlightToText($(this));
        } else {
        */
        if (filter !== '') {
            if (hasText($(this),filter)) {
                if ($(this).find("ul").length == 0)
                    "do nothing"
                    /* Temporarily disable highlighting as it's too slow (particularly when removing the highlight).
                     * Also, buggy in its interaction with the treeview control: branches may no longer respond to clicks
                     * (presumably due to the added spans).
                    addHighlightToText($(this),filter); // then this is a leaf node, so u can perform highlight
                    */
                else {
                    // Expand the TOC sub-tree
                    // TODO: Figure out how to directly call the "toggler" method from the treeview code rather than using this
                    //       implementation-specific code (also, buggy w.r.t. last child - "xp" in TOC)
                    $(this).removeClass("expandable").addClass("collapsable");/*.addClass("open");*/
                    $(this).children("div").removeClass("expandable-hitarea").addClass("collapsable-hitarea");
                    $(this).children("ul").css("display","block");
                }
            } else {
                /*
                removeHighlightToText($(this));
                */
                $(this).addClass("hide-detail");
            }
        }            
    });
}

function hasText(item,text) {
    var fieldTxt = item.text();
    if (fieldTxt.indexOf(text) !== -1)
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
                filterConfigDetails(currentFilterText);
            }            
        },350);        
    });
    
});
