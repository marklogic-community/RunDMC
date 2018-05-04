$(document).ready(function() {
  jQuery.validator.addMethod("twitter", function(value, element) {
    return this.optional(element) || /^@.+/.test(value);
  }, "Please specify a valid twitter handle. Twitter handles start with '@', e.g. @MarkLogic.");

  $('#profile-form').validate({
    "errorClass": "signup-form-error"
  });

  function reportMsg(type, msg) {
    var errorDiv = document.getElementById('textarea-msg');
    errorDiv.innerHTML = '';

    var alertDiv = document.createElement('div');
    alertDiv.setAttribute('class', 'alert alert-dismissible alert-' + type);
    alertDiv.setAttribute('role', 'alert');

    var dismissBtn = document.createElement('button');
    dismissBtn.setAttribute('type', 'button');
    dismissBtn.setAttribute('class', 'close');
    dismissBtn.setAttribute('data-dismiss', 'alert');
    dismissBtn.setAttribute('aria-label', 'Close');

    var span = document.createElement('span');
    span.setAttribute('aria-hidden', 'true');
    span.innerHTML = 'x';

    dismissBtn.appendChild(span);
    alertDiv.appendChild(dismissBtn);

    var msgElement = document.createElement('p');
    msgElement.innerHTML = msg;

    alertDiv.appendChild(msgElement);
    errorDiv.appendChild(alertDiv);
  }

  $('#doc-section').change(function(event){
    var selections = {
      setting: event.currentTarget.getAttribute('name'),
      value: event.currentTarget.value
    };
    $.ajax({
      url: '/people/preferences',
      method: 'POST',
      data: selections,
      success: function() {
        reportMsg('success', 'Your preference has been updated.');
      },
      error: function(error) {
        reportMsg('danger', 'Error while updating: ' + error);
      }
    });
  });
});

$('#profile-form').dirtyForms();

