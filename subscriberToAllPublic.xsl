<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- This stylesheet transforms the unlisted EIR issue index page for subscribers into a listed EIR issue index page for the archive 6 weeks after publication, when all articles are made public and listed -->
<xsl:include href="subscriberToAllPublicVars.xsl" />

 <xsl:variable name="year" select="substring(substring-after($issuedir,'-'),1,4)" />
 <xsl:variable name="yeardir" select="concat($year,'/')" />

<xsl:variable name="relativeRootDir" select="'../../../../'" />


<xsl:variable name="newdirseq" as="xs:string*" >
<xsl:sequence select="fn:tokenize($newdirs,' ')" />
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
		<xsl:value-of select="substring-after(@onclick,$issuedir)" />
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




<!-- Reconstruct article PDF links -->
<xsl:template match="a[@class='tocLinkPDF']"  priority="2">
	<xsl:copy>
	<xsl:attribute name="href">
<xsl:value-of select="substring-after(@href,$issuedir)" />
	</xsl:attribute>
	  <xsl:apply-templates select="node()|@* except @href" />
	</xsl:copy>
</xsl:template>

<!-- Reconstruct article HTML links -->
<xsl:template match="a[@class='tocLinkAltHTML']"  priority="2">
<xsl:variable name="pos">
<xsl:value-of select="count(preceding::a[@class='tocLinkAltHTML']) + 1"/>
</xsl:variable>

	<xsl:copy>

		<xsl:attribute name="href">
 <xsl:choose>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'o'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'oe'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/editorials/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'oi'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/interviews/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'ob'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/book_reviews/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'og'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/govt_docs/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'h'">
<xsl:value-of select="fn:concat($relativeRootDir,'hzl/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'h-'">
<xsl:value-of select="fn:concat($relativeRootDir,'hzl/',$yeardir,substring-before(@href,'.html'),'-hzl.html')" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'l'">
<xsl:value-of select="fn:concat($relativeRootDir,'lar/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'l-'">
<xsl:value-of select="fn:concat($relativeRootDir,'lar/',$yeardir,substring-before(@href,'.html'),'-lar.html')" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'o'">
<xsl:value-of select="fn:concat($relativeRootDir,'other/',$yeardir,@href)" />
</xsl:when>
<xsl:when test="fn:subsequence($newdirseq,$pos,1) eq 'p'">
<xsl:value-of select="fn:concat($relativeRootDir,'pr/',$yeardir,@href)" />
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@href" />
</xsl:otherwise>
</xsl:choose>
		   <!-- <xsl:text>clear</xsl:text> -->
			
		</xsl:attribute>
	<xsl:apply-templates select="text() |@* except @href" />


</xsl:copy>
</xsl:template>

 
</xsl:stylesheet>
