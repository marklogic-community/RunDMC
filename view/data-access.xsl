<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp"
  extension-element-prefixes="xdmp">

  <xdmp:import-module href="../model/data-access.xqy"                 namespace="http://developer.marklogic.com/site/internal"/>
  <xdmp:import-module href="/MarkLogic/appservices/search/search.xqy" namespace="http://marklogic.com/appservices/search"/>

</xsl:stylesheet>
