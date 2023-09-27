<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- This stylesheet transforms the unlisted EIR issue index page for subscribers into a listed EIR issue index page for non-subscribers. Some article PDFs and all full issue PDFs remain private, and the HTML versions of the same articles remain unlisted. -->

<xsl:include href="subscriberToPublicVars.xsl" />

<xsl:variable name="year" select="substring(substring-after($issuedir,'-'),1,4)" />
 <xsl:variable name="yeardir" select="concat($year,'/')" />

<xsl:variable name="relativeRootDir" select="'../../../../'" />


<xsl:variable name="newdirseq" as="xs:string*" >
<xsl:sequence select="fn:tokenize($newdirstr,' ')" />
</xsl:variable>

<!-- <xsl:variable name="unlistedIndexPage" -->

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

<!-- Reconstruct link element, correcting "text" attribute to "type", and relocate hrefs -->
<xsl:template match="link" priority="2">
	<xsl:element name="link">
		<xsl:attribute name="rel">
			<xsl:text>stylesheet</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="type">
			<xsl:text>text/css</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="href">
			<xsl:value-of select="concat('../../css/',substring-after(@href,'css/'))" />
		</xsl:attribute>
	</xsl:element>
</xsl:template>

<!-- relocate href of large cover picture link -->
<xsl:template match="p[@class='tocThumbnail']/a" priority="2">
<xsl:copy>
		<xsl:attribute name="href">
			<xsl:value-of select="substring-after(@href,$issuedir)" />
		</xsl:attribute>
<xsl:apply-templates select="node()|@* except @href" />
</xsl:copy>
	
</xsl:template>

<!-- adjust srcs in script elements -->
<xsl:template match="script" priority="2">
	<xsl:element name="script">
		<xsl:attribute name="src">
			<xsl:value-of select="concat('../../css/',substring-after(@src,'css/'))" />
		</xsl:attribute>
	</xsl:element>
</xsl:template>

<!-- adjust srcs in img elements -->
<xsl:template match="img" priority="2">
	<xsl:copy>
	<xsl:attribute name="src">
<xsl:choose>
<xsl:when test="starts-with(@src,'../../../../../../graphics/')">
<xsl:value-of select="fn:concat($relativeRootDir,'graphics/',substring-after(@src,'graphics/'))" />
</xsl:when>
<xsl:when test="starts-with(@src,concat('/eiw/public/',$yeardir,$issuedir))">
<xsl:value-of select="substring-after(@src,$issuedir)" />
</xsl:when>
<xsl:when test="starts-with(@src,concat($relativeRootDir,$yeardir,$issuedir))">
<xsl:value-of select="substring-after(@src,$issuedir)" />
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@src" />
</xsl:otherwise>
</xsl:choose>
	</xsl:attribute>
	<xsl:apply-templates select="@* except @src" />
	</xsl:copy>
</xsl:template>


<xsl:template match="h3[@class='tocFullIssueView']" priority="2">
	<xsl:copy>
	<xsl:attribute name="class">
<xsl:value-of select="'tocFullIssueViewSub'" />
	</xsl:attribute>
<xsl:apply-templates select="node()|@*"/>
	</xsl:copy>
<xsl:element name="h3">
<xsl:attribute name="class">
<xsl:value-of select="'tocSubscribersOnly'" />
</xsl:attribute>
<xsl:text>(Subscribers only)</xsl:text>
</xsl:element>
</xsl:template>
 
<!-- Reconstruct full issue download links -->
<xsl:template match="div[@id='fullIssueLinks']/button" priority="2">
	<xsl:element name="button">
		<xsl:attribute name="type">
			<xsl:text>button</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="class">
			<xsl:text>buttonA</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="onclick">
			<xsl:text>window.location='</xsl:text>
		<xsl:value-of select="concat('../../../private/',$yeardir,$issuedir,substring-after(@onclick,$issuedir))" />
		</xsl:attribute>
		<xsl:value-of select="text()" />
	</xsl:element>
</xsl:template>

