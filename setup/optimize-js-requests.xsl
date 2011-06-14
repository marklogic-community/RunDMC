<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns                  ="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns:my="http://localhost"
  exclude-result-prefixes="xs my">

  <xsl:output indent="no"/>

  <xsl:param name="last-all.js"/>
  <xsl:param name="new-all.js"/>
  <xsl:param name="previous-result"/>

  <!-- Where we store the combined JS files -->
  <xsl:variable name="js-dir" select="'/js/optimized'"/>

  <!-- Get the previous optimized template, if present -->
  <xsl:variable name="previous-template-path" select="concat('../config/', $previous-result)"/>
  <xsl:variable name="previous-template" select="if (doc-available($previous-template-path))
                                               then  doc          ($previous-template-path)
                                               else  ()"/>

  <!-- Get the last combined result, if present -->
  <xsl:variable name="last-js-path" select="concat('..', $js-dir, '/', $last-all.js)"/>
  <xsl:variable name="last-js" select="if (unparsed-text-available($last-js-path))
                                     then  unparsed-text          ($last-js-path)
                                     else  ()"/>

  <!-- Combine all the current local .js files -->
  <xsl:variable name="new-js" as="xs:string">
    <xsl:value-of select="/html/head/script[my:is-local-external-script(.)]/@src/unparsed-text(concat('..', .))" separator="&#xA;"/>
  </xsl:variable>

  <!-- Compare the two to see if we need to update -->
  <xsl:variable name="js-updated" select="not($last-js eq $new-js)"/>

  <xsl:template match="/">
    <!-- Always output the result to new-all.js (which will get renamed to last-all.js) -->
    <xsl:result-document href="..{$js-dir}/new-all.js" method="text">
      <xsl:value-of select="$new-js"/>
    </xsl:result-document>
    <!-- Process template contents -->
    <xsl:apply-templates/>
  </xsl:template>

  <!-- By default, copy everything unchanged -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- But, if applicable, replace the first optimizable script reference with a reference to all-*.js -->
  <xsl:template match="/html/head/script[my:is-local-external-script(.)][1]" priority="1">
    <xsl:choose>
      <!-- If JS has been updated or previous template is missing,
           then create a new script file and reference to it -->
      <xsl:when test="$js-updated or not($previous-template)">
        <xsl:message>JavaScript changes detected; creating new all-*.js file</xsl:message>
        <xsl:variable name="file-name" select="concat($js-dir, '/all-', current-dateTime(), '.js')"/>
        <script src="{$file-name}" type="text/javascript"/>
        <xsl:result-document href="..{$file-name}" method="text">
          <xsl:value-of select="$new-js"/>
        </xsl:result-document>
      </xsl:when>
      <!-- Otherwise, leave the existing script reference unchanged;
           i.e. grab it from the last template we generated -->
      <xsl:otherwise>
        <xsl:message>No JavaScript changes detected; using same all-*.js file</xsl:message>
        <xsl:copy-of select="$previous-template/html/head/script[my:is-local-external-script(.)]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- And strip out all the other local, external script references -->
  <xsl:template match="/html/head/script[my:is-local-external-script(.)]"/>

  <!-- A <script> tag is local and external if it has a "src" attribute that starts with "/" -->
  <xsl:function name="my:is-local-external-script">
    <xsl:param name="script" as="element(script)"/>
    <xsl:sequence select="starts-with($script/@src,'/')"/>
  </xsl:function>

</xsl:stylesheet>
