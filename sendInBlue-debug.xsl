<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- This stylesheet generates a sendInBlue EIR subscriber email in HTML format from an EIR issue directory of the form vVVnNN-YYYYMMDD/, an EIR subscriber issue index page converted to XHTML, and pieces of a saved sendInBlue email in HTML format.  -->
<xsl:include href="sendInBlueVars.xsl" />

<xsl:variable name="year" select="substring(substring-after($issuedir,'-'),1,4)" />
 <xsl:variable name="yeardir" select="concat($year,'/')" />

<xsl:variable name="vol" select="substring(substring-after($issuedir,'eirv'),1,2)" />
<xsl:variable name="num" select="substring(substring-after($issuedir,'eirv'),4,2)" />

<!-- local webserver document root should be the C drive root directory -->

<xsl:variable name="wspath" select="'http://localhost:8000/Users/Richard/Dropbox_insecure/Dropbox/software/website-scripts/website-scripts/'" />

<xsl:variable name="unlisted" select="if ($hashdir eq '') then '' else 'unlisted/'" />

<xsl:variable name="sipath" select="concat('http://localhost:8000/Users/Richard/Documents/websites/EIR/eiw/public/',$unlisted,$yeardir,$issuedir,$hashdir,'index.xhtml')" />
<xsl:variable name="wwwsipath" select="concat('https://larouchepub.com/eiw/public/',$unlisted,$yeardir,$issuedir,$hashdir)" />

<xsl:variable name="rowuri" select="concat($wspath,'sendInBlueEmail-row-template-notext-noanchor.xhtml')" />
<xsl:variable name="rowdoc" select="if (doc-available($rowuri)) then doc($rowuri) else ()" />
<xsl:variable name="row" select="doc($rowuri)/descendant::tr[@class='row']" as="node()" />

<xsl:variable name="srowuri" select="concat($wspath,'sendInBlueEmail-section-row-template-notext-noanchor.xhtml')" />
<xsl:variable name="srowdoc" select="if (doc-available($srowuri)) then doc($srowuri) else ($srowuri)" />
<xsl:variable name="srow" select="doc($srowuri)/descendant::tr[@class='srow']" />

<xsl:variable name="headuri" select="concat($wspath,'sendInBlueEmail-head.html')" />
<xsl:variable name="headdoc" select="if (unparsed-text-available($headuri)) then unparsed-text($headuri) else ($headuri)" />
<xsl:variable name="head" select="unparsed-text($headuri)" />


<xsl:variable name="sidoc" select="if (doc-available($sipath)) then doc($sipath) else ($sipath)" />

<xsl:variable name="si" select="doc($sipath)/descendant::div[@id='toc']" as="node()" />
	
<xsl:variable name="uery_string" select="substring($query_string,2)" />
<xsl:variable name="issue_basename" select="substring($issuedir,1,string-length($issuedir)-1)" />


<xsl:variable name="pdf_url" select="concat('https://larouchepub.com/eiw/private/',$yeardir,$issuedir,$issue_basename,'.pdf')" />
<xsl:variable name="hires_pdf_url" select="concat('https://larouchepub.com/eiw/private/',$yeardir,$issuedir,$issue_basename,'lg.pdf')" />


<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

