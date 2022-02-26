<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- abbreviated form for the directories for the HTML article pages.
h = hzl/
h- = hzl/ and append -hzl to the filename before the extension
l = lar/
l-  = lar/ and append -lar to the filename before the extension
o = other/
ob = other/book_reviews/
oe = other/editorials/
og = other/govt_docs/
oi = other/interviews/
p = pr/
-->

<xsl:variable name="newdirs" select="'oe o oi oi o l- o o o'" />

<xsl:variable name="issuedir" select="'eirv49n02-20220114/'" />
</xsl:stylesheet>
