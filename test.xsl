<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

<xsl:variable name="newdirs">
<dir key="o" value="other/" />
<dir key="oe" value="other/editorials/" />
<dir key="oi" value="other/interviews/" />
</xsl:variable>

<!-- identity template -->
<xsl:template match="node()|@*" priority="1">
	<xsl:copy>
		<xsl:apply-templates select="node()|@*"/>
	</xsl:copy>
</xsl:template>

<!-- Add doctype and add language to html element -->
<xsl:template match="html" priority="2">
 	<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;
</xsl:text>
 	<xsl:element name="html">
 		<xsl:attribute name="lang">
 			<xsl:text>en</xsl:text>
 		</xsl:attribute>
 <xsl:apply-templates />
 	</xsl:element>
</xsl:template>

<xsl:template match="node()|@*" mode="newtext">
<xsl:param name="textnode" tunnel="yes" />
<xsl:param name="newtext" tunnel="yes" />

	  <xsl:choose>
	  <xsl:when test=". is $textnode">
	    <xsl:value-of select="$newtext" />
	    </xsl:when>
	  <xsl:otherwise>
	<xsl:copy>
		<xsl:apply-templates select="node()|@*" mode="newtext"/>
	</xsl:copy>
		</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="text()" mode="textnode">
<xsl:param name="newtext" />
<xsl:value-of select="$newtext" />
</xsl:template>

<xsl:template match="a[@href]" priority="2">
<xsl:variable name="textnode" select="subsequence(.//text(),1,1)"/>
<xsl:variable name="key" select="substring($textnode,7)" />
<xsl:variable name="remainder" select="substring($textnode,1,6)" />
<xsl:variable name="val" select="$newdirs/dir[@key=$key]/@value" />
<xsl:comment>Position: <xsl:value-of select="count(preceding::a[@href]) + 1" /></xsl:comment>
<xsl:comment>Key: <xsl:value-of select="$key" /></xsl:comment>
<xsl:copy>
<xsl:apply-templates select="@*"/>
<xsl:value-of select="concat('Position: ',position(),' ')" />
<xsl:value-of select="concat('New directory: ',$val,' ')" />
<xsl:apply-templates select="node()" mode="newtext">
<xsl:with-param name="textnode" select="$textnode" tunnel="yes" />
<xsl:with-param name="newtext" select="$remainder" tunnel="yes" />
</xsl:apply-templates>
</xsl:copy>
<xsl:comment>Position: <xsl:value-of select="position()" />
</xsl:comment>
</xsl:template>
</xsl:stylesheet>
