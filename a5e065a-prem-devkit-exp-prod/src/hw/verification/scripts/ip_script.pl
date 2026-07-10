#!/usr/bin/perl

use strict;
use warnings;

#adding the ip list
my $arg = shift @ARGV or die "Usage: $0 HSSI_10G=1 | HSSI_25G=1\n";

my ($feature, $value) = split(/=/, $arg);

die "Invalid format. Use like HSSI_25G=1\n"
    unless defined $feature && defined $value;

my %lines_to_add = (
    'HSSI_10G'  => "set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll.ip 
  set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip.ip",
    'HSSI_25G'  => "set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip_25G.ip
  set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll_25G.ip",
);


die "Unknown feature: $feature. Use HSSI_25G | HSSI_10G\n"
    unless exists $lines_to_add{$feature};

my $filename = "ip_list.tcl";  
my $line_num = 7;  

open my $fh, '<', $filename or die "Could not open '$filename': $!";
my @lines = <$fh>;
close $fh;

splice(@lines, $line_num - 1, 0, $lines_to_add{$feature} . "\n");

open my $out, '>', $filename or die "Could not write '$filename': $!";
print $out @lines;
close $out;

print "Inserted at line $line_num in $filename\n";

#converting .tcl to .f
my $text= '$DESIGNDIR';
#my $text1= '../';
my $text1= '';
#IP LIST
open(my $in,  "<", "ip_list.tcl") or die "Couldn't open ip_list.tcl: $!";
open(my $out, ">", "ip_list.f")   or die "Couldn't open ip_list.f: $!";

while (my $line = <$in>) {
    chomp $line;

    my $char = substr($line, 28, 1);

    if ($char eq "I") {
        #substr($line, 0, 36) = $text1;
        substr($line, 0, 39) = $text1;
    }
    else {
        #substr($line, 0, 38) = $text1;
        substr($line, 0, 41) = $text1;
    }

    print $out "$line\n";
}

close $in;
close $out;

system("mv ip_list.f ../tb/.");
print "Converted ip_list.tcl → ip_list.f successfully\n";
