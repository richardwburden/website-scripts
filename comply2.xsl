<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- This stylesheet fixes issue indexes to make them HTML5 compliant -->

<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

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

<!-- Reconstruct link element, correcting "text" attribute to "type" -->
<xsl:template match="link" priority="2">
	<xsl:element name="link">
		<xsl:attribute name="rel">
			<xsl:text>stylesheet</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="type">
			<xsl:text>text/css</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="href">
			<xsl:value-of select="@href" />
		</xsl:attribute>
	</xsl:element>
</xsl:template>
 
<!-- Reconstruct full issue download links -->
<xsl:template match="h3[starts-with(@class,'tocFullIssue')][a]" priority="2">
	<xsl:element name="button">
		<xsl:attribute name="type">
			<xsl:text>button</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="class">
			<xsl:text>buttonA</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="onclick">
			<xsl:text>window.location='</xsl:text>
			<xsl:value-of select="a/@href" />
			<xsl:text>';</xsl:text>
		</xsl:attribute>
		<xsl:value-of select="a/button/text()" />
	</xsl:element>
	<xsl:element name="br">
	</xsl:element>
</xsl:template>

<!-- Make sure title has issue info -->
<xsl:template match="title" priority="2">
	<xsl:element name="title">
		<xsl:text>EIR </xsl:text>
		<xsl:value-of select="normalize-space(//div[@class='tocIssueTitle'])" />
	</xsl:element>
</xsl:template>

<!-- Remove all type="text/javascript" attributes from script element -->
<xsl:template match="script/@type" priority="2"/>

<!-- Remove all border and charoverride attributes -->
<xsl:template match="@border|@class[starts-with(.,'charoverride')]" priority="2"/>

<!-- Remove all height and width attributes -->
<xsl:template match="@height|@width" priority="2" />

<!-- Remove empty attributes -->
<xsl:template match="@*[not(normalize-space())]" priority="2" />

<!-- Remove all span elements that have either no class, or lc or uc class -->
<xsl:template match="span[not(@class)]|span[@class='lc' or 'uc']" priority="2">
	<xsl:apply-templates select="node()"/>
</xsl:template>

<!-- Remove all strong elements inside article titles -->
<xsl:template match="h3[@class='tocArticle']/descendant::strong" priority="2">
	<xsl:apply-templates select="node()"/>
</xsl:template>

<!-- Make path to SSI callout relative -->
<xsl:template match="comment()" priority="2">
	<xsl:comment>
		<xsl:value-of select="replace(., '/eiw/public/css', '../../css')" />
	</xsl:comment>
</xsl:template>

<!-- Simplify path to George's index page -->
<xsl:template match="p[@class='tocThumbnail']/a" priority="2">
	<xsl:element name="a">
		<xsl:attribute name="href">
			<xsl:value-of select="replace(@href,'../../../../eiw/public/2018/','../')" />
		</xsl:attribute>
		<xsl:if test="@id">
			<xsl:attribute name="id">
				<xsl:value-of select="@id" />
			</xsl:attribute>
		</xsl:if>
		<xsl:if test="@title">
			<xsl:attribute name="title">
				<xsl:value-of select="@title" />
			</xsl:attribute>
		</xsl:if>
		<xsl:apply-templates select="node()"/>
	</xsl:element>
</xsl:template>
  
<!-- Make sure all img elements have "alt" attribute;
use value of "id" if available; otherwise set it to "clear" -->
<xsl:template match="img[not(@alt)]" priority="2">
	<xsl:copy>
		<xsl:attribute name="alt">
			<xsl:choose>
				<xsl:when test="@id">
					<xsl:value-of select="@id" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>clear</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>
