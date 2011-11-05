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

  <xdmp:import-module href="/model/data-access.xqy"   namespace="http://developer.marklogic.com/site/internal"/>
  <xdmp:import-module href="/model/filter-drafts.xqy" namespace="http://developer.marklogic.com/site/internal/filter-drafts"/>
  <xdmp:import-module href="/MarkLogic/appservices/search/search.xqy" namespace="http://marklogic.com/appservices/search"/>
  <xdmp:import-module href="/lib/util-2.xqy" namespace="http://marklogic.com/rundmc/util"/>
  <xdmp:import-module href="/controller/disqus-info.xqy" namespace="http://marklogic.com/disqus"/>
  <xdmp:import-module href="/controller/server-urls.xqy" namespace="http://marklogic.com/rundmc/server-urls"/>
  <xdmp:import-module href="/lib/cookies.xqy" namespace="http://parthcomp.com/cookies"/>
  <xdmp:import-module href="/lib/stackoverflow.xqy" namespace="http://marklogic.com/stackoverflow"/>

</xsl:stylesheet>
