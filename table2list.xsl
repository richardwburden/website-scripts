<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">
  
  <!-- This stylesheet transforms each row of the table to a paragraph, and column in a row to an item in the paragraph, with a separator specified for each column. -->
  
  
  <xsl:output method="html" omit-xml-declaration="yes" indent="no"/>
  
  <!-- identity templates -->
  <xsl:template match="node()|@*" priority="1">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
	
  <xsl:template match="node()|@*" priority="1" mode="cellContents">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" mode="cellContents" />
    </xsl:copy>
  </xsl:template>

 <xsl:template match="p" priority="2" mode="cellContents">
      <xsl:apply-templates select="node()" mode="cellContents" />
  </xsl:template>
 <xsl:template match="td" priority="2" mode="cellContents">
      <xsl:apply-templates select="node()" mode="cellContents" />
  </xsl:template>
  
  <!-- Add doctype and add language to html element -->
  <xsl:template match="html" priority="2">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt; </xsl:text>
    <xsl:element name="html">
      <xsl:attribute name="lang"> <xsl:text>pr</xsl:text> </xsl:attribute>
      <xsl:apply-templates />
      
    </xsl:element>
  </xsl:template>
  
<xsl:template match="tr"  priority="2">
<xsl:element name="p">
<xsl:attribute name="class"><xsl:text>petition</xsl:text></xsl:attribute>
<xsl:apply-templates select="node()|@*" />
 </xsl:element>
  </xsl:template>

<xsl:template match="td"  priority="2">
<xsl:variable name="pos" as="xs:integer">
<xsl:value-of select="count(preceding-sibling::td)" />
</xsl:variable>
 <xsl:choose>
 <xsl:when test="$pos eq 1">
<xsl:text>(</xsl:text>

<xsl:apply-templates select="node()" mode="cellContents" />

<xsl:text>)</xsl:text>
 </xsl:when>

 <xsl:otherwise>
<xsl:apply-templates select="node()" mode="cellContents" />
 </xsl:otherwise>
      </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
