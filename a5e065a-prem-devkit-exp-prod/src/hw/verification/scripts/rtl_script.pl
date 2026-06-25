#!/usr/bin/perl

$text= '$DESIGN_DIR';
$text1= '../../';
#RTL LIST
open($DATA3, "<rtl_list.tcl") or die "Couldn't open file file.txt, $!";
open($DATA4, ">rtl_list.f") or die "Couldn't open file file.txt, $!";

while($line2=<$DATA3>)
{
	chomp $line2;
	$a2=substr($line2,28,1);
	$s2="S";
	if($a2 eq $s2){
		substr($line2,0,53)=$text;
		}
	else{
		substr($line2,0,47)=$text;
		}
		
	print $DATA4 "$line2\n";
}