<!-- output the email message -->
<xsl:template match="node()|@*" mode="row">
<xsl:param name="href" tunnel="yes" />
<xsl:param name="title" tunnel="yes" />
<xsl:param name="author" tunnel="yes" />
<xsl:param name="blurb" tunnel="yes" />
<xsl:param name="LayoutID" tunnel="yes" />
<xsl:copy>
<xsl:if test="self::a">
<xsl:attribute name="href">
<xsl:value-of select="concat($wwwsipath,$href,$query_string)" />
</xsl:attribute>
</xsl:if>
<!-- copy all the attributes before adding any new child nodes, 
except @href to avoid obliterating the new value for href -->
<xsl:apply-templates select="@* except @href" mode="row" />
<xsl:if test="self::a[@name='Layout']">
<xsl:attribute name="name">
<xsl:value-of select="$LayoutID" />
</xsl:attribute>
</xsl:if>
<xsl:if test="self::table[@id='Layout']">
<xsl:attribute name="id">
<xsl:value-of select="$LayoutID" />
</xsl:attribute>
<xsl:attribute name="name">
<xsl:value-of select="$LayoutID" />
</xsl:attribute>
</xsl:if>
<xsl:if test="self::span[@class='title']">
<xsl:element name="br" />
<xsl:sequence select="$title" />
</xsl:if>
<xsl:if test="self::span[@class='author']">
<xsl:sequence select="$author/node()" />
<xsl:choose>
<xsl:when test="(count($author) + count($blurb)) lt 1">
<xsl:comment>No author or blurb</xsl:comment>
</xsl:when>
<xsl:when test="count ($blurb) lt 1">
<xsl:comment>blurb count: 0</xsl:comment>
</xsl:when>
<xsl:when test="(count($blurb/node()) gt 1) and (count ($author) gt 0)">
<xsl:comment>blurb child count: <xsl:value-of select="count($blurb/node())" /></xsl:comment>
<xsl:element name="br" />
<xsl:sequence select="$blurb/node()" />
</xsl:when>
<xsl:when test="(count ($author) gt 0) and (string-length($author) + string-length($blurb/text()) gt 60)">
<xsl:comment>author strlen: <xsl:value-of select="string-length($author)" /></xsl:comment>
<xsl:comment>blurb text strlen: <xsl:value-of select="string-length($blurb/text())" /></xsl:comment>
<xsl:element name="br" />
<xsl:sequence select="$blurb/node()" />
</xsl:when>
<xsl:when test="matches($author,'\S+') and matches($blurb/text(),'\S+')">
<xsl:comment>author has non-blank text: <xsl:value-of select="matches($author,'\S+')" /></xsl:comment>
<xsl:comment>blurb has non-blank text: <xsl:value-of select="matches($blurb/text(),'\S+')" /></xsl:comment>
<xsl:value-of select="' &#x000A0; '" />
<xsl:sequence select="$blurb/node()" />
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$blurb/node()" />
</xsl:otherwise>
</xsl:choose> 
</xsl:if>

<xsl:apply-templates select="node()" mode="row" />
</xsl:copy>
</xsl:template>


<xsl:template match="node()|@*" mode="srow">
<xsl:param name="stitle" tunnel="yes" />
<xsl:param name="LayoutID" tunnel="yes" />
<xsl:copy>
<!-- copy all the attributes before adding any new child nodes -->
<xsl:apply-templates select="@*" mode="srow" />
<xsl:if test="self::a[@name='Layout']">
<xsl:attribute name="name">
<xsl:value-of select="$LayoutID" />
</xsl:attribute>
</xsl:if>
<xsl:if test="self::table[@name='Layout']">
<xsl:attribute name="name">
<xsl:value-of select="$LayoutID" />
</xsl:attribute>
</xsl:if>
<xsl:if test="self::span[@class='sectionTitle']">
<xsl:value-of select="$stitle" />
</xsl:if>
<xsl:apply-templates select="node()" mode="srow" />
</xsl:copy>
</xsl:template>


  <xsl:key name="article" match="$si/*[not(self::h3[@class='tocArticle'] or self::h2[@class='tocSection'])]" 
           use="generate-id(preceding-sibling::*[self::h3[@class='tocArticle'] or self::h2[@class='tocSection']][1])"/>

<xsl:template match="tr[@id='about_larouche']" priority="2">
<xsl:for-each select="$si/h3[@class='tocArticle'] union $si/h2[@class='tocSection']">
<xsl:variable name="this" select="." />
<xsl:variable name="group" select=". | key('article',generate-id($this))" />
<xsl:variable name="articleNumber" select="4 + position()" />
<xsl:variable name="LayoutID" select="concat('Layout_',$articleNumber)" />
<xsl:choose>
<xsl:when test="self::h3[@class='tocArticle']">
<xsl:variable name="newhref" select="a[@class='tocLinkAltHTML']/@href" />
<xsl:variable name="newtitle" select="a[@class='tocLinkPDF']/node()" />
<!-- select the first following sibling, and only if it is of tocAuthor class -->
<xsl:variable name="newauthor" select="following-sibling::*[1][@class='tocAuthor']" />
<xsl:variable name="newblurbs" select="$group[self::p[@class='tocBlurb']]" />

