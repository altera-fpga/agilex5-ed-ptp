#!/usr/intel/pkgs/perl/5.14.1/bin/perl
use strict;
use Cwd qw();
my $input_path     = $ARGV[0] ;
my $ptile_top_path = $input_path."qsys/qsys_top/sim/qsys_top.v";
print "PTILE PATH = $ptile_top_path\n";

#===============================================
# [STAGE:1] Copying required files from IP Path
#===============================================
system("cp $ptile_top_path .");


#=====================================================
# [STAGE:2] Adding HPS_ENABLE in Ptile top RTL file 
#=====================================================
open(my $FHW,">","temp1.f");
open(my $FHR,"<","$ptile_top_path");
my $flag = 0;
while(<$FHR>)
{
  if($_ =~ m/subsys_hps \(|subsys_sgmii_emac1 \(/)
   {
      print $FHW "`ifdef HPS_ENABLE\n";
      print $FHW "$_";
      $flag = 1;
   }
  elsif(($_ =~ m/\);/) && $flag==1)
   {
      print $FHW "$_";
      print $FHW "`endif\n";
      $flag = 0;
   }
  else
  {
      print $FHW "$_";
  }  
}
close FHR;
close FHW;
system("rm qsys_top.v");
system("mv temp1.f qsys_top.v");
system("mv qsys_top.v ../tb/");

#=====================================================
# [STAGE:3] Adding updated RTL in rtl filelist 
#=====================================================
my $path = Cwd::cwd();
#open(my $FHW,">","rtl_filelist.f");
#print $FHW "$path/qsys_top.v\n";
#close FHW;
