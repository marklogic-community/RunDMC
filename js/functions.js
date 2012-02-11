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
			$('.utility a img, .utility input[type=image], .stip').tooltip({
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

        $(document).ready(function() {

            //Hide login and signup when we're on a signup page
            if (window.location.pathname == '/people/signup' || 
                window.location.pathname == '/people/fb-signup') {
                    $('#login-menu-nav').hide();
            }

            $('input#email').focus();

            $("#session-trigger").click(function(e) {
                e.preventDefault();
                $("#session-menu").toggle();
                $(this).toggleClass("menu-open");
            });

            $("#login-trigger").click(function(e) {
                e.preventDefault();
                $("#login-menu").toggle();
                $(this).toggleClass("menu-open");
            });

			$(document).bind('keydown.drop-down-menu', function(event) {
                if (event.keyCode && event.keyCode === $.ui.keyCode.ESCAPE) {
                    $('.drop-down-menu').each(function() {
                        $(this).hide();
                        $(this).removeClass("menu-open");
                    });
					event.preventDefault();
                }
            });


            $("fieldset.drop-down-menu").mouseup(function() {
                return false;
            });

            $(document).mouseup(function(e) {
                if ($(e.target).parents("fieldset.drop-down-menu").length == 0) { // hide if the click is outside of a menu
                    $('.drop-down-menu').each(function() {
                        $(this).hide();
                        $(this).removeClass("menu-open");
                    });
                }
            });            

            $("#local-login").click(function(e) {
                $("#local-login-form").toggle().appendTo('#login-menu');
            });

            $("#login_submit").click(function(e) {
                $.ajax({
                    type: 'POST',
                    url: '/login', /* could get from form */
                    data: {
                        'email': $('#local-login-form').find('#email').val(),
                        'password': $('#local-login-form').find('#password').val()
                    }, 
                    success: function( data ) {
                        if (data.status === 'ok') {
                            $('#login-error').text("");
                            $('#login-menu').hide();
                            $('#login-trigger').removeClass("menu-open");

                            $('#signup-trigger').hide();
                            $('#login-trigger').hide();
                            $('#session-trigger span').text(data.name);
                            $('#session-trigger').show();
                        } else {
                            $('#login-error').text(data.status);
                        }
                    },
                    dataType: 'json'
                });
            });

            $("#logout").click(function(e) {

                $("session-trigger span").text("");
                $('#session-trigger').hide();
                $('#session-menu').hide();
                $('#signup-trigger').show();
                $('#login-trigger').show();

                $.ajax({
                    type: 'POST',
                    url: '/logout',
                    success: function( data ) {
                        // Stop busy indicator
                        // Adjust page if need be
                        window.location = "/";
                    },
                    dataType: 'json'
                });
            });

            $("#fb-login").click(function(e) {

                console.log("fb-login");
                $('#login-error').text("");
                $("#login-menu").hide();
                $("#signup-trigger").hide();
                $("#login-trigger").hide();

                FB.getLoginStatus(function(response) {

                    if (response.status === 'connected') {

                        doFBLogin(response);


                    } else {
                        FB.login(function(response){
                            if (response.authResponse) {
                                doFBLogin(response);
                            } else {
                                $('#signup-trigger').show();
                                $('#login-trigger').show();
                            };
                        }, {"scope": "email"} );
                    }
                });
            });

            $("#profile-save").click(function(e) {
                $('#profile-form').cleanDirty(); // could do in success I spose
                e.preventDefault();
                $('#changes-saved span').hide("");
                $('this').attr('disabled', 'disabled');
                $.ajax({
                    type: 'POST',
                    url: '/save-profile',
                    success: function( data ) {
                        $('#session-trigger span').text(data.name);
                        $('#changes-saved').text('Changes saved').removeClass("failed-save").addClass("successful-save").fadeIn('slow', function() {
                            $(this).fadeOut('slow');
                        });
                    },
                    error: function( data ) {
                        $('#changes-saved').removeClass("successful-save").addClass("failed-save").text("Save failed").fadeIn('slow', function() {
                            $(this).fadeOut('slow');
                        });
                    },
                    finished: function( data ) {
                        $('this').removeAttr('disabled');
                    },
                    data: $('#profile-form').serialize(),
                    dataType: 'json'
                });
            });
        });

        //$("#signup-form input[type=text], #signup-form input[type=password]").blur(function(event) {
            // Ajax validation tbd
        //});

        //$('#signup-form').submit(function(e) {
		    // e.preventDefault();
        //});


		// add new functions before this comment

	});
};

function getParameterByName(name)
{
  name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(window.location.search);
  if(results == null)
    return "";
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "));
}

function doFBLogin(response) {

    var signedRequest = response.authResponse ? response.authResponse.signedRequest : null;

    FB.api('/me', 'get', { access_token:response.authResponse.accessToken }, function(response) {

        if (!response || response.error) {
            alert('Communication with Facebook graph failed');
            console.log(response.error)
            $('#signup-trigger').show();
            $('#login-trigger').show();
        } else {
            console.log(response);


            $.ajax({
                type: 'POST',
                url: '/fb-login',
                data: {
                    signedRequest: signedRequest,
                    facebookID: response.id,
                    email: response.email,
                    name: response.name
                },
                success: function(data) {
                    if (data.status === 'ok') {
                        $('#session-trigger span').text(data.name);
                        $('#session-trigger').show();
                    } else {
                        $("#login-trigger").show();
                        $('#login-error').text(data.status);
                        $("#login-menu").show();
                    }
                }
            });
        }
    });
}
