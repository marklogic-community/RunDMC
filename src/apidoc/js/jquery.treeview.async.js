/*
 * Async Treeview 0.1 - Lazy-loading extension for Treeview
 * 
 * http://bassistance.de/jquery-plugins/jquery-plugin-treeview/
 *
 * Copyright (c) 2007 Jörn Zaefferer
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id$
 *
 */

if (typeof String.prototype.endsWith != 'function') {
  String.prototype.endsWith = function (str){
    return this.slice(-str.length) == str;
  };
}

if (typeof String.prototype.startsWith != 'function') {
  String.prototype.startsWith = function (str){
    return this.slice(0, str.length) == str;
  };
}

;(function($) {


function load(settings, rootId, child, container) {
//console.log("async.load", settings, rootId, child, container);
	function createNode(parent) {
		var current = $("<li/>").attr("id", this.id || "").html("<span>" + this.text + "</span>").appendTo(parent);
		if (this.classes) {
			current.children("span").addClass(this.classes);
		}
		if (this.expanded) {
			current.addClass("open");
		}
		if (this.hasChildren || this.children && this.children.length) {
			var branch = $("<ul/>").appendTo(current);
			if (this.hasChildren) {
				current.addClass("hasChildren");
				createNode.call({
					classes: "placeholder",
					text: "&nbsp;",
					children:[]
				}, branch);
			}
			if (this.children && this.children.length) {
				$.each(this.children, createNode, [branch])
			}
		}
	}
	$.ajax($.extend(true, {
    //EDL: START of changes I made (commented out original lines)
		//url: settings.url,
            // For javascript pages we need to rewrite the id a bit.
      url: settings.url
                + (rootId.startsWith("js_")
                   ? "js/" + rootId.substring(3)
                   : rootId)
                + ".html",
		//dataType: "json",
		  dataType: "html",
    /*
		data: {
			root: rootId
		},
    */
		success: function(response) {
			//child.empty();
      // EDL: Don't call createNode; just insert the retrieved HTML
      var newChild = $(response);
      child.parent().addClass("loaded");
      child.replaceWith(newChild);
			//$.each(response, createNode, [child]);
	    //$(container).treeview({add: child});
	      $(container).treeview({add: newChild});
      //EDL: END of changes I made
	    }
     // EDL: START CHANGES
     // If there's an error, assume it's an old TOC part (or connectivity problem) and force a refresh
     ,error: function(jqXHR, textStatus, errorThrown) {
       console.log("jquery.treeview.async.error",
                   jqXHR, textStatus, errorThrown);
       // mblakele: or not!
       //window.location.reload();
     }
     // EDL: END CHANGES
	}, settings.ajax));
	/*
	$.getJSON(settings.url, {root: rootId}, function(response) {
		function createNode(parent) {
			var current = $("<li/>").attr("id", this.id || "").html("<span>" + this.text + "</span>").appendTo(parent);
			if (this.classes) {
				current.children("span").addClass(this.classes);
			}
			if (this.expanded) {
				current.addClass("open");
			}
			if (this.hasChildren || this.children && this.children.length) {
				var branch = $("<ul/>").appendTo(current);
				if (this.hasChildren) {
					current.addClass("hasChildren");
					createNode.call({
						classes: "placeholder",
						text: "&nbsp;",
						children:[]
					}, branch);
				}
				if (this.children && this.children.length) {
					$.each(this.children, createNode, [branch])
				}
			}
		}
		child.empty();
		$.each(response, createNode, [child]);
        $(container).treeview({add: child});
    });
    */
}

var proxied = $.fn.treeview;
$.fn.treeview = function(settings) {
	if (!settings.url) {
		return proxied.apply(this, arguments);
	}
	var container = this;
	if (!container.children().size())
		load(settings, "source", this, container);
	var userToggle = settings.toggle;
	return proxied.call(this, $.extend({}, settings, {
		collapsed: true,
		toggle: function() {
			var $this = $(this);
			if ($this.hasClass("hasChildren")) {
				var childList = $this.removeClass("hasChildren").find("ul");
				load(settings, this.id, childList, container);
			}
			if (userToggle) {
				userToggle.apply(this, arguments);
			}
		}
	}));
};

})(jQuery);
