<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/attribute-labels"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:template match="auto-form">
    <xsl:apply-templates mode="generate-form" select="xdmp:document-get(concat(xdmp:modules-root(),
                                                                        '/admin/forms/',
                                                                        @template))"/>
  </xsl:template>

          <xsl:template mode="generate-form" match="*">
            <form class="adminform" id="codeedit" action="" method="get" enctype="application/x-www-form-urlencoded">
              <input type="submit" name="add" value="Add new" />
              <fieldset>
                <legend>Edit</legend>
                <xsl:apply-templates mode="form-control" select="*"/>
              </fieldset>
            </form>
          </xsl:template>

                  <xsl:template mode="form-control" match="*[not(*)]">
                    <div>
                      <label for="{local-name()}"><xsl:value-of select="@form:label"/></label>
                      <input id="{local-name()}" type="text" />
                    </div>
                  </xsl:template>

</xsl:stylesheet>
