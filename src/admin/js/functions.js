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
      $('input[name=add_media]').wrap('<a href="/admin/view/adminAddMedia.html" rel="#overlay"></a>"');
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
    /*
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
    */
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

    var uriPrefix = document.querySelector('#media-modal .uri-filter input[name=uri-prefix]');
    if (uriPrefix) {
      uriPrefix.onkeyup = function(e){
        if(e.keyCode == 13){
          getFilteredURIs(event, 'uri-prefix');
        }
      };
    }

		// new functions should be added here
	});
}

function toggleEditor(id) {
  var insertImgBtn;

  if (!tinyMCE.get(id)) {
    tinyMCE.execCommand('mceAddControl', false, id);
    insertImgBtn = document.querySelector('.adminform button[data-target="#media-modal"]');
    if (!insertImgBtn.getAttribute('disabled')) {
      insertImgBtn.setAttribute('disabled', 'disabled');
    }
  } else {
    tinyMCE.execCommand('mceRemoveControl', false, id);
    // enable the Insert Image button
    insertImgBtn = document.querySelector('.adminform button[data-target="#media-modal"]');
    if (insertImgBtn.getAttribute('disabled')) {
      insertImgBtn.removeAttribute('disabled', 'disabled');
    }
  }
}

function buildAttr(attrName, attrValue) {
  var attr = document.createAttribute(attrName);
  attr.value = attrValue;
  return attr;
}

// Builds a Bootstrap dismissible alert.
// See http://getbootstrap.com/components/#alerts
function reportMsg(type, msg) {
  var errorDiv = document.getElementById('textarea-msg');
  errorDiv.innerHTML = '';

  var alertDiv = document.createElement('div');
  alertDiv.setAttributeNode(buildAttr('class', 'alert alert-dismissible alert-' + type));
  alertDiv.setAttributeNode(buildAttr('role', 'alert'));

  var dismissBtn = document.createElement('button');
  dismissBtn.setAttributeNode(buildAttr('type', 'button'));
  dismissBtn.setAttributeNode(buildAttr('class', 'close'));
  dismissBtn.setAttributeNode(buildAttr('data-dismiss', 'alert'));
  dismissBtn.setAttributeNode(buildAttr('aria-label', 'Close'));

  var span = document.createElement('span');
  span.setAttributeNode(buildAttr('aria-hidden', 'true'));
  span.innerHTML = 'x';

  dismissBtn.appendChild(span);
  alertDiv.appendChild(dismissBtn);

  var msgElement = document.createElement('p');
  msgElement.innerHTML = msg;

  alertDiv.appendChild(msgElement);
  errorDiv.appendChild(alertDiv);
}

function checkValidXhtml(action, target) {
  // Event has more than one TEXTAREA, so we need to loop.
  var textAreas = document.getElementsByTagName("TEXTAREA");
  var textAreasLength = textAreas.length;
  var isValid = true;
  var updatedDOM = document.querySelectorAll('input[name="~updated"]');
  var lastUpdated = updatedDOM.length > 0 ? updatedDOM[0].getAttribute('value') : '';
  var uriDOM = document.querySelectorAll('input[name="~existing_doc_uri"]');
  var uri = uriDOM.length > 0 ? uriDOM[0].getAttribute('value') : '';
  $.each(textAreas, function(index, value)
    {
    $.ajax({
      url: '/admin/controller/validate.xqy',
      type: "POST",
      data: {
        xhtml: value.value,
        updated: lastUpdated,
        uri: uri
      },
      cache: false,
      dataType: "xml",
      async: false,
      success:

        function(response)
        {
          // If we get a response, something is wrong with the content
          if(response)  {
            // Bad XHTML or another problem.  Display this error:error node back to the user.
            reportMsg('danger', "There was a problem with your content. Error from the Server: " +
              $(response).find('format-string').text());
            isValid = false;
          }

        },
      error:
        function(xml) {
          reportMsg('danger', "There was unexpected problem in the Server: " + xml.responseText);
          isValid = false;
        }
    });
  });

  // No problem in the textareas, allow form submission to continue
  if(isValid) {
    var adminform = document.getElementsByClassName('adminform')[0];
    var formData = {};
    adminform.querySelectorAll('input:not([type=submit]), textarea, select').forEach(function(input) {
      formData[input.name] = input.value;
    });

    if (action === '/admin/controller/preview.xqy') {
      // We're going to get back a redirect. Let that take its course. The new
      // content will be launched in a different tab.
      adminform.action = action;
      adminform.target = target;
      adminform.submit();
    } else {
      // We're saving the content. Make an AJAX request and stay here.
      $.ajax({
        url: action,
        type: 'POST',
        data: formData,
        dataType: 'xml',
        success: function(response) {
          var updated = $(response).find('updated').text();
          var updatedStr = null;
          var msg = 'Content updated';
          if (updated !== '') {
            updatedStr = new Date(updated).toString();
            var lastUpdated = document.querySelector('#codeedit dd');
            if (lastUpdated) {
              lastUpdated.innerHTML = updatedStr;
            }
            document.querySelector('.adminform input[name="~updated"]').value = updated;
            msg += ' at ' + updatedStr;
          }
          reportMsg('success', msg);
        },
        error: function(error) {
          reportMsg('danger', 'There was a problem saving your update: ' + error.responseText);
        }
      });
    }

  }

  return false;
}

