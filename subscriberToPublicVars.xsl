<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- edit this variable to point to the directory containing the new issue's public index page. This must have a slash at the end, before the closing single quotation mark-->
<xsl:variable name="issuedir" select="'eirv51n50-20241220/'" />

<!-- abbreviated form for the directories for the public HTML article pages.
Use html2xhtml.pl to generate the XHTML version of the subscriber's issue index page:

cd C:\Users\Richard\Dropbox_insecure\Dropbox\software\website-scripts\website-scripts

set j=2022\eirv49n28-20220722
set h=pdb3Lq1Mvixtdeu4CEA_si
set u=\Users\Richard\Documents\websites\EIR\eiw\public\unlisted
set p=\Users\Richard\Documents\websites\EIR\eiw\public\

perl -w html2xhtml.pl %u%\%j%\%h%\index.html %u%\%j%\%h%\indexp.xhtml
rem or for the Dell computer:
perl -w html2xhtml.pl %u%\%j%\%h%\index.html %u%\%j%\%h%\indexp.xhtml -Dell

Open indexp.xhtml in Dreamweaver.
Prefix the title of each public article in the XHTML version of the subscriber's issue index page with one of the following abbreviations followed by ##

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

Make sure that each of these prefixes is at the beginning of the content of the a tag for the title, and not inside any other tag within the a tag, such as an em tag. Otherwise, this script will fail to respond to the prefix. If it is outside the a tag, the prefix will appear in the output.


Then use a command line like the following to run subscriberToPublic.xsl to generate the public issue index page for the new issue:

java net.sf.saxon.Transform -s:%u%\%j%\%h%\indexp.xhtml -xsl:subscriberToPublic.xsl -o:%p%%j%\indexp.html

Upload indexp.html and verify that it is correct, then copy over to index.html and upload.


-->

</xsl:stylesheet>
