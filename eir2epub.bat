rem The command line for this script should be
rem eir2epub config_suffix YYYY\vVVnNN\F
rem where config_suffix is the suffix of the configuration file name
rem e.g. eir2epub-eir.xml has suffix eir
rem where YYYY is the year, VV is the EIR volume number, NN is the issue number, and F is the sub-folder name
rem e.g. eir2epub eir 2022\v49n46\1

perl -w eir2epub.pl %1 %2\OEBPS
pause
