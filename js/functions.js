if(typeof jQuery != 'undefined') {
	$(function() {
		$('body').addClass('jsenabled'); // this class is applied to have a selector to add functionality with CSS later on that would only make sense if JS is actually enabled/available
		if(jQuery().defaultvalue) {
			$("#s_inp, #ds_inp, #kw_inp").defaultvalue(
	        "Search the site",
	        "Search current document",
	        "Search documents by keyword"
	    );
		}
		$('#sub > div:last-child').addClass('last'); // only supposed to add some last-child functionality to IE
		if(jQuery().tabs) {
			$('#special_intro .nav').tabs('#special_intro > div',{
				//effect: 'fade',
				tabs: 'li'
			});
		}
		// accordion style menu
		$('#sub .subnav h2, #sub .subnav li span').each(function() {
			if(!($(this).next().children().is('.current'))) {
				$(this).addClass('closed').next().hide();
			}
		})
		
		$('#sub .current').parents().show();
		$('#sub .subnav h2, #sub .subnav li span').click(function() {
			$(this).toggleClass('closed').next().toggle('normal');
		});
		// overlay functions
		if(jQuery().overlay) {
			$('body').append('<div class="overlay" id="overlay"><div class="overlayContent"></div></div>');
			//signup overlay
			$('#utilnav .signup a').attr('rel','#overlay').overlay({
				expose: 'black',
				left: 'center',
				closeOnClick: false,
				onBeforeLoad: function() { 
	        var wrap = this.getContent().find(".overlayContent"); 
	      	wrap.load(this.getTrigger().attr("href") + ' .popup');
	      },
	      onLoad: function() {
	   			$('.popup input[type=reset]').replaceWith('<input type="button" class="cancel" value="Cancel" />');
    			$('.popup input.cancel').click(function() {
    				$('#utilnav .signup a[rel]').overlay().close();
    			});
}
      });
      // generic function to prevent form submission for certain submit buttons
      function preventSubmit(form,trigger) {
	      $(form).submit(function(e) {
	        if (e.originalEvent.explicitOriginalTarget.name == trigger || e.originalEvent.explicitOriginalTarget.className == trigger) {
	          e.preventDefault();
	          return false;
	        }
	    	});
    	}
    	// invoke specific submission prevention
    	preventSubmit('form#codeedit','add_media');
      // begin add media overlay
      $('input[name=add_media]').wrap('<a href="adminAddMedia.html" rel="#overlay"></a>"');
			$('input[name=add_media]').parent('a[rel]').overlay({
				expose: 'black',
				left: 'center',
				closeOnClick: false,
				onBeforeLoad: function() { 
	        var wrap = this.getContent().find(".overlayContent"); 
	      	wrap.load(this.getTrigger().attr("href") + ' #addmedia');
	      },
	      onLoad: function() {
		      $('#overlay #addmedia div ul li').click(function() {
		      	$(this).children('input').attr('checked','checked');
		      	$(this).siblings().removeClass('selected');
		      	$(this).addClass('selected');
		      });
    			$('input[name=media_cancel]').replaceWith('<button type="button" class="close">Cancel</button>')
    			$('button.close').click(function() {
    				$('input[name=add_media]').parent('a[rel]').overlay().close();
    			});
	      }
      });
      // end add media overlay
		}// end “if jQuery overlay”
		// begin “add author” functionality
		$('input[name=add_author]').replaceWith('<a class="add_remove add_author">+&nbsp;Add author</a>');
		var removeAuthor = ' <a class="add_remove remove_author">-&nbsp;Remove author</a>';
		$('a.add_author').click(function() {
			$(this).parent().before('<div><input name="author[]" type="text" />' + removeAuthor + '</div>');
				if($('input[name=author\[\]]').length == 2) {
					$('input[name=author\[\]]:first').after(removeAuthor);
				}
			$('a.remove_author').click(function() {
				$(this).parent().remove();
				if($('input[name=author\[\]]').length == 1) {
					$('a.remove_author').remove();
				}
			});
		});
		// end “add author” functionality
		// begin “add link” functionality
		$('input[name=add_link]').replaceWith('<a class="add_remove add_link">+&nbsp;Add link</a>');
		var removeLink = ' <a class="add_remove remove_link">-&nbsp;Remove link</a>';
		$('a.add_link').click(function() {
			$('#ce_link').parent().after('<div><input name="link[]" type="text" />' + removeLink + '</div>');
				if($('input[name=link\[\]]').length == 2) {
					$('input[name=link\[\]]:first').after(removeLink);
				}
			$('a.remove_link').click(function() {
				$(this).parent().remove();
				if($('input[name=link\[\]]').length == 1) {
					$('a.remove_link').remove();
				}
			});
		});
		// end “add link” functionality
		// begin sortable table functionality
				if(jQuery().dataTable) {
					$('.documentsTable').dataTable({
						"bPaginate": false,
						"bFilter": false,
						"bInfo": false,
						"aoColumns": [
							{"sType": "html"},
							{"sType": "string"},
							{"sType": "string"},
							{"sType": "date"}
						],
						"fnDrawCallback": function() {
							$(".documentsTable tbody tr").removeClass("alt");
							$(".documentsTable tbody tr:even").addClass("alt");
						}
					});
				}
				// end sortable table functionality
				 if(jQuery().getFeed) {
				   $.getFeed({
		        url: 'feed.xml',
		        success: function(feed) {
		        
		            /*$('#result').append('<h2>'
		            + '<a href="'
		            + feed.link
		            + '">'
		            + feed.title
		            + '</a>'
		            + '</h2>');*/
		            
		            var html = '';
		            
		            var threads = new Array();
		            
		            for(var i = 0; i < feed.items.length && threads.length < 5; i++) {
		            
		                var item = feed.items[i];
		                var threadTitle = item.title.replace(/^RE: /i, '');
		                
		                if (threads.indexOf(threadTitle) == -1) {
											threads.push(threadTitle);
		
											html += '<tr><td>'
											+ '<a class="thread" href="'
											+ item.link
											+ '">'
											+ threadTitle
											+ '</a>'
											+ '</td>';
		
											var formattedDate = item.updated.match(/\d{4}-\d{2}-\d{2}/)[0];
											var dt = new Date(item.updated);
											var hours = dt.getHours();
											var suffix = "am";
											if (hours >= 12) {
												 suffix = "pm";
												 hours = dt.getHours - 12;
												 }
											if (hours == 0)
												hours = 12;
		
											var minutes = dt.getMinutes();
										 if (minutes < 10)
											minutes = "0" + minutes;
		
											var formattedTime = hours + ':' + minutes + suffix;
		
											html += '<td>' +formattedDate + ' ' + formattedTime + '<br />';
											html += 'by ' + item.author + '</td>';
		
										/*  html += '<td>?'
											//+ item.author
											+ '</td><td>?</td>'; */
		                }
		            }
		            
		            $('#threads tbody').append(html);
		        }
		   	 });
   } //end if
		// new functions should be added here
	});
}