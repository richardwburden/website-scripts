<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- edit this variable to point to the new issue's public index page -->
<xsl:variable name="issuedir" select="'eirv49n09-20220304/'" />

<!-- abbreviated form for the directories for the public HTML article pages.
Use html2xhtml.pl to generate the XHTML version of the subscriber's issue index page:

cd C:\Users\Richard\Dropbox_insecure\Dropbox\software\website-scripts\website-scripts

set i=eirv49n09-20220304
set h=m8gy_eFcAKQd24Mx
set u=\Users\Richard\Documents\websites\EIR\eiw\public\unlisted
set p=\Users\Richard\Documents\websites\EIR\eiw\public

perl -w html2xhtml.pl %u%\2022\%i%\%h%\index.html %u%\2022\%i%\%h%\index.xhtml

Open index.xhtml in Dreamweaver.
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


Then use a command line like the following to run subscriberToPublic.xsl to generate the public issue index page for the new issue:

java net.sf.saxon.Transform -s:%u%\2022\%i%\%h%\index.xhtml -xsl:subscriberToPublic.xsl -o:%p%\2022\%i%\indexp.html

Upload indexp.html and verify that it is correct, then copy over to index.html and upload.


-->

</xsl:stylesheet>