/*
 * Monkey-patch textarea to allow insertion at the current position.
 * Source: http://stackoverflow.com/questions/11076975/insert-text-into-textarea-at-cursor-position-javascript
 */
HTMLTextAreaElement.prototype.insertAtCaret = function (text) {
  text = text || '';
  if (document.selection) {
    // IE
    this.focus();
    var sel = document.selection.createRange();
    sel.text = text;
  } else if (this.selectionStart || this.selectionStart === 0) {
    // Others
    var startPos = this.selectionStart;
    var endPos = this.selectionEnd;
    this.value = this.value.substring(0, startPos) +
      text +
      this.value.substring(endPos, this.value.length);
    this.selectionStart = startPos + text.length;
    this.selectionEnd = startPos + text.length;
  } else {
    this.value += text;
  }
};

function insertImage() {
  var imgSrc = document.querySelector('#media-modal .uri-filter img.preview').getAttribute('src');

  var body = document.querySelector('.adminform textarea');
  var imgTag = '\n<img src="' + imgSrc + '" style="max-width:100%"/>\n';
  body.insertAtCaret(imgTag);
}

function getFilteredURIs(event, textboxName) {
  var filterDiv = event.currentTarget.parentElement;
  var uriInput = filterDiv.querySelector('input[name='+textboxName+']').value;
  var insertBtn = document.querySelector('#media-modal button.insert');

  function setPreview(event) {
    var uri = event.currentTarget.parentElement.querySelector('.uri').innerHTML;
    var preview = filterDiv.querySelector('img.preview');
    preview.setAttribute('src', uri);
    insertBtn.removeAttribute('disabled');
  }

  function buildURILine(uri) {
    var li = document.createElement('li');

    var previewBtn = document.createElement('button');
    previewBtn.setAttribute('class', 'btn btn-default btn-xs');
    previewBtn.addEventListener('click', setPreview, false);
    previewBtn.innerHTML = 'Preview';
    li.appendChild(previewBtn);

    var span = document.createElement('span');
    span.setAttribute('class', 'uri');
    span.innerHTML = uri;
    li.appendChild(span);

    return li;
  }

  $.ajax({
    url: '/admin/controller/list-media-by-uri.xqy',
    type: 'GET',
    data: {
      uri: uriInput
    },
    success: function(response) {
      var uris = JSON.parse(response);
      var ul = filterDiv.querySelector('ul');
      ul.innerHTML = '';
      for (var i in uris) {
        ul.appendChild(buildURILine(uris[i]));
      }
    },
    error: function(error) {
      reportMsg('danger', 'Unable to retrieve URIs: ' + error.responseText);
    }
  });

  return false;
}
