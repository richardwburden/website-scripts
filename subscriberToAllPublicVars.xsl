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


Use html2xhtml.pl to generate the XHTML version of the subscriber's issue index page:

cd C:\Users\Richard\Dropbox_insecure\Dropbox\software\website-scripts\website-scripts

set i=eirv49n03-20220121
set h=iPsUeM8Nw3_cHaM-
set u=\Users\Richard\Documents\websites\EIR\eiw\public\unlisted
set p=\Users\Richard\Documents\websites\EIR\eiw\public

perl -w html2xhtml.pl %u%\2022\%i%\%h%\index.html %u%\2022\%i%\%h%\index.xhtml

Set the variables newdirs and issuedir, then

use a command line like the following to run subscriberToAllPublic.xsl to generate the public issue index page for the more than 6 week old issue:

java net.sf.saxon.Transform -s:%u%\2022\%i%\%h%\index.xhtml -xsl:subscriberToAllPublic.xsl -o:%p%\2022\%i%\indexp.html

Upload indexp.html and verify that it is correct, then copy over to index.html and upload.
-->

<xsl:variable name="newdirs" select="'oe h- o oi l- o o o oi o o o o o'" />

<xsl:variable name="issuedir" select="'eirv49n03-20220121/'" />
</xsl:stylesheet>
