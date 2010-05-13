This directory contains three primary processes:

form2xml.xsl
  This is how we re-construct an XML document purely from
  a set of HTTP POST request parameters, including a hidden
  field named "~xml_to_edit" and a bunch of name/value pairs
  we match up with the XML elements by ID.

  This code is invoked directly by the controller scripts
  (replace, create, and preview).


xml2form.xsl
  This is a much more involved process of translating the
  form configuration file, merging it with an existing XML
  document if applicable (when the user is editing an existing
  document), into an XML-based format that can be readily
  rendered as an HTML form (using ../view/form.xsl).

  This code is imported by form.xsl.


set-doc-attribute.xsl
  This is a simple stylesheet used to update a document by
  adding an attribute to the document element. It's invoked
  directly by the controller scripts for setting @status to
  "Draft" or "Published" and @preview-only="yes".
