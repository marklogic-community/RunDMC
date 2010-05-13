This directory contains the form config file for each document type that can
be edited using the Admin interface.

Here's a summary of the annotations you can use for the form config files.
Some combinations won't work, and there are limitations on how much nesting
you can do. For more specifics of the assumptions and limitations of this
system, see the comments at the top of /admin/model/xml2form.xsl.

Document element only:
  @form:uri-prefix-for-new-docs - where to store new docs of this type. This
                                  is what configures the URI path prefix you
                                  see at the top of each form.

Any element:
  @form:label - What makes an element a form field; the human-readable name of
                the field. Elements used only as containers for sub-elements
                or attributes should not use this attribute.

  @form:type  - Only supported value right now: "textarea"
                This creates a textarea in which you can edit XHTML content.

  @form:lines - How big to make the textarea (number of lines)

  @form:optional="yes" - If the element has no supplied value (or any attribute
                         fields with supplied values), then it will be stripped
                         out of the resulting XML that gets constructed.

  @form:wide="yes" - For regular input fields, render them as wide.

  @form:values  - A space-separated enumeration of values (use "_" for literal
                  spaces). This will cause the field to be rendered as a
                  drop-down menu.

  @form:repeating="yes" - For elements that can repeat, this will cause the
                          appropriate JavaScript to be generated for adding
                          and removing repeating form fields in the browser.

  @form:group-label - For repeating elements that contain more than just a
                      simple value, e.g., child elements or attributes that
                      are part of a repeating group.

Any attribute:
  To annotate an attribute, you use either the "label" or "values" namespaces.
  An inherent limitation of this approach is that it only allows editing
  attributes that are not in a namespace.

  @label:myAttribute - Replace "myAttribute" with the name of the attribute
                       you are specifying the label for. If you don't provide
                       a label, the attribute won't be editable. This is
                       equivalent to editing this element (and in fact is
                       translated as such in the implementation):

                         <myAttribute form:label="Field Name"/>


  @values:myAttribute - Replace "myAttribute" with the name of the attribute
                        you are specifying the enumeration for. This is
                        optional and causes the field to be rendered as a
                        drop-down menu. This is equivalent to editing this
                        element (and in fact is translated as such in the
                        implementation):

                          <myAttribute form:values="Published Draft Another_value"/>
