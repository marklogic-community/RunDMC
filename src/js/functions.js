if(typeof jQuery != 'undefined') {
  $(function() {
    // cache selectors
    var body = $('body');
    var main = $('#main');
    body.addClass('jsenabled');
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
    if(hasPlaceholderSupport() === false) {
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
          if($(this).val() === '') {$(this).val(labelText).addClass('default');}
        })
        .prev()
          .hide();
    }
    var valText = 'Type to filter TOC';
    $('#toc_content .default','#api_sub')
      .val(valText)
      .addClass('default')
      .focus(function() {
        if($(this).val() == valText) {
          $(this).val('').removeClass('default');
        }
      })
      .blur(function() {
        if($(this).val() === '') {$(this).val(valText).addClass('default');}
      });
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

    $('.features thead th:first-child')
      .addClass('title')
      .append($('.features caption').text())
      .closest('table')
      .children('caption')
      .remove();
    // general class if window width smaller than container width
    if($(window).width() <= 1100) {
      body.addClass('sticky');
    }
    $(window).resize(function() {
      if($(this).width() <= 1100) {
        body.addClass('sticky');
      }
      else {
        if(body.hasClass('sticky')) {
          body.removeClass('sticky');
        }
      }
    });
    // end general class

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
    var inside = false;
    root.find('form').hover(function(){
        inside=true;
      }, function(){
        inside=false;
    });
    body.mouseup(function(){
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

    $(function () {
      $('[data-toggle="tooltip"]').tooltip();
    });

    // end utility form stuff
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

    $('.hide-if-href-empty').each(function() {
      if ( $(this).attr('href') === "" ) {
        $(this).hide();
      }
    });

    // $("#s_download").attr("v

    $("#iemail,#ipass").keyup(function() {
      var b = $(":button:contains('Download')");
      var email = $("#iemail").val();
      var pass = $("#ipass").val();
      if ($("#iaccept").is(":checked") && isValidEmailAddress(email)) {
        b.prop("disabled", false);
        $("#confirm-dialog").dialog.email = email;
        $("#confirm-dialog").dialog.pw = pass;
      } else {
        b.prop("disabled", true);
      }
    });

    $("#iaccept").click(function() {
      var b = $(":button:contains('Download')");
      if ($("#iaccept").is(":checked") &&
        ( $('#iemail').length === 0|| $("#iemail").is(":hidden") || isValidEmailAddress($("#iemail").val()))) {
        b.prop("disabled", false);
        $("#confirm-dialog").dialog.email = $("#iemail").val();
        $("#confirm-dialog").dialog.pw = $("#ipass").val();
      } else {
        b.prop("disabled", true);
      }
    });

    var download_iframe;

    if(jQuery().dialog) {
      $("#confirm-dialog").dialog({
        resizable: false,
        autoOpen: false,
        closeOnEscape: true,
        title: 'MarkLogic Download Confirmation',
        width: 550,
        modal: true,
        buttons: {
          Download: function() {
            var u = $(this).dialog.href;

            if ($("#confirm-dialog").dialog.email) {
              $.ajax({
                type: 'POST',
                url: "/login",
                context: $(this),
                data: {
                  email: $("#confirm-dialog").dialog.email,
                  password: $("#confirm-dialog").dialog.pw,
                  asset: u
                },
                success: function( data ) {
                  if (data.status && data.status === 'ok') {

                    $("#ifail").text("");
                    $('#signup-trigger').hide();
                    $('#login-trigger').hide();
                    $('#session-trigger').text(data.name);
                    $('#session-trigger').show();

                    $(this).dialog('close');

                   //  _gaq.push(['_trackEvent', 'success-login-for-download', u]);

                    doDownload(u);

                  } else {
                    if (data.status) {
                      $("#ifail").text(data.status);
                      //  _gaq.push(['_trackEvent', 'failed-login-for-download', data.status, u]);
                    } else {
                      $("#ifail").text("Unknown failure"); // XXX
                      //  _gaq.push(['_trackEvent', 'failed-login-for-download', "Unknown failure", u]);
                    }
                  }
                }
              }).fail(function( jqXHR, textStatus, errorThrown ) {
                alert( "Failed: " + textStatus ); // FIXME
              });

            } else {
              $(this).dialog('close');

              doDownload(u);
            }
          },
          "Download Via Curl": function() {
            var u = $(this).dialog.href;

            if ($("#confirm-dialog").dialog.email) {
              $.ajax({
                type: 'POST',
                url: "/login",
                context: $(this),
                data: {
                  email: $("#confirm-dialog").dialog.email,
                  password: $("#confirm-dialog").dialog.pw,
                  asset: u
                },
                success: function( data ) {
                  if (data.status && data.status === 'ok') {
                    $("#ifail").text("");
                    $('#signup-trigger').hide();
                    $('#login-trigger').hide();
                    $('#session-trigger').text(data.name);
                    $('#session-trigger').show();

                    // _gaq.push(['_trackEvent', 'success-login-for-download-url', u]);
                    showDownloadURL(this, u);

                  } else {
                    if (data.status) {
                      $("#ifail").text(data.status);
                      // _gaq.push(['_trackEvent', 'failed-login-for-download-url', data.status, u]);
                    } else {
                      $("#ifail").text("Unknown failure"); // XXX
                      // _gaq.push(['_trackEvent', 'failed-login-for-download-url', "Unknown failure", u]);
                    }
                  }
                }
              }).fail(function() {
                alert('Failed'); // XXX
              });
            } else {
              showDownloadURL(this, u);
            }
          },
          Cancel: function() {
            var u = $(this).dialog.href;
            // _gaq.push(['_trackEvent', 'cancel-download', u]);
            /* try {
                var s = '/cancel-download' + u.replace(/\?., "");
                mktoMunchkinFunction('clickLink', { href: s } );
            } catch (err) {}
            */
            $(this).dialog('close');
          }
        }
      });
      $(".ui-dialog-titlebar").hide();
      // $(".ui-dialog-buttonpane")
      $(".ui-dialog").addClass("download-dialog");
    }

    $('a.license-popup').click(function() {
      $('#license-agreement-dialog').dialog({
        resizable: false,
        autoOpen: true,
        closeOnEscape: true,
        width: 550,
        height: 500, /* change to dynamic height XXX */
        modal: true,
        buttons: {
          'Print': function() {
            $('.license-header').printThis();
          },
          'OK': function() {
            $(this).dialog('close');
          }
        }
      });
      $(".ui-dialog-titlebar").hide();
    });

    $('a.confirm-download').each(function() {
      var href = $(this).attr("href");
      $(this).click(function() {
        $(":button:contains('Download')").prop("disabled", true);
        $("#iaccept").removeAttr('checked');
        $("#confirm-dialog").dialog.href = href;
        $("#confirm-dialog-signup").attr("href", "/people/signup?d=" + href + "&p=" + window.location.pathname);
        $("#confirm-dialog").dialog('open');
        $("#iemail").focus();
        return false;
      });
      var dp = getParameterByName('d'); // e.g. '/download/binaries/6.0/MarkLogic-6.0-2-x86_64.dmg';
      if (href == dp) {
        $("#iaccept").removeAttr('checked');
        $("#confirm-dialog").dialog.href = href;
        $("#confirm-dialog-signup").attr("href", "/people/signup?d=" + href + "&p=" + window.location.pathname);
        $("#confirm-dialog").dialog('open');
        $("#iemail").focus();
      }
    });

    if ($('#page_content').length) {
      $('body:not(.sticky) #page_content')
        .append($('<div>', {'class': 'shadow'}));
    }

    $(document).ready(function() {

      var container = document.getElementById("home-tabs");

      if (container !== null) {

        // set current tab
        var cname = 'rundmc-home-tab';
        var ident = '1';
        if ($.cookie(cname)) {
          ident = $.cookie(cname);
        }
        if (window.location.hash !== "") {
          if (window.location.hash.substring(1) == 'mm-demo') {
            ident = 3;
          } else {
            var h = window.location.hash.substring(1, 2);
            if (['1', '2', '3'].indexOf(h) != -1) {
              ident = h;
            }
          }
        }

        var navitem = document.getElementById("tabHeader_" + ident);
        if (navitem) {

          //store which tab we are on
          navitem.parentNode.setAttribute("data-current",ident);
          //set current tab with class of activetabheader
          navitem.setAttribute("class","tabActiveHeader");

          //hide two tab contents we don't need
          $('.tabpage').hide();

          $('#tabpage_' + ident).show();


          var t = document.getElementById("tabHeader_" + ident);

          $('#tabsborder').position({
            my: "left top",
            at: "left bottom",
            of: t
          });
          $('#tabsborder').css({marginTop: '-=3px'});

          //this adds click event to tabs
          $('#tabContainer li').click(function() {

            var current = $(this).parent().attr("data-current");

            // Make sure current is one of our tab indexes.
            if (['1', '2', '3'].indexOf(current) == -1) {
              return;
            }

            //remove class of activetabheader and hide old contents
            document.getElementById("tabHeader_" + current).removeAttribute("class");
            document.getElementById("tabpage_" + current).style.display="none";

            var ident = this.id.split("_")[1];
            $.cookie(cname, ident);
            //add class of activetabheader to new active tab and show contents
            $(this).attr("class","tabActiveHeader");
            document.getElementById("tabpage_" + ident).style.display="block";
            $(this).parent().attr("data-current",ident);

            window.location.hash = "";

            $('#tabsborder').position({
              my: "left top",
              at: "left bottom",
              of: $(this).get()
            });
            $('#tabsborder').css({marginTop: '-=3px'});
          });
        }
      }

      if (navigator.appVersion.indexOf("10_7") != -1) {
          $('.showScroll').addClass('lion');
      }

      $('div#diagram101 .component').mouseover(function(){
          $(this).data('old-border-color', $(this).css('border-color'));
          // $(this).css('border-color', 'black');
      });
      $('div#diagram101 .component').mouseout(function(){
          // $(this).css('border-color', $(this).data('old-border-color'));
      });

      // $('div.qtips[title]').qtip({
      //     style: {
      //         width: 300,
      //         padding: 5,
      //         color: 'black',
      //         tip: {
      //             corner: 'bottomLeft'
      //         },
      //         border: {
      //             color: 'black',
      //             radius: 2,
      //             width: 1
      //         }
      //     },
      //     show: 'mouseover',
      //     hide: { when: 'mouseout', fixed: true },
      //     position: {
      //         corner: {
      //             target: 'center',
      //             tooltip: 'leftBottom'
      //         },
      //         adjust: {
      //             y: -20
      //         }
      //     }
      // });

      $('input#email').focus();

      $("button").click(function(e) {
        var u = $(this).data('url');
        if (u) {
          window.location = u;
          return false;
        }
      });

      $("#session-trigger").click(function(e) {
        $("#session-menu").toggle(0, function() {
          if ($("#session-menu:visible")) {
            $("#session-trigger").addClass("triggered");
          }
        });

        $( "#session-menu" ).position({
            my: "left top",
            at: "left bottom",
            of: "#session-trigger",
            offset: "0 -4"
        });

        e.preventDefault();
      });

      $(document).bind('keydown.drop-down-menu', function(event) {
        if (event.keyCode && event.keyCode === $.ui.keyCode.ESCAPE) {
          $('.drop-down-menu').each(function() {
            $(this).hide();
          });
          event.preventDefault();
        }
      });

      $("fieldset.drop-down-menu").mouseup(function() {
        return false;
      });

      // fixes issue 507
      var _startedClickInMenu = false;
      $('#login-menu').mousedown(function(e) {
        _startedClickInMenu = true;
      });

      $(document).mouseup(function(e) {
        // hide if the click is outside of a menu
        if (  (! $(e.target).hasClass("drop-down-trigger")) &&
              (! $(e.target).parent().hasClass("drop-down-trigger")) &&
              !_startedClickInMenu) {

          $('.drop-down-menu').each(function() {
            $(this).hide();
          });
          $('.triggered').each(function() {
            $(this).removeClass('triggered');
          });
        }

        _startedClickInMenu = false;
      });

      $("#local-login").click(function(e) {
        $("#local-login-form").toggle().appendTo('#login-menu');
      });

      $('#local-login-form').bind('keypress', function (event){
        if (event.keyCode === 13) {
          $('#login_submit').trigger('click');
          return false;
        }
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

              $('#signup-trigger').hide();
              $('#login-trigger').hide();
              $('#session-trigger').text(data.name);
              $('#session-trigger').show();
            } else {
              $('#login-error').text(data.status);
            }
          },
          dataType: 'json'
        });
      });

      $("#logout").click(function(e) {

        $("#session-trigger").text("");
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

      $("#signup-submit").click(function(e) {
        e.preventDefault();
        if (! $('#signup-form').validate().form()) {
          return;
        }
        $('#signup-form').cleanDirty(); // could do in success I spose
        $('#signup-form').submit();
      });

      $("#profile-save").click(function(e) {
        e.preventDefault();
        if (! $('#profile-form').validate().form()) {
          $('#changes-saved').removeClass("successful-save").addClass("failed-save").text("Save failed").fadeIn('slow', function() {
              $(this).fadeOut('slow');
          });
          return;
        }
        $('#profile-form').cleanDirty(); // could do in success I spose
        $('#changes-saved span').hide("");
        $('this').attr('disabled', 'disabled');
        $.ajax({
          type: 'POST',
          url: '/save-profile',
          success: function( data ) {
            $('#session-trigger').text(data.name);
            $('#changes-saved').text('Changes saved').removeClass("failed-save").addClass("successful-save").fadeIn('slow', function() {
                $(this).fadeOut('slow');
            });
          },
          error: function( ) {
            $('#changes-saved').removeClass("successful-save").addClass("failed-save").text("Save failed").fadeIn('slow', function() {
                $(this).fadeOut('slow');
            });
          },
          finished: function( ) {
            $('this').removeAttr('disabled');
          },
          data: $('#profile-form').serialize(),
          dataType: 'json'
        });
      });

      // $('#s_country').selectToAutocomplete();
      // $('#country').selectToAutocomplete();

      $('#s_industry').val([]);
      $('#industry').val($('#industry').data('initvalue'));

      // $('#country').val($('#country').data('initvalue'));
      var v =
        $("#country option").filter(function() {
            //may want to use $.trim in here
            return $(this).val() == $('#country').data('initvalue');
        }).attr('selected', true).text();
      $("input.country").val(v);

      $(".ui-dialog-buttonset").append(
              '<div style="font-size: 80%">' +
                   '<a style="color: #01639D;" target="_blank" href="/people/recovery">Forgot your password?</a>' +
                   ' Or having <a style="color: #01639D;" href="mailto:community-requests@marklogic.com">other trouble</a>?' +
              '</div>');

      if (getParameterByName('fs')) {
          $(document).fartscroll(800);
      }

      buildCodeMirror('xml');
      buildCodeMirror('javascript');
      buildCodeMirror('xquery');
      buildCodeMirror('shell');
    });

    var d = $('.yearpicker').attr('data-value');
    var now = new Date().getFullYear();
    for (i = now; i < now + 10 ; i++)
    {
      $('.yearpicker').append($('<option />').val(i).html(i));
    }
    $('.yearpicker').append($('<option />').html('N/A'));
    $('.yearpicker').val(d);


    $(".vidwrap").click(function(e) {
      var rel = $(this).attr('rel');
      if (rel) {
        $(this).children('div').replaceWith('<iframe id="vidplayer" width="460" height="259" src="http://www.youtube.com/embed/'+ rel+'?autoplay=1&rel=0&vq=hd720" frameborder="0" allowfullscreen=""></iframe>');
      }
    });

    $('div.thumb img').click(function(e){
      var vid = $(this).parent().data('vid');
      if (vid) {
        e.preventDefault();
        var player = $('#vidplayer');
        if (player.length === 0) {
          $('#demowrapper').children('div').replaceWith('<iframe id="vidplayer" width="460" height="259" src="http://www.youtube.com/embed/'+ vid +'?autoplay=1&rel=0&vq=hd720" frameborder="0" allowfullscreen=""></iframe>');
        } else {
          $('#vidplayer').attr('src','http://www.youtube.com/embed/'+vid+'?autoplay=1&rel=0&vq=hd720');
        }
      }
    });

    $(function(){
      $('#slider').anythingSlider({
        buildArrows: false,
        buildStartStop: false,
        theme: 'default',
        startSlide: 1,
        resizeContents: true,
        navigationFormatter : function(i, panel) {
          return ['Line chart', 'Bar chart', 'Pie chart', 'Heat map', 'Point map'][i - 1];
        }
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
}

// Give your textarea two classes: 'codemirror' and a mode. For instance,
// <textarea class="codemirror xml">...</textarea>
// Then call codeMirror.apply('xml');, adding any desired options.
function buildCodeMirror(className, options) {
  var elements = document.getElementsByClassName('codemirror ' + className);
  var codeOptions = {
    lineNumbers: true,
    mode: className,
    readOnly: true,
    theme: 'default'
  };
  if (elements.length > 0) {
    $.extend(codeOptions, options);
    Array.prototype.forEach.call(elements, function(item) {
      CodeMirror.fromTextArea(item, codeOptions);
    });
  }
}


function loadRecentContent() {
  var icons = {
    'blog': 'bullhorn',
    'tutorial': 'education'
  };
  $.ajax({
    url: '/recent',
    dataType: 'json',
    success: function(data) {
      var recent = $('#recent');
      if (data) {
        data.forEach(function(item) {
          recent.append(
            $('<a/>')
              .addClass('list-group-item')
              .attr('href', item.uri)
              .append(
                $('<span/>')
                  .addClass('glyphicon')
                  .addClass('glyphicon-' + icons[item.type])
                  .addClass('pull-left')
              )
              .append(
                $('<h3 class="panel-title"/>')
                  .text(item.title)
              )
              .append(
                $('<p/>')
                  .text(item.short)
              )
          );
        });
      }
    }
  });
}

function getParameterByName(name)
{
  name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(window.location.search);
  if(results === null)
    return "";
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "));
}


function isValidEmailAddress(emailAddress) {
  var pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
  return pattern.test(emailAddress);
}


function doDownload(u) {

  //  _gaq.push(['_trackPageview', u],
  //      ['_trackEvent', 'success-login-for-download', u],
  //      ['_trackEvent', 'start-download', u]);

/*
    try {
        mktoMunchkinFunction('clickLink', { href: '/start-download' + u.replace(/\?., "") } );
    } catch (err) {
    }
*/

  download_iframe = document.getElementById("hiddenDownloader");
  if (download_iframe === null) {
    download_iframe = document.createElement('iframe');
    download_iframe.id = "hiddenDownloader";
    download_iframe.style.visibility = 'hidden';
    document.body.appendChild(download_iframe);
  }
  download_iframe.src = u;
}

function showDownloadURL(me, u) {

  $('#download-curl-dialog').dialog({
    modal: true,
    width: 630,
    resizable: false,
    closeOnEscape: true,
    title: 'MarkLogic Download URL',
    open: function(event, ui) {
      $.ajax({
        type: 'POST',
        url: "/get-download-url",
        data: {
            download: u
        },
        context: $(me),
        success: function(data) {

          //  _gaq.push(['_trackPageview', u],
          //      ['_trackEvent', 'show-url-for-download', u]
          //  );

/*
            try {
                mktoMunchkinFunction('clickLink', { href: '/show-download-url' + u.replace(/\?., "") } );
            } catch (err) {
            }
*/

          var port = (window.location.port === "") ? "" : ":" + window.location.port;
          var host = window.location.hostname + port;
          var sechost = (window.location.port === "") ? host : window.location.hostname;
          $('#curl-url').text(window.location.protocol + '//' + host + data.path);
          $('#secure-curl-url').text('https:' + '//' + sechost + data.path);

          // If current URL is secure, we don't need this
          if (window.location.protocol == "https:") {
            $('#download-curl-dialog .secure').hide();
          }
        },
        dataType: 'json'
      }).fail(function( jqXHR, textStatus, errorThrown ) {
        alert( "Failed: " + textStatus ); // FIXME
      });

      $('.download-url').click(function() {
        $(this).select();
      });

      $('.download-url').focus(function() {
        $(this).select();
      });

      $('.download-url').mouseup(function(e) {
        e.preventDefault();
      });
    },
    buttons: {
      'OK': function() {
        $('#download-curl-dialog').dialog('close');
        $('#confirm-dialog').dialog('close');
      },
      'Cancel': function() {
        $('#download-curl-dialog').dialog('close');
      }
    }
  });
  $(".ui-dialog-titlebar").hide();

  ZeroClipboard.setDefaults({
    moviePath: "/images/ZeroClipboard.swf"
  });

  new ZeroClipboard($("#copy-url-button"));
  new ZeroClipboard($("#copy-secure-url-button"));
}
