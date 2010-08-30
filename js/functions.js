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
        $("#s_inp").addClass("default");
						$("#s_inp").focus(function() {$("#s_inp").removeClass("default");} );
						$("#s_inp").blur(function() {
							if ($("#s_inp").val() == "Search the site" || $("#s_inp").val() == "")
								$("#s_inp").addClass("default");
				});
        $('#sub > div:last-child').addClass('last'); // only supposed to add some last-child functionality to IE
        if(jQuery().tabs) {
          $('#special_intro > div').hide();
					$('#special_intro .nav').tabs('#special_intro > div',{
						//effect: 'fade',
                tabs: 'li'
            });
        }
        // accordion style menu
        $('#sub .subnav.closed h2, #sub .subnav.closed li span').each(function() {
            if(!($(this).next().children().is('.current'))) {
                $(this).addClass('closed').next().hide();
            }
        })
        
        $('#sub .current').parents().show();
        $('#sub .subnav h2, #sub .subnav li span').click(function() {
            $(this).toggleClass('closed').next().toggle();
        });

        $("#confirm-dialog").dialog({
            resizable: false,
            autoOpen: false,
            width: 550,
            modal: true,
            buttons: {
                Download: function() {
                    $(this).dialog('close');
                    document.location = $(this).dialog.href + '?r=dmc';
                },
                Cancel: function() {
                    $(this).dialog('close');
                }
           }
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

        $('a.stip[title]').qtip({ 
            position: { 
                corner: {
                    target: 'topLeft',
                    tooltip: 'bottomLeft'
                },
                adjust: {
                    x: 9,  
                    y: 2
                }
            },
            style: {
	            font: '1em Verdana, Arial, Helvetica, Sans-serif',
                padding: 3,
                border: {
                    width: 2,
                    radius: 3,
                    color: '#CDD1B4'
                }
            } 
        })

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
            }); // end add media overlay
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
          $('.documentsList').dataTable({
              "bPaginate": false,
              "bFilter": false,
              "bInfo": false,
              "bSort": true,
              "aoColumns": [
                  {"sType": "html"},
                  {"sType": "string"},
                  {"sType": "string"}
              ],
              "fnDrawCallback": function() {
                  $(".documentsList tbody tr").removeClass("alt");
                  $(".documentsList tbody tr:even").addClass("alt");
               }
            });

          $('.documentsTable').dataTable({
              "bPaginate": false,
              "bFilter": false,
              "bInfo": false,
              "bSort": false,
              "fnDrawCallback": function() {
                  $(".documentsTable tbody tr").removeClass("alt");
                  $(".documentsTable tbody tr:even").addClass("alt");
               }
            });
        }
        // end sortable table functionality

      // new functions should be added here
   });
}

