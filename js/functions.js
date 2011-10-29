if(typeof jQuery != 'undefined') {
	$(function() {
		$('body').addClass('jsenabled');
		// cache selectors
		var main = $('#main');
		if(!$.support.opacity) {
			$('th:last-child, td:last-child, tr:last-child, tbody:last-child, .utility a:last-child, .widget div li:last-child, .lists li:last-child','#content').addClass('last');
			$('.features section:nth-child(even)', main).addClass('even');
			$('.features section:nth-child(odd)', main).addClass('odd');
		}
		// search field default value
		function hasPlaceholderSupport() {
			var input = document.createElement('input');
			return ('placeholder' in input);
		}

		if(hasPlaceholderSupport() == false) {
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
		}/*
		var utilSearch = $('.utility #us_input','footer');
		var valText = utilSearch.attr('title');
		utilSearch
			.val(valText)
			.addClass('default')
			.focus(function() {
				if($(this).val() == valText) {
					$(this).val('').removeClass('default');
				}
			})
			.blur(function() {
				if($(this).val() == '') {$(this).val(valText).addClass('default')}
			});*/
		// end search field default value
		// side nav accordion functionality
		$('body:not(.blog) #sub li').each(function() {
			if($(this).children('span').length) {
				$(this).addClass('active');
			}
		});
		$('#sub li > span').click(function() {
			var that = $(this);
			if(that.parent().hasClass('active')) {
				that.next().slideUp(function() {
					that.parent().removeClass('active');
				});
			}
			else {
				that.next().slideDown().end().parent().addClass('active');
			}
		});
		$('#sub li').find('.current').parent().show().closest('li').addClass('active');
		// end side nav accordion functionality
		$('.features thead th:first-child').addClass('title').append($('.features caption').text()).closest('table').children('caption').remove();
		
		// utility form stuff
		var root = $('.utility');
		var btn = root.find('form input[type=image]');
		root
			.contents()
				.wrapAll($('<div>', {'class': 'u_wrapper'}))
				.end()
			.find('form')
				.after(
					$('<a>', {'class': 'search'}).append(
						$('<img>', {
							src: btn.attr('src'),
							title: btn.attr('title')
						})
					)
				)
				.submit(function() {
					$(this).find('input[type=image]').prop('disabled',true);
				})
				.end()
			.find('.search')
				.click(function(e) {
					e.preventDefault();
					$(this).prev().addClass('active').find('input[type=text]').focus();
				});
		if($(window).width() <= 1100) {
			root.addClass('sticky');
		}
		$(window).resize(function() {
			if($(this).width() <= 1110) {
				root.addClass('sticky');
			}
			else {
				if(root.hasClass('sticky')) {
					root.removeClass('sticky');
				}
			}
		});
		var inside = false;
		root.find('form').hover(function(){ 
		    inside=true; 
			}, function(){ 
		    inside=false; 
		});
		$('body').mouseup(function(){ 
	    if(!inside) {
	    	root.find('form.active').removeClass('active');
	    }
		});
		if(jQuery().tooltip) {
			$('.utility a img, .utility input[type=image]').tooltip({
				showURL: false,
				track: true,
				top: -8
			});
		}
		$('.post + .pagination',main).clone().insertBefore(main);
		// comments tab position at right 
		var pos = parseInt($('#comments .action').css('top'), 10);
		$('#comments .action').css('top', pos+$('#breadcrumb + section > h2').height()+'px');
		// end comments tab position
		// blog heading change
		if($('.blog #main article.post').length == 1) {
      /* EDL: we don't need this; the XSLT takes care of this
			var h3 = $('.blog #main article.post:only-child header h3').hide();
			$('.blog #breadcrumb + section > h2').text(h3.text());
      */
			$('#comments .action').css('top', pos+$('#breadcrumb + section > h2').height()+'px');
		}
		//end blog heading change
		// home page close button(s)
		$('.removable').each(function() {
			var sectionHeight = $(this).height();
			var paddingb = $(this).css('padding-bottom');
			var paddingt = $(this).css('padding-top');
            var id = $(this).attr('id');
            var c = 'rundmc-r-' + id;

            if ($.cookie(c) === 'closed') {
				$(this).addClass('closed');
				$(this).height(35).css('padding-bottom', 5).css('padding-top', 15);
            }

			$(this).append($('<a>', {'class': 'close'})).children('.close').click(function() {
				if($(this).parent().hasClass('closed')) {
					$(this).parent().animate({height: sectionHeight,'padding-bottom':paddingb,'padding-top':paddingt},500, function() {
						$(this).removeClass('closed');
                        $.cookie(c, 'open');
					});
				}
				else {
					$(this).parent().animate({height: 35,'padding-bottom': 5, 'padding-top': 15},500, function() {
						$(this).addClass('closed');
                        $.cookie(c, 'closed');
					});
				}
			});

		});

        $('.hide-if-href-empty').each(function() {
            if ( $(this).attr('href') == "" ) {
                $(this).hide();
            }
        });

        $("#iaccept").click(function() {
            var b = $(":button:contains('Download')");
            if (b.button('option', 'disabled')) {
                b.button("enable");
            } else {
                b.button("disable");
            }
        });

        $('a.confirm-download').each(function() {
            var href = $(this).attr("href");
            $(this).click(function() {
                $(":button:contains('Download')").button('disable');
                $("#iaccept").removeAttr('checked');
                $("#confirm-dialog").dialog.href = href;
                $("#confirm-dialog").dialog('open');
                return false;
            });
        });

        $("#confirm-dialog").dialog({
            resizable: false,
            autoOpen: false,
            title: 'MarkLogic Server Download Confirmation',
            width: 550,
            modal: true,
            buttons: {
                Download: function() {
                    var u = $(this).dialog.href;
                    _gaq.push(['_trackPageview', u],
                              ['_trackEvent', 'start-download', u]);
                    $(this).dialog('close');
                    document.location = u + '?r=dmc';
                },
                Cancel: function() {
                    var u = $(this).dialog.href;
                    _gaq.push(['_trackEvent', 'cancel-download', u]);
                    $(this).dialog('close');
                }
           }
        });

		if(jQuery().fancybox) {
			$('a[rel=detail]',main).each(function() {
				var ref = $(this).attr('href');
				$(this).append(
					$('<span>',{'class':'caption',text: 'Enlarge image'})
				).fancybox({
					transitionIn: 'elastic',
					transitionOut: 'elastic'
				});
			});
		}
		// add new functions before this comment

	});
};
