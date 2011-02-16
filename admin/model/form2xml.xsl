<!-- This stylesheet constructs an XML document from a set of name/value $params.
     One of the params is ~xml_to_edit, which dictates the resulting structure.
     The rest of the params are used to replace values and/or add new elements
     to the result. In a final stage, we perform cleanup and convert elements
     back to attributes where applicable.
-->
<!DOCTYPE xsl:stylesheet
[
<!ENTITY mlns "http://developer.marklogic.com/site/internal">
]>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="&mlns;"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="&mlns;"
  exclude-result-prefixes="xs ml xdmp xhtml form"> <!-- XSLTBUG workaround: exclude-result-prefixes (wrongly) affects nodes copied from the source tree;
                                                                            conversely, <xsl:element> is copying namespace nodes from the stylesheet (also wrongly). -->

  <xsl:param name="params"/>

  <xsl:variable name="doc-path" select="$params[@name eq '~existing_doc_uri']"/>

  <xsl:variable name="base-doc" select="xdmp:unquote(string($params[@name eq '~xml_to_edit']))"/>

  <xsl:variable name="populated">
    <xsl:apply-templates mode="populate" select="$base-doc/*"/>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:apply-templates mode="clean-up" select="$populated"/>
  </xsl:template>

  <!-- By default, copy everything as is -->
  <xsl:template mode="populate" match="@* | node()" name="default-copy-rule">
    <xsl:param name="content"/>
    <!-- XSLTBUG workaround: The processor behaves incorrectly when I try to give the $content parameter a default value (via content).
         Not only that, but it seems to cause intermittent segfaults. -->
    <xsl:variable name="dispatched-content">
      <elementWrapper> <!-- Another XSLTBUG workaround: if I don't include this, then whitespace-only text nodes will get stripped when copied as a direct child of the implicit document node -->
        <xsl:apply-templates mode="populate-content" select="."/>
      </elementWrapper>
    </xsl:variable>
    <xsl:variable name="real-content" select="if ($content) then $content else $dispatched-content/*/node()"/>
    <xsl:copy>
      <xsl:apply-templates mode="populate" select="@*"/>
      <xsl:copy-of select="$real-content"/>
    </xsl:copy>
  </xsl:template>

          <!-- By default, just process children -->
          <xsl:template mode="populate-content" match="*">
            <xsl:apply-templates mode="populate"/>
          </xsl:template>

          <!-- But for fields with names, insert value from the corresponding request parameter -->
          <xsl:template mode="populate-content" match="*[@form:name]">
            <!-- First, process attribute-cum-element fields -->
            <xsl:apply-templates mode="populate" select="*"/>

            <!-- Then get the value of this element -->
            <xsl:copy-of select="form:get-value(., string($params[@name eq current()/@form:name]))"/>
          </xsl:template>

          <!-- For elements that are children of (part of) a repeating group -->
          <xsl:template mode="populate-content" match="*[@form:group-label]/*[@form:name]" priority="1">
            <xsl:param name="position" tunnel="yes"/>
            <!-- First, process attribute-cum-element fields -->
            <xsl:apply-templates mode="populate" select="*"/>

            <!-- Then get the value of this element -->
            <xsl:copy-of select="form:get-value(., string($params[@name eq concat(current()/@form:name,'[',$position,']')]))"/>
          </xsl:template>

                  <!-- For <textarea> values, re-ify the markup -->
                  <xsl:function name="form:get-value">
                    <xsl:param name="config-node"/>
                    <xsl:param name="param-value"/>
                    <xsl:variable name="is-xml-valued" select="$config-node/@form:type eq 'textarea'"/>
                    <!-- XSLTBUG: xdmp:unquote() apparently strips out whitespace-only text nodes, at least at the top level :-( -->
                    <xsl:variable name="unquoted-doc">
                      <xsl:variable name="quoted-doc" select="concat('&lt;docWrapper xmlns:ml=&quot;&mlns;&quot;>', $param-value, '&lt;/docWrapper>')"/>
                      <xsl:if test="$is-xml-valued">
                        <xsl:copy-of select="xdmp:unquote($quoted-doc, 'http://www.w3.org/1999/xhtml')"/>
                      </xsl:if>
                    </xsl:variable>
                    <xsl:sequence select="if ($is-xml-valued) then $unquoted-doc/*/node()
                                                              else $param-value"/>
                  </xsl:function>


          <!-- Special timestamp rule for non-annotated fields; always update <last-updated> and only update <created> if we're creating a new document -->
          <xsl:template mode="populate-content" match="last-updated
                                                     | created[not($doc-path)]">
            <xsl:value-of select="current-dateTime()"/>
          </xsl:template>


  <!-- For repeating elements (not repeating groups) -->
  <xsl:template mode="populate" match="*[@form:name and (@form:repeating eq 'yes')]">
    <xsl:variable name="prefix" select="concat(@form:name, '[')"/>
    <xsl:variable name="element" select="."/>
    <!-- Create one for each parameter that was submitted -->
    <xsl:for-each select="$params[starts-with(@name, $prefix)]">
      <!-- Sort by the positional indicator [1], [2], etc. -->
      <xsl:sort select="form:extract-position(@name)" data-type="number"/>
      <xsl:variable name="param" select="."/>
      <xsl:for-each select="$element">
        <xsl:call-template name="default-copy-rule">
          <xsl:with-param name="content" select="string($param)"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- For elements that represent a repeating group -->
  <xsl:template mode="populate" match="*[@form:group-label]">
    <!-- We are going to use the first child in this group as the prefix to look for among the request parameters -->
    <xsl:variable name="prefix" select="concat(*[1]/@form:name, '[')"/>
    <xsl:variable name="element" select="."/>
    <!-- Create one for each first parameter that was submitted -->
    <xsl:for-each select="$params[starts-with(@name, $prefix)]">
      <!-- Sort by the positional indicator [1], [2], etc. -->
      <xsl:sort select="form:extract-position(@name)" data-type="number"/>
      <xsl:variable name="param" select="."/>
      <!-- DEBUGGING
      <FOUND param="{@name}" prefix="{$prefix}">
      -->
      <xsl:for-each select="$element">
        <xsl:call-template name="default-copy-rule">
          <xsl:with-param name="content">
            <!-- XSLTBUG workaround: using for-each because, for some reason, apply-templates is not triggering the rule for each of the multiple child elements, but only the first -->
            <xsl:for-each select="*">
              <!-- Process the content, passing the current positional context along -->
              <xsl:apply-templates mode="populate" select="."><!--select="*">-->
                <xsl:with-param name="position" select="form:extract-position($param/@name)" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
      <!--
      </FOUND>
      -->
    </xsl:for-each>
  </xsl:template>

          <xsl:function name="form:extract-position">
            <xsl:param name="string"/>
            <xsl:sequence select="number(substring-before(substring-after($string, '['), ']'))"/>
          </xsl:function>

  <!-- Strip out the repeated items; we're replacing them all with values from the parameters -->
  <xsl:template mode="populate" match="*[@form:subsequent-item]"/>


  <!-- By default, copy everything unchanged -->
    <!-- XSLTBUG workaround: copy-namespaces="no" doesn't appear to work
  <xsl:template mode="clean-up" match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="clean-up" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  -->
  <xsl:template mode="clean-up" match="*">
    <!-- XSLTBUG: even then, not all the unnecessary namespaces are removed: xmlns:form remains... -->
    <xsl:element name="{name()}" namespace="{namespace-uri(.)}">
      <!-- Keep the XHTML namespace around so we don't have to see re-declarations all over in the body -->
      <xsl:copy-of select="namespace::*[. eq 'http://www.w3.org/1999/xhtml']"/>
      <!-- Process the attributes-disguised-as-elements first -->
      <xsl:apply-templates mode="#current" select="*[@form:is-attribute]"/>
      <!-- Then process the rest of the elements -->
      <xsl:apply-templates mode="#current" select="@* | node()[not(@form:is-attribute)]"/>
    </xsl:element>
  </xsl:template>

  <xsl:template mode="clean-up" match="@* | comment() | text() | processing-instruction()">
    <xsl:copy/>
  </xsl:template>

  <!-- Strip out optional fields that don't have a value set -->
  <xsl:template mode="clean-up" match="*[@form:optional eq 'yes']

                                        [not(normalize-space(.))]  (: This tests for any non-whitespace text,
                                                                      whether directly contained, inside a child
                                                                      element, or inside (what will be converted to)
                                                                      an attribute; if they're all empty, then
                                                                      we strip it out :)

                                        [not((.//@* except .//@form:*)  (: This test is still necessary in case       :)
                                             [normalize-space(.)]       (: there are hard-coded (fixed and non-       :)
                                            )]                          (: editable) attribute values in the template :)
                                            "/>

  <!-- Convert elements back to attributes -->
  <xsl:template mode="clean-up" match="*[@form:is-attribute]">
    <xsl:attribute name="{name()}" namespace="{namespace-uri(.)}">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- Remove all the @form:* annotations -->
  <xsl:template mode="clean-up" match="@form:*"/>

  <!-- Remove the start and end tags of, e.g., <form:fieldset> -->
  <xsl:template mode="clean-up" match="form:*">
    <xsl:apply-templates mode="clean-up"/>
  </xsl:template>

  </xsl:stylesheet>
