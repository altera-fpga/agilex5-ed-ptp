#!/usr/bin/env perl
use warnings;

use MIME::Lite; 
use Net::SMTP;

my $OFS_ROOTDIR=`git rev-parse --show-toplevel`; 

my $filename ;
my $comp_log_end_pattern;
my $sim_log_end_pattern;
my $runsim ;
my $sim = '../sim';
my $testdir = ' '; 
my $a = "FAILED"; 
my $b = "FAILED"; 
my $flag = 0;
my $run = 0;
my $result = ' ';
my $testcase_no = 1;
my $pass_count = 0;
my $fail_count = 0;
my $seed;
my $simulator = "vcs";
my $data = "<table border='1'>";
my $count=0;
my $variant = 'Base FIM';
my $git_rev = `git log -n 1`;
my $scripts=`pwd`;
my $sanitytests = `echo \${ROOTDIR}/verification/tb/tests/sequences/sm_ptp_virtual_seq_list.sv`;
my @tests_to_run ;
chomp $scripts;
push(@tests_to_run,$sanitytests);

$filename = '../sim/vcs.log';
$comp_log_end_pattern = 'CPU';
$sim_log_end_pattern = 'CPU Time|Fatal: ';
$runsim = '';

if ($ARGV[0] eq "cov") {
   $coverage = 'COV=1';
} elsif ($ARGV[0] eq "nocov") {
   print "coverage option is disabled";
   $coverage = 'NOCOV=1';
} else {
   die "please provide first option as cov/nocov for coverage";
}


if ($ARGV[1] eq "25G") {
system("gmake -f Makefile.mk cmplib HSSI_25G=1");
system("gmake -f Makefile.mk build HSSI_25G=1 $coverage");
} elsif ($ARGV[1] eq "10G") {
system("gmake -f Makefile.mk cmplib HSSI_10G=1");
system("gmake -f Makefile.mk build  HSSI_10G=1 $coverage");
}

while (1) {
  if (-e $filename) {
    print "Compilation log is created..!";
    last;
  }
}

open(my $fh,  $filename)
  or die "Could not open file '$filename' $!";

while (1) { 
  while (my $row = <$fh>) {
    chomp $row;
    if($row =~ m/$comp_log_end_pattern/)
    { print "$row\n"; $flag = 1; }
  }
  if($flag == 1) {
   last;
  }
}

