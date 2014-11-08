<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="../../setup/optimize-js-requests.xsl"/>

  <!-- These settings override the ones in the imported code. -->
  <xsl:variable name="absolute-js-dir"         select="'/apidoc/js/optimized'"/> <!-- URL path prefix to optimized JS file -->
  <xsl:variable name="js-relative-path-prefix" select="'../..'"/>                <!-- For finding the JS files relative to the stylesheet -->
  <xsl:variable name="stylesheet-uri"          select="static-base-uri()"/>      <!-- This stylesheet URI -->
  <xsl:variable name="server"                  select="'apidoc'"/>               <!-- Used only for informational messages to the console -->

</xsl:stylesheet>
