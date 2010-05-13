<!-- This stylesheet ensures that all possible form fields are rendered
     when editing an existing document. Some elements may be missing from
     the source document, because they were optional or because they were
     new additions to the form configuration.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp form xhtml">

  <!-- The form configuration document is passed in as a top-level parameter. -->
  <xsl:param name="normalized-form-config"/>

  <xsl:variable name="source-tree" select="/"/>

  <xsl:template match="/">
    <xsl:variable name="missing-fields" select="$flagged-form-config//*[not(@form:found eq 'yes')]"/>
    <xsl:copy-of select="form:insert-fields(/, $missing-fields)"/>
  </xsl:template>

  <xsl:variable name="flagged-form-config">
    <xsl:apply-templates mode="flag-found-nodes" select="$normalized-form-config"/>
  </xsl:variable>

  <xsl:template mode="flag-found-nodes" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="flag-atts" select="."/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

          <!-- By default, don't add any attributes -->
          <xsl:template mode="flag-atts" match="*"/>
          <!-- Flag as "found" each field that has a corresponding element in the source document -->
          <xsl:template mode="flag-atts" match="*[$source-tree//*[deep-equal(form:path-to-me(.),
                                                                             form:path-to-me(current()))]]">
            <xsl:attribute name="form:found">yes</xsl:attribute>
          </xsl:template>

  <!-- Insert each missing field at its appropriate location in the form spec -->
  <xsl:function name="form:insert-fields">
    <xsl:param name="form-spec"/>
    <xsl:param name="missing-fields"/>
    <xsl:choose>
      <!-- If we're done processing the missing fields, then the $form-spec is complete -->
      <xsl:when test="not($missing-fields)">
        <xsl:copy-of select="$form-spec"/>
      </xsl:when>
      <!-- Otherwise, insert the first field in the list -->
      <xsl:otherwise>
        <xsl:variable name="field" select="$missing-fields[1]"/>
        <xsl:variable name="field-inserted">
          <xsl:apply-templates mode="insert-field" select="$form-spec">
            <xsl:with-param name="field"                     select="$field"                                          tunnel="yes"/>
            <xsl:with-param name="path-to-parent"            select="form:path-to-me($field/..)"                      tunnel="yes"/>
            <xsl:with-param name="path-to-preceding-sibling" select="form:path-to-me($field/preceding-sibling::*[1])" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:variable>
        <!-- Recursively process the newly updated document, passing it the remaining list of fields to insert -->
        <xsl:copy-of select="form:insert-fields($field-inserted,
                                                $missing-fields[position() > 1])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

          <xsl:template mode="insert-field" match="@* | node()">
            <xsl:copy/>
          </xsl:template>

          <xsl:template mode="insert-field" match="element()" priority="1">
            <xsl:param name="field"                     tunnel="yes"/>
            <xsl:param name="path-to-parent"            tunnel="yes"/>
            <xsl:param name="path-to-preceding-sibling" tunnel="yes"/>
            <!-- Shallow copy of the element -->
            <xsl:copy>
              <!-- Copy all its attributes -->
              <xsl:apply-templates mode="#current" select="@*"/>
              <xsl:choose>
                <!-- If this is the parent context for the field we're trying to insert... -->
                <xsl:when test="deep-equal(form:path-to-me(.), $path-to-parent)">
                  <xsl:variable name="just-before" select="*[deep-equal(form:path-to-me(.), $path-to-preceding-sibling)]
                                                            [last()]"/>
                  <!-- Process everything up to the just-before node -->
                  <xsl:apply-templates mode="#current" select="node()[$just-before >> . or
                                                                      $just-before is .]"/>
                  <!-- Insert the field -->
                  <xsl:apply-templates mode="copy-field" select="$field"/>
                  <!-- Process everything after the just-before node -->
                  <xsl:apply-templates mode="#current" select="node()[. >> $just-before]"/>
                </xsl:when>
                <!-- Otherwise, just process contents -->
                <xsl:otherwise>
                  <xsl:apply-templates mode="#current"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:copy>
          </xsl:template>

          <xsl:template mode="copy-field" match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

          <!-- Don't insert any default values from the form config file; those should
               only appear when editing a new document -->
          <xsl:template mode="copy-field" match="text()[normalize-space(.)]"/>


  <xsl:function name="form:path-to-me" as="xs:QName*">
    <xsl:param name="element"/>
    <xsl:sequence select="for $e in $element/ancestor-or-self::* return $e/node-name(.)"/>
  </xsl:function>

</xsl:stylesheet>
