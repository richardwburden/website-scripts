<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- This stylesheet generates relocated EIR article pages in HTML format, relocated from the unlisted directory provided to subscribers, to their permanent, listed home.  Inputs: an EIR issue directory of the form vVVnNN-YYYYMMDD/, an EIR subscriber issue index page converted to XHTML, the unlisted article pages.  -->
<xsl:include href="sendInBlueVars.xsl" />

<xsl:variable name="year" select="substring(substring-after($issuedir,'-'),1,4)" />
 <xsl:variable name="yeardir" select="concat($year,'/')" />

<!-- local webserver document root should be the C drive root directory -->

<xsl:variable name="wspath" select="'http://localhost:8000/Users/Richard/Dropbox_insecure/Dropbox/software/website-scripts/website-scripts/'" />

<xsl:variable name="sidir" select="concat('http://localhost:8000/Users/Richard/Documents/websites/EIR/eiw/public/unlisted/',$yeardir,$issuedir,$hashdir)" />

<xsl:variable name="sipath" select="concat($sidir,'index.xhtml')" />

<xsl:variable name="wwwsipath" select="concat('https://larouchepub.com/eiw/public/unlisted/',$yeardir,$issuedir,$hashdir)" />


<xsl:variable name="sidoc" select="if (doc-available($sipath)) then doc($sipath) else ($sipath)" />

<xsl:variable name="si" select="doc($sipath)/descendant::div[@id='toc']" as="node()" />
	
<xsl:variable name="issue_basename" select="substring($issuedir,1,string-length($issuedir)-1)" />

<xsl:variable name="newdirseq" as="xs:string*" >
<xsl:sequence select="fn:tokenize($newdirs,' ')" />
</xsl:variable>

<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

<!-- output the email message -->

<newdirs>
<dir

<xsl:template match="h3[@class='tocArticle']" priority="2">
<xsl:variable name="pos">
<xsl:value-of select="count(preceding::h3[@class='tocArticle']) + 1"/>
</xsl:variable>
<xsl:variable name="newdirkey">
<xsl:value-of select="subsequence($newdirseq,$pos,1)"/>
</xsl:variable>
<xsl:variable name="articleHref" select="a[@class='tocLinkAltHTML']/@href" />
<xsl:for-each select="doc(concat($sidir,$articleHref))">
<xsl:for-each select="a[@href]">
<xsl:copy>
<xsl:variable name="href" select="./@href" />
<xsl:if test="(substring($href,1,1) ne '/') and not (matches($href,'^[a-z]+//:','i'))">
<xsl:variable name="abshref" select="resolve-uri($href,base-uri(.))" />
<xsl:variable name="newhref" select="concat($newdir,$href)" />
<xsl:attribute name="href">
<xsl:value-of select="$newhref" />
</xsl:attribute>
</xsl:if>

<xsl:for-each select="$row">
<xsl:comment>call row</xsl:comment>
<xsl:apply-templates select="." mode="row">
<xsl:with-param name="href" tunnel="yes" select="$newhref" />
<xsl:with-param name="title" tunnel="yes" select="$newtitle" />
<xsl:with-param name="author" tunnel="yes" select="$newauthor" />
<xsl:with-param name="blurb" tunnel="yes" select="$newblurb" />
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
		<xsl:apply-templates select="node()|@* except @href" />
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
