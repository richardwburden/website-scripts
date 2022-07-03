<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<xsl:variable name="issuedir" select="'eirv49n26-20220701/'" />

<!-- if the index page is public, set hashdir to '', otherwise, hashdir's value should end with a forward slash just like issuedir  -->
<xsl:variable name="hashdir" select="'mov8fjRswRzNcK1-5sED/'" />


<!-- <xsl:variable name="query_string" select="'?utm_source=sendinblue&amp;utm_campaign=EIR_-_February_25_2022&amp;utm_medium=email'" /> -->

<!-- SendInBlue will add the query strings for you -->
<xsl:variable name="query_string" select="''" />


</xsl:stylesheet>