foreach my $item(@tests_to_run) {
  open(my $sh,  $item)
  or die "Could not open file '$item' $!";

  while (my $test = <$sh>) {
    chomp $test;
    next if($test =~ m/`include "(axi_base_sequence_pkg).sv"/);
    next if($test =~ m/`include "(sm_ptp_null_virtual_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_simple_reset_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_axi_master_base_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_basic_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_msgdma_cfg_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_axi_slave_host_response_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_basic_data_path_seq).sv"/);

    if($test =~ m/`include "(sm_ptp_.*).sv"/)
    {
      print "$1\n";
        $runsim = "simulate_$1.log";
        my $testname = join('/',$sim,$1,$runsim);
        $testdir = $1;
        print "$testdir\n";
        print "$runsim\n";
        print "$testname\n";
        system("arc submit -PE flow/sw/bigmem mem=20000 -- \" gmake -f Makefile.mk SEQNAME=$testdir run $coverage\"");
    }
  }
  close $sh;
}

foreach my $item(@tests_to_run) {
  open(my $sh,  $item)
  or die "Could not open file '$item' $!";
  
  while (my $test = <$sh>) {
    chomp $test;
    next if($test =~ m/`include "(axi_base_sequence_pkg).sv"/);
    next if($test =~ m/`include "(sm_ptp_null_virtual_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_simple_reset_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_axi_master_base_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_basic_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_msgdma_cfg_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_axi_slave_host_response_seq).sv"/);
    next if($test =~ m/`include "(sm_ptp_basic_data_path_seq).sv"/);
  
    if($test =~ m/`include "(sm_ptp_.*).sv"/) {
      print "$1\n";
      $runsim = "simulate_$1.log";
      my $testname = join('/',$sim,$1,$runsim);
      $testdir = $1; 
  
      while (1) {
        print "check if $testname exists";
        if (-e $testname) {
          print "runsim.log is created";
          last;
        }
      }
  
      open(my $rh,  $testname)
      or die "Could not open file '$testname' $!";
      $run=0;
         
      while (1) { 
        while (my $row = <$rh>) {
         chomp $row;
           if($row =~ m/$sim_log_end_pattern/)
                { print "$row\n"; $run = 1; $row = <$rh>;}
        }
        if($run == 1) {
          last;
        }
      }
      close($rh);   
      ######Processing runsim.log files #################
  
      open(my $ph,  $testname)
       or die "Could not open file '$testname' $!";
  
      print "Processing $testname \n";
      $a = "FAILED";
      $b = "FAILED";
  
      while(my $row = <$ph>) {
        chomp $row;

        if($row =~ m/UVM_ERROR :    0|finish called from file.*top_tb/) {
          $a = "PASSED";
          print "Found 0 UVM_ERROR in $testname \n";
        }
        if($row =~ m/UVM_FATAL :    0|finish called from file.*top_tb/) {
          $b = "PASSED";
          print "Found 0 UVM_FATAL in $testname \n";
          last;
        }
        if($row =~ m/NOTE: automatic random seed used:(\s*)(\d*)/){
           $seed = $2;
        }
      }
      print "processing done...\n";
  
      if($a eq "PASSED" && $b eq "PASSED") {
        $result = "PASSED"."\n";
      } else {
        $result = "FAILED"."\n";
      }
  
      if($count == 0) {   
       $data .= "<tr><td>S.No</td><td>Testcase Name</td><td>Seed value</td><td>Status</td></tr>"; 
       $count++;
      }
      if($a eq "PASSED" && $b eq "PASSED") {
       $data .= "<tr><td>$testcase_no</td><td>$testdir</td><td>$seed</td><td>$result</td></tr>";
       $pass_count++;
      } else {
       $data .= "<tr><td>$testcase_no</td><td>$testdir</td><td>$seed</td><td><font size=\"3\" color=\"#FF0000\">$result</td></tr>";
       $fail_count++;
      }
      $testcase_no++;
    }
  }
}
  
$testcase_no--;
$data .= "</table>";
#$data .= "<pre><h2> Total Testcases - $testcase_no </h2></pre>";
#$data .= "<pre><h2> Total Pass      - $pass_count  </h2></pre>";
#$data .= "<pre><h2> Total Fail      - $fail_count  </h2></pre>";
$data .= "<p> Result Dir      - $scripts/../sim </p>";
$data .= "<p> GIT Revision    - $git_rev </p>";

#my $sender = 'drajarat@ecsmtp.sc.altera.com';
my $sender = 'drajarat@ecsmtp-altera.sc.intel.com';
my $receiver = 'dinesh.babu.rajarathinam@altera.com alekhya.yerramreddy@altera.com ipsita.das@altera.com';
my $mail_host = 'smtp.intel.com';
my $msg_body ="Attached is a file";

################# Post processing for email 
#
if ($ARGV[1] eq "25G") {
my $msg = MIME::Lite->new(
    From    => $sender,
    To      => $receiver,
    #Cc      => $cc_receiver,
    Subject => "Regression results for SMPLUS 25G PTP ED UVM simulations - Tool: $simulator",
  #  Data    => $msg_body,
   Type    =>"multipart/mixed",
);


$msg->attach(Type         => 'text/html',
             Data         => $data 
             );

#$msg->attach('Type'     => 'application/octet-stream',
#             'Encoding' => 'base64',
#              Path      => "outfile.txt"
#          );

print "send mail\n";
MIME::Lite->send('smtp',$mail_host , Timeout=>60);
$msg->send();
}
} elsif ($ARGV[1] eq "10G") {
my $msg = MIME::Lite->new(
    From    => $sender,
    To      => $receiver,
    #Cc      => $cc_receiver,
    Subject => "Regression results for SMPLUS 10G PTP ED UVM simulations - Tool: $simulator",
  #  Data    => $msg_body,
   Type    =>"multipart/mixed",
);


$msg->attach(Type         => 'text/html',
             Data         => $data 
             );

#$msg->attach('Type'     => 'application/octet-stream',
#             'Encoding' => 'base64',
#              Path      => "outfile.txt"
#          );

print "send mail\n";
MIME::Lite->send('smtp',$mail_host , Timeout=>60);
$msg->send();
}
}
        
print "mail sent\n";
