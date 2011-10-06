if(typeof jQuery != 'undefined') {
	$(function() {
		$('body').addClass('jsenabled');
		if(!$.support.opacity) {
			$('.features th:last-child, .features td:last-child, .features tr:last-child, .features tbody:last-child','#main').addClass('last');
		}
		// search field default value
		var searchField = $('#s_inp','#header');
		var labelText = searchField.prev().text();
		searchField
			.val(labelText)
			.addClass('default')
			.focus(function() {
				if($(this).val() == labelText) {
					$(this).val('').removeClass('default');
				}
			})
			.blur(function() {
				if($(this).val() == '') {$(this).val(labelText).addClass('default')}
			})
			.prev()
				.hide();
		// end search field default value
		// side nav accordion functionality
		$('#sub li > span').click(function() {
			$(this).next().slideToggle().end().parent().toggleClass('active');
		});
		// end side nav accordion functionality
		$('.features thead th:first-child').addClass('title').append($('.features caption').text()).closest('table').children('caption').remove();
		$('.utility input[type=image]').click(function(e) {
			e.preventDefault();
			$(this).closest('form').addClass('active');
		});
		var inside = false;
		$('.utility form').hover(function(){ 
		    inside=true; 
			}, function(){ 
		    inside=false; 
		});
		$('body').mouseup(function(){ 
	    if(!inside) {
	    	$('.utility form.active').removeClass('active');
	    }
		});
		$('.utility a img').tooltip();
	});
}