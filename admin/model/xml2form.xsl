<!-- ASSUMPTIONS:
       * No mixed content (except with escaped markup to be edited as string, signified using @form:type="textarea")
       * Repeating siblings are contiguous. This is okay: <foo><HI/><bat><HI/><HI/></bat></foo>
                                            But this is not: <foo><HI/><bat/><HI/></foo>
     LIMITATIONS:
       * Can't edit comments or PIs
       * Only supports one level deep of repeating groups.
           E.g.: <group><field1/><field2/></group>
                 <group><field1/><field2/></group>
           In this case, field1 (and field2) may not contain elements or attributes.
           Nor can they repeat (because they're already in a repeating group).
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:map ="http://marklogic.com/xdmp/map"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp map">

  <xsl:variable name="params-doc" select="root($params[1])"/>

  <!-- Workaround for XSLTBUG where modules aren't resolved relative to the referencing module. -->
  <xsl:variable name="base-path" select="'/admin/model/xml2form'"/>

  <xsl:function name="form:form-template">
    <xsl:param name="template"/>

    <!-- STAGE 1: Strip comments from the form config file -->
    <xsl:variable name="form-config" select="xdmp:xslt-invoke(concat($base-path,'/strip-comments.xsl'), xdmp:document-get(concat(xdmp:modules-root(),
                                                                                                                      '/admin/config/forms/',
                                                                                                                      $template)))"/>
    <!-- Initialize some parameters we'll be passing to xslt-invoke -->
    <xsl:variable name="normalized-form-config" select="form:normalize-spec($form-config)"/>
    <xsl:variable name="form-config-map"       select="map:map()"/>
    <xsl:variable name="params-map"            select="map:map()"/>
    <xsl:variable name="normalized-config-map" select="map:map()"/>
    <xsl:variable name="side-effects" select="map:put($form-config-map,       'form-config',            $form-config),
                                              map:put($params-map,            'params',                 $params),
                                              map:put($normalized-config-map, 'normalized-form-config', $normalized-form-config)"/>
    <xsl:variable name="empty-doc">
      <empty/>
    </xsl:variable>

    <!-- STAGE 2: Determine the source of the form template; it depends on whether this is a new or existing document -->
    <xsl:variable name="raw-form-spec" select="(: If the user just tried to create a new doc at a URI that is already taken... :)
                                               if ($doc-already-exists-error) then xdmp:xslt-invoke(concat($base-path,'/annotate-doc.xsl'),
                                                                                                      xdmp:xslt-invoke('form2xml.xsl', $empty-doc, $params-map),
                                                                                                    $form-config-map)
                                                                                     
                                               (: If the user is editing an existing doc :)
                                          else if  (doc-available($doc-path)) then xdmp:xslt-invoke(concat($base-path,'/annotate-doc.xsl'), doc($doc-path), $form-config-map)

                                               (: If ~doc_path is set to a document that doesn't exist (shouldn't normally happen) :)
                                          else if (string($doc-path)) then error((), 'You are attempting to edit a document that does not exist.')

                                               (: If the user is loading the empty form for creating a new doc :)
                                          else $form-config"/>

    <!-- STAGE 3: Normalize the form spec (attribute fields to element fields, etc.) -->
    <xsl:variable name="normalized" select="form:normalize-spec($raw-form-spec)"/>

    <!-- STAGE 4: Insert fields for absent elements (makes a difference when we're editing an existing document that has some new or optional elements missing) -->
    <xsl:variable name="fields-inserted" select="xdmp:xslt-invoke(concat($base-path,'/insert-missing-fields.xsl'), $normalized, $normalized-config-map)"/>

    <!-- STAGE 5: Finally, add a unique ID to each field so we can re-associate field names with XML elements later on -->
    <xsl:sequence select="xdmp:xslt-invoke(concat($base-path,'/add-ids.xsl'), $fields-inserted)"/>
  </xsl:function>

  <xsl:function name="form:normalize-spec">
    <xsl:param name="raw-form-spec"/>
    <xsl:sequence select="xdmp:xslt-invoke(concat($base-path,'/normalize-form-spec.xsl'), $raw-form-spec)"/>
  </xsl:function>

</xsl:stylesheet>
