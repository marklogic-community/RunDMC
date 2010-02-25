<!DOCTYPE xsl:stylesheet [
<!ENTITY  mlns      "http://developer.marklogic.com/site/internal">
]>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns      ="&mlns;"
  xmlns:ml               ="&mlns;"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xpath-default-namespace="&mlns;">

  <xsl:template match="ml:document-list">
    <doc-list>
      <xsl:for-each select="ml:lookup-docs(string(@type), string(@topic))">
        <doc type="{@type}" href="{ml:external-uri(base-uri())}"/>
      </xsl:for-each>
    </doc-list>
  </xsl:template>

          <xsl:function name="ml:lookup-docs" as="element()*">
            <xsl:param name="type"  as="xs:string"/>
            <xsl:param name="topic" as="xs:string"/>
            <xsl:sequence select="collection()/document[((@type  eq $type)  or not($type)) and
                                                        ((@topic eq $topic) or not($topic))]"/>
          </xsl:function>

</xsl:stylesheet>
