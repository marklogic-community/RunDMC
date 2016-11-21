$(document).ready(function() {
  jQuery.validator.addMethod("twitter", function(value, element) {
    return this.optional(element) || /^@.+/.test(value);
  }, "Please specify a valid twitter handle");

  $('#profile-form').validate({
    "errorClass": "signup-form-error"
  });

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
        console.log('success');
      },
      error: function(error) {
        console.log('nope');
      }
    });
  });
});

$('#profile-form').dirtyForms();