<xsl:for-each select="$row">
<xsl:apply-templates select="." mode="row">
<xsl:with-param name="href" tunnel="yes" select="$newhref" />
<xsl:with-param name="title" tunnel="yes" select="$newtitle" />
<xsl:with-param name="author" tunnel="yes" select="$newauthor" />
<xsl:with-param name="blurb" tunnel="yes" select="$newblurbs" />
<xsl:with-param name="LayoutID" tunnel="yes" select="$LayoutID" />
</xsl:apply-templates>
</xsl:for-each>
</xsl:when>

<xsl:otherwise> <!-- it's a section head -->
<xsl:variable name="newstitle" select="text()" />
<xsl:for-each select="$srow">
<xsl:comment>call srow</xsl:comment>
<xsl:apply-templates select="." mode="srow">
<xsl:with-param name="stitle" tunnel="yes" select="$newstitle" />
<xsl:with-param name="LayoutID" tunnel="yes" select="$LayoutID" />
</xsl:apply-templates>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>

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

<xsl:template match="a[@id='lar_writings']" priority="2">
	<xsl:copy>
		<xsl:attribute name="href">
		<xsl:value-of select="concat(@href,$query_string)" />
		</xsl:attribute>
		<xsl:apply-templates select="node()|@* except @href" />
	</xsl:copy>
</xsl:template>
	
	
	<xsl:template match="tr[@id='subscriber_services']" priority="4">
		<xsl:copy>
					<xsl:apply-templates select="@*" />

		<xsl:comment>I saw: <xsl:value-of select="$uery_string" /></xsl:comment>
		<xsl:apply-templates select="node()" />
			</xsl:copy>
	</xsl:template>
						 
						 
	
<xsl:template match="tr[@id='subscriber_services']//a" priority="2">
	<xsl:comment>I saw it: href=<xsl:value-of select="@href"/></xsl:comment>
	<xsl:copy>
				<xsl:apply-templates select="@*" />

		<xsl:attribute name="href">
		<xsl:choose>
			
		<xsl:when test="(substring(@href,string-length(@href)) eq '?') or (substring(@href,string-length(@href)) eq '&amp;')">
			
		<xsl:value-of select="concat(@href,$uery_string)" />
		</xsl:when>		
			
		
		<xsl:when test="@id eq 'pdf'">
					<xsl:value-of select="concat($pdf_url,$query_string)" />
		</xsl:when>
			
		<xsl:when test="@id eq 'hires_pdf'">

		<xsl:value-of select="concat($hires_pdf_url,$query_string)" />	

		</xsl:when>

			
		<xsl:otherwise>
			
		<xsl:value-of select="@href" />	
				
		</xsl:otherwise>	
		</xsl:choose>
			</xsl:attribute>
				<xsl:comment>I saw it</xsl:comment>
	
		<xsl:apply-templates select="node()" />
</xsl:copy>
</xsl:template>
	
<xsl:template match="div[@id='cover']/a" priority="2">
	<xsl:copy>
		<xsl:attribute name="href">
		<xsl:value-of select="concat($wwwsipath,@href,$query_string)" />
		</xsl:attribute>
		<xsl:apply-templates select="node()|@* except (@href)" />
	</xsl:copy>
</xsl:template>

<xsl:template match="div[@id='cover']/a/img" priority="2">
	<xsl:copy>
		<xsl:attribute name="alt">
		<xsl:value-of select="concat('EIR Vol. ',$vol,' No. ',$num,' cover')" />
		</xsl:attribute>
		<xsl:apply-templates select="@* except @alt" />
	</xsl:copy>
</xsl:template>


<!-- Add doctype and add language to html element, then insert head from unparsed input file   -->
<xsl:template match="html" priority="3">
 	<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;
</xsl:text>
 	<xsl:element name="html">
 		<xsl:attribute name="lang">
 			<xsl:text>en</xsl:text>
 		</xsl:attribute>
<xsl:value-of select="$head" disable-output-escaping="yes" />
 <xsl:apply-templates />
 	</xsl:element>
</xsl:template> 
</xsl:stylesheet>
