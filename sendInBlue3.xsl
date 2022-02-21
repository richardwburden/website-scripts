<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- This stylesheet generates a sendInBlue EIR subscriber email in HTML format from an EIR issue directory of the form vVVnNN-YYYYMMDD/, an EIR subscriber issue index page converted to XHTML, and pieces of a saved sendInBlue email in HTML format.  -->
<xsl:include href="sendInBlueVars.xsl" />

<xsl:variable name="year" select="substring(substring-after($issuedir,'-'),1,4)" />
 <xsl:variable name="yeardir" select="concat($year,'/')" />

<!-- local webserver document root should be the C drive root directory -->

<xsl:variable name="wspath" select="'http://localhost:8000/Users/Richard/Dropbox_insecure/Dropbox/software/website-scripts/website-scripts/'" />
<xsl:variable name="sipath" select="concat('http://localhost:8000/Users/Richard/Documents/websites/EIR/eiw/public/unlisted/',$yeardir,$issuedir,$hashdir,'index.xhtml')" />


<xsl:variable name="rowuri" select="concat($wspath,'sendInBlueEmail-row-template-notext.xhtml')" />
<xsl:variable name="rowdoc" select="if (doc-available($rowuri)) then doc($rowuri) else ($rowuri)" />
<xsl:variable name="row" select="doc($rowuri)/descendant::tr[@class='row']" as="node()" />

<xsl:variable name="srowuri" select="concat($wspath,'sendInBlueEmail-section-row-template.xhtml')" />
<xsl:variable name="srowdoc" select="if (doc-available($srowuri)) then doc($srowuri) else ($srowuri)" />
<xsl:variable name="srow" select="doc($srowuri)/descendant::tr[@class='srow']" />

<xsl:variable name="sidoc" select="if (doc-available($sipath)) then doc($sipath) else ($sipath)" />

<xsl:variable name="si" select="doc($sipath)/descendant::div[@id='toc']" as="node()" />


<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

<!-- output the email message -->
<xsl:template match="node()|@*" mode="row">
<xsl:param name="href" tunnel="yes" />
<xsl:param name="title" tunnel="yes" />
<xsl:param name="author" tunnel="yes" />
<xsl:param name="blurb" tunnel="yes" />
<xsl:copy>
<xsl:if test="self::a">
<xsl:attribute name="href">
<xsl:value-of select="$href" />
</xsl:attribute>
</xsl:if>
<!-- copy all the attributes before adding any new child nodes, 
except @href to avoid obliterating the new value for href -->
<xsl:apply-templates select="@* except @href" mode="row" />
<xsl:if test="self::span[@class='title']">
<xsl:element name="br" />
<xsl:value-of select="$title" />
</xsl:if>
<xsl:if test="self::span[@class='author']">
<xsl:value-of select="$author" />
<xsl:choose>
<xsl:when test="count ($author) lt 1">
<xsl:comment>author count: 0</xsl:comment>
</xsl:when>
<xsl:when test="count ($blurb) lt 1">
<xsl:comment>blurb count: 0</xsl:comment>
</xsl:when>
<xsl:when test="count ($author) gt 1">
<xsl:comment>author count: <xsl:value-of select="count($author)" /></xsl:comment>
<xsl:element name="br" />
</xsl:when>
<xsl:when test="count($blurb) gt 1">
<xsl:comment>blurb count: <xsl:value-of select="count($blurb)" /></xsl:comment>
<xsl:element name="br" />
</xsl:when>
<xsl:when test="count($blurb/*) gt 1">
<xsl:comment>blurb child count: <xsl:value-of select="count($blurb/*)" /></xsl:comment>
<xsl:element name="br" />
</xsl:when>
<xsl:when test="string-length($author) + string-length($blurb/text()) gt 60">
<xsl:comment>author strlen: <xsl:value-of select="string-length($author)" /></xsl:comment>
<xsl:comment>blurb text strlen: <xsl:value-of select="string-length($blurb/text())" /></xsl:comment>
<xsl:element name="br" />
</xsl:when>
<xsl:when test="matches($author,'\S+') and matches($blurb/text(),'\S+')">
<xsl:comment>author has non-blank text: <xsl:value-of select="matches($author,'\S+')" /></xsl:comment>
<xsl:comment>blurb has non-blank text: <xsl:value-of select="matches($blurb/text(),'\S+')" /></xsl:comment>
<xsl:value-of select="' &#x000A0; '" />
</xsl:when>
</xsl:choose> 
<xsl:sequence select="$blurb/*" />
</xsl:if>

<xsl:apply-templates select="node()" mode="row" />
</xsl:copy>
</xsl:template>

<xsl:template name="row">
<xsl:param name="href" tunnel="yes" />
<xsl:copy>
<xsl:apply-templates select="node()" mode="row" />
<xsl:comment><xsl:value-of select="$href" /></xsl:comment>
</xsl:copy>
</xsl:template>


<!-- <xsl:for-each select="$si/h3/a[@class='tocLinkAltHTML']/@href">
-->

<xsl:template match="tr[@id='about_larouche']" priority="2">
<xsl:for-each select="$si/h3">
<xsl:variable name="newhref" select="a[@class='tocLinkAltHTML']/@href" />
<xsl:variable name="newtitle" select="a[@class='tocLinkPDF']/text()" />
<!-- select the first following sibling, and only if it is of tocAuthor class -->
<xsl:variable name="newauthor" select="following-sibling::*[1][@class='tocAuthor']/text()" />
<!-- to calculate how many following siblings before the next article -->
<!-- is there a next article in this section? -->
<xsl:variable name="beforenexth3" select="count(following-sibling::*[local-name() = 'h3'][1]/preceding-sibling::p[@class='tocBlurb'])" />
<xsl:variable name="nexth3Exists" select="count(following-sibling::*[local-name() = 'h3'])" />

<!-- <xsl:variable name="beforenexth2" select="count(following-sibling::*[local-name() = 'h2'][1]/preceding-sibling::p[@class='tocBlurb'])" /> -->
<xsl:variable name="blurbExists" select="count(following-sibling::p[@class='tocBlurb'])" />

<!-- <xsl:variable name="nextAnswerListItemPos" select="count(following-sibling::*[local-name() = 'AnswerListItem'][1]/preceding-sibling::*) + 1" /> -->
<xsl:variable name="newblurb" select="if ($blurbExists and $beforenexth3 or not ($nexth3Exists)) then following-sibling::p[@class='tocBlurb'][1] else ()" />

<!--
<xsl:variable name="newblurb" select="following-sibling::*[position() &lt; 3][@class='tocBlurb']/text()" /> -->
<xsl:for-each select="$row">
<xsl:comment>call row</xsl:comment>
<xsl:apply-templates select="." mode="row">
<xsl:with-param name="href" tunnel="yes" select="$newhref" />
<xsl:with-param name="title" tunnel="yes" select="$newtitle" />
<xsl:with-param name="author" tunnel="yes" select="$newauthor" />
<xsl:with-param name="blurb" tunnel="yes" select="$newblurb" />
</xsl:apply-templates>
</xsl:for-each>
</xsl:for-each>
<xsl:copy>
<xsl:apply-templates select="node()|@*"/>
</xsl:copy>
</xsl:template>  


<!-- identity template -->
<xsl:template match="node()|@*" priority="1">
	<xsl:copy>
		<xsl:apply-templates select="node()|@*"/>
	</xsl:copy>
</xsl:template>



<!-- Add doctype and add language to html element   -->
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
</xsl:stylesheet>
