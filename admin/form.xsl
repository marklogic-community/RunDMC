<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/form/attribute-labels"
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
              <xsl:apply-templates mode="labeled-controls" select="*"/>
            </form>
          </xsl:template>

                  <xsl:template mode="labeled-controls" match="*">
                    <xsl:apply-templates mode="#current" select="(@* except (@label:*|@form:*)) | *"/>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="form:fieldset">
                    <fieldset>
                      <legend>
                        <xsl:value-of select="@legend"/>
                      </legend>
                      <xsl:apply-templates mode="#current" select="*"/>
                    </fieldset>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="@*"/>
                  
                  <xsl:template mode="labeled-controls" match="* [@form:label]
                                                             | @*[local-name(.) = ../@label:*/local-name()]" name="control-with-label">
                    <div>
                      <label for="{local-name()}_{generate-id()}">
                        <xsl:apply-templates mode="control-label" select="."/>
                      </label>
                      <xsl:apply-templates mode="form-control" select="."/>
                    </div>
                  </xsl:template>

                          <xsl:template mode="control-label" match="*">
                            <xsl:value-of select="@form:label"/>
                          </xsl:template>

                          <xsl:template mode="control-label" match="@*">
                            <xsl:value-of select="../@label:*[local-name() eq local-name(current())]"/>
                          </xsl:template>


                          <xsl:template mode="form-control" match="* | @*">
                              <input id ="{local-name()}_{generate-id()}"
                                     name="{local-name()}"
                                     type="text">
                                <xsl:apply-templates mode="class-att" select="."/>
                              </input>
                          </xsl:template>

                                  <xsl:template mode="class-att" match="*[@form:wide eq 'yes']">
                                    <xsl:attribute name="class">wideText</xsl:attribute>
                                  </xsl:template>


                          <xsl:template mode="form-control" match="*[@form:type eq 'textarea']">
                              <input type="submit" name="add_media" value="Add media"/>
                              <br/>
                              <textarea id ="{local-name()}_{generate-id()}"
                                        name="{local-name()}"
                                        cols="30"
                                        rows="5">
                                <xsl:apply-templates mode="class-att" select="."/>
                              </textarea>
                          </xsl:template>

</xsl:stylesheet>
