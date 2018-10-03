<?php
$ext = '.pdf';
if ($_REQUEST{'ext'} === 'epub')
{
	$ext = '.epub';
}
else if ($_REQUEST{'ext'} === 'mobi')
{
	$ext = '.mobi';
}
$fn = 'eirv45n33-20180817';
$fne = $fn.$ext;
// change $archiveRoot to /web/eiw/public/ after 6 weeks
$archiveRoot = '/home/98/99/1009998/web/eiw/public/';
// change $archiveStructure to 'JS' when ready
$archiveStructure = 'GH';
// Sample URLs
// GH: https://larouchepub.com/eiw/private/2018/2018_30-39/2018-36/pdf/eirv45n36.pdf
// GH: https://larouchepub.com/eiw/public/2018/2018_20-29/2018-25/2018-25/pdf/eirv45n25.pdf
// JS: https://larouchepub.com/eiw/public/2004/eirv31n26-20040702/eirv31n26-20040702.pdf

// as a security measure, only serve files located in our directory
if( $fne && $fne=== basename($fne) ) {

  // make sure we're serving a PDF, EPUB or MOBI (and not some system file)
  if( strtolower( strrchr( $fne, '.' ) )== $ext ) {
	 
	  $vol = substr($fn,4,2);
	  $num = substr($fn,7,2);
	  $year = substr($fn,10,4);
	  $mmdd = substr($fn,-4);
	  $numMod10 = $num % 10;
	  $tenNumGroup = $num - $numMod10;
	  $tenNumGroupEnd = $tenNumGroup + 9;
	  if ($tenNumGroup == 0) {$tenNumGroup = '01-09';}
	  else {$tenNumGroup = $tenNumGroup.'-'.$tenNumGroupEnd;}
	  $yearNum = $year.'-'.$num;

	 if ($archiveStructure === 'GH')
	 { 
	  $dir = $archiveRoot.$year.'/'.$year.'_'.$tenNumGroup.'/'.$yearNum.'/';
	  if (substr($archiveRoot,-7) === 'public/') {$dir .= $yearNum.'/';}
	  if ($ext === '.pdf') {$dir .= 'pdf/';}
	  else {$dir .= 'ebook/';}
	  $fn = substr($fn,0,9);
	  $fne = $fn.$ext;
	 }
	 else if ($archiveStructure === 'JS')
	 {
		$dir = $archiveRoot.$year.'/'.'eirv'.$vol.'n'.$num.'-'.$year.$mmdd.'/';	 
	 }
	if (is_dir($dir) === false){print 'directory "'.$dir.'" not found'; exit;}
	chdir($dir);
	if (is_file($fne) === false){print 'file "'.$fne.'" not found in directory "'.$dir.'"'; exit;}

    if( ($num_bytes= @filesize( $fne )) ) {
      // use file pointers instead of readfile()
      // for better performance, esp. with large PDFs
      if( ($fp= @fopen( $fne, 'rb' )) ) { // open binary read success

        // try to conceal our content type
        header('Content-Type: application/octet-stream');

        // cue the client that this shouldn't be displayed inline
        header('Content-Disposition: attachment; filename='.$fne);

        // we don't support byte serving
        header('Accept-Ranges: none');

        header('Content-Length: '.$num_bytes);
        fpassthru( $fp ); // this closes $fp
      }
    }
  }
}
?>
