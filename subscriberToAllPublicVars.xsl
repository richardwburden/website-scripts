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
set y=2024
set n=44
set v=51
set md=1108
set vn=%v%%n%
set i=%y%/eirv%v%n%n%-%y%%md%
set j=%y%\eirv%v%n%n%-%y%%md%
set u=\Users\rburden\data\websites\EIR\eiw\public\unlisted
set p=\Users\rburden\data\websites\EIR\eiw\public\
set d=https://larouchepub.com/eiw/public/unlisted/
rem use this dir command to determine what should be the value of h, then set h
dir %u%\%j%\
set h=ub0v4lDpEgLaxM32-v8f6N1

perl -w html2xhtml.pl %u%\%j%\%h%\index.html index.xhtml
rem on the Dell computer:
perl -w html2xhtml.pl %u%\%j%\%h%\index.html index.xhtml -Dell

Set the variables newdirs and issuedir, then

use a command line like the following to run subscriberToAllPublic.xsl to generate the public issue index page for the more than 6 week old issue:

java net.sf.saxon.Transform -s:index.xhtml -xsl:subscriberToAllPublic.xsl -o:%p%%j%\indexp.html


Upload indexp.html and verify that it is correct, then copy over to index.html and upload.
-->

<xsl:variable name="newdirs" select="'oe'" />

<xsl:variable name="issuedir" select="'eirv51n44-20241108/'" />
</xsl:stylesheet>
