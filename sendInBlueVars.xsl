<xsl:stylesheet version="2.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"  
xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!--

run all these script, and find all these files, unless otherwise specified, in this, the "ws directory": C:\Users\Richard\Dropbox_insecure\Dropbox\software\website-scripts\website-scripts

note that sendInBlue.xsl looks for index.xhtml in issuedir
index.xhtml should be produced from index.html using html2xhtml.pl

prepare the subscriber's index page as input to Saxon for generating the email with placeholders for teasers, etc.

%u% is \Users\Richard\Documents\websites\EIR\eiw\public\unlisted
%p% is \Users\Richard\Documents\websites\EIR\eiw\public\
%j% is year and issue directory e.g. 2022\eirv49n11-20220318
%h% is hash, e.g. Gobe9cJ3xVa_pF2X

set y=2022
set n=33
set v=49
set md=0826
set vn=%v%%n%
set i=%y%/eirv%v%n%n%-%y%%md%
set j=%y%\eirv%v%n%n%-%y%%md%
set h=9n7c02-zPq_sekmC3Nd
set u=\Users\Richard\Documents\websites\EIR\eiw\public\unlisted
set p=\Users\Richard\Documents\websites\EIR\eiw\public\

perl -w html2xhtml.pl %u%\%j%\%h%\index.html %u%\%j%\%h%\index.xhtml
# for the Dell computer,
perl -w html2xhtml.pl %u%\%j%\%h%\index.html %u%\%j%\%h%\index.xhtml -Dell

# or, if the issue is all public

perl -w html2xhtml.pl %p%%j%\index.html %p%%j%\index.xhtml
# for the Dell computer,
perl -w html2xhtml.pl %p%%j%\index.html %p%%j%\index.xhtml -Dell

start a webserver with document root the c drive:

First, open a new command window:

start cmd

Then Run this script in the new command window:

start_local_webserver-c_drive.bat

generate the email with placeholders for teasers, etc.
The Saxon transform engine may fail to insert nodes if the <head> is included in the main input file
Saxon will import the <head> unparsed from sendInBlueEmail-head.html
other input files: 
the section title template: sendInBlueEmail-section-row-template-notext-noanchor.xhtml 
the article link template: sendInBlueEmail-row-template-notext-noanchor.xhtml

java net.sf.saxon.Transform -s:sendInBlueEmail-noArticleLinks-nohead.xhtml -xsl:sendInBlue.xsl -o:junk.html

rem for the Dell computer:
java net.sf.saxon.Transform -s:sendInBlueEmail-noArticleLinks-nohead-Dell.xhtml -xsl:sendInBlue-Dell.xsl -o:junk.html

after adding teasers, etc. in Dreamweaver,

perl -w minify.pl junk2.html junkm.html

paste code from junkm.html into SendInBlue


-->

<xsl:variable name="issuedir" select="'eirv51n47-20241129/'" />

<!-- if the index page is public, set hashdir to '', otherwise, hashdir's value should end with a forward slash just like issuedir  -->
<xsl:variable name="hashdir" select="'pvuwM3iX8vA3_vMwsJqUoLs/'" />


<!-- <xsl:variable name="query_string" select="'?utm_source=sendinblue&amp;utm_campaign=EIR_-_February_25_2022&amp;utm_medium=email'" /> -->

<!-- SendInBlue will add the query strings for you -->
<xsl:variable name="query_string" select="''" />


</xsl:stylesheet>