<!-- Make sure title has issue info -->
<xsl:template match="title" priority="2">

<xsl:copy>
		<xsl:text>EIR </xsl:text>
		<xsl:value-of select="normalize-space(//div[@class='tocIssueTitle'])" />

</xsl:copy>
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
		<xsl:value-of select="replace(.,'/eiw/public/unlisted','../../css')" />
	</xsl:comment>
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
		<xsl:apply-templates select="@*"/> 
	</xsl:copy>
</xsl:template>




<!-- Reconstruct article links -->
<xsl:template match="a[@class='tocLinkPDF']"  priority="2">
<xsl:variable name="pos">
<xsl:value-of select="count(preceding::a[@class='tocLinkPDF']) + 1"/>
</xsl:variable>

	<xsl:copy>
	<xsl:attribute name="href">
 <xsl:choose>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq '-'"> <!-- subscriber only -->
<xsl:value-of select="concat('../../../private/',$yeardir,$issuedir,substring-after(@href,$issuedir))" />
</xsl:when>
<xsl:otherwise> <!-- public article -->
<xsl:value-of select="substring-after(@href,$issuedir)" />
</xsl:otherwise>
</xsl:choose>
	</xsl:attribute>
	<xsl:attribute name="class">
 <xsl:choose>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq '-'">
<xsl:value-of select="'tocLinkSubPDF'" />
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@class" />
</xsl:otherwise>
</xsl:choose>
	</xsl:attribute>
	  <xsl:apply-templates select="@* except (@href,@class)" />
<!-- trim the text, so that the text wraps before the PDF (SUBSCRIBERS ONLY) pdf_icon_sub.gif -->
<xsl:value-of select="replace(replace(text(),' +$',''),'^ +','')" />
	</xsl:copy>
</xsl:template>


<xsl:variable name="newdirs">
<dir key="o" value="other/" />
<dir key="oe" value="other/editorials/" />
<dir key="oi" value="other/interviews/" />
<dir key="ob" value="other/book_reviews/" />
<dir key="og" value="other/govt_docs/" />
<dir key="h" value="hzl/" />
<dir key="h-" value="hzl/" />
<dir key="l" value="lar/" />
<dir key="l-" value="lar/" />
<dir key="p" value="pr/" />
</xsl:variable>

<xsl:variable name="newFnSuffixes">
<sfx key="o" value="" />
<sfx key="oe" value="" />
<sfx key="oi" value="" />
<sfx key="ob" value="" />
<sfx key="og" value="" />
<sfx key="h" value="" />
<sfx key="h-" value="-hzl" />
<sfx key="l" value="" />
<sfx key="l-" value="-lar" />
<sfx key="p" value="" />
</xsl:variable>

<xsl:template match="a[@class='tocLinkAltHTML']"  priority="2">
<xsl:variable name="pos">
<xsl:value-of select="count(preceding::a[@class='tocLinkAltHTML']) + 1"/>
</xsl:variable>
	<xsl:copy>
	<xsl:attribute name="href">
<xsl:choose>
<xsl:when test="exists ($newdirs/dir[@key = subsequence($newdirseq,$pos,1)])">
<xsl:value-of select="concat($relativeRootDir,$newdirs/dir[@key = subsequence($newdirseq,$pos,1)]/@value,$yeardir,substring-before(@href,'.html'),$newFnSuffixes/sfx[@key = subsequence($newdirseq,$pos,1)]/@value,'.html')" />
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="'#'" />
</xsl:otherwise>
</xsl:choose> 
	</xsl:attribute>
	<xsl:attribute name="class">
 <xsl:choose>
<xsl:when test="not (exists ($newdirs/dir[@key = subsequence($newdirseq,$pos,1)]))">
<xsl:value-of select="'tocLinkHiddenHTML'" />
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@class" />
</xsl:otherwise>
</xsl:choose>
	</xsl:attribute>
	<xsl:apply-templates select="text()|@* except (@href,@class)" />
</xsl:copy>
</xsl:template>

 
</xsl:stylesheet>
