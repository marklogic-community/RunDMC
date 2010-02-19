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
		$('#sub > div:last').addClass('last'); // only supposed to add some last-child functionality to IE
		if(jQuery().tabs) {
			$('#special_intro .nav').tabs('#special_intro > div',{
				//effect: 'fade',
				tabs: 'li'
			});
		}
		// accordion style menu
		$('#sub .subnav h2, #sub .subnav li span').addClass('closed').next().hide();
		$('#sub .subnav h2, #sub .subnav li span').click(function() {
			$(this).toggleClass('closed').next().toggle('normal');
		});
		// signup form overlay
		if(jQuery().overlay) {
			$('body').append('<div class="overlay" id="overlay"><div class="overlayContent"></div></div>');
			$('#utilnav .signup a').attr('rel','#overlay').overlay({
				expose: 'black',
				left: 'center',
				closeOnClick: false,
				onBeforeLoad: function() { 
	       if ($.browser.msie) {$('#sub .subnav h2, #sub .subnav li span').unbind();}  //IE needs this otherwise it doubles up the event handler
	       // grab wrapper element inside content 
	        var wrap = this.getContent().find(".overlayContent"); 
	        // load the page specified in the trigger 
	      	wrap.load(this.getTrigger().attr("href"));
	      }
      });
		}
		
		// new functions should be added here
	});
}