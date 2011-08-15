#version: 2011-1-10

#!/usr/local/bin/perl -w

use strict;
#use cwd;
use diagnostics;

use LWP::UserAgent;
use LWP::Simple;
#use Win32;
#use Compress::Zlib;
#use Clipboard; or use Win32::Clipboard

#*****************************GLOBAL  VARIABLES****************************#
my $bDEBUG = 0;
my ($TRUE, $FALSE, $SUCCESS, $FAILED) = (1,0,1,0);
my $osVersion = "";

my $NEWLINE = "\r\n";
#*****************************AUXILIARY  FUNCTIONS****************************#
sub DEBUG_INFO {
  return if (!$bDEBUG);
  if (defined(@_)) {
    print "@_\n";
  } else {
    print "Not Defined!\n";
  }
}
sub D {DEBUG_INFO(@_);}
sub P {print "@_\n";}

sub LOG_FILE {
  my($fileName, $bAppData, @logPara) = @_;  #bAppData -- append date to file or overwrite file
  #DEBUG_INFO($fileName, $bAppData);
  $fileName =~ s!\\!/!ig;
  my @pathAry = split('/', $fileName);
  my $tmpPath = "";
  for (my $i=0; $i<scalar(@pathAry)-1; $i++) {
      $tmpPath .= $pathAry[$i] . '/';   #D($tmpPath);
      mkdir($tmpPath, 0111) if (! -d $tmpPath);
  }
  if ($bAppData) {$fileName = " >> " . $fileName;  #append data
  } else         {$fileName = " > "  . $fileName;}

  open(tmpLogFile, $fileName) || die "Cannot open log file: $fileName!\n";
  foreach (@logPara) {
    my ($str0D, $str0A) = ('\r', '\n');  
    s/$str0D//ig;  #remove all '\r' chars
    print tmpLogFile "$_\n";
  }
  close(tmpLogFile);
}

sub download_webpage {
  my ($url, $savedFName) = @_;  D("In download_webpage() -- $savedFName\t$url");
  my $userAgent = new LWP::UserAgent;
  $userAgent->agent('Mozilla/5.0');

  my $req = HTTP::Request->new('GET', $url);
  #my $req = new HTTP::Request ('POST',$address);
  $req->content_type('application/x-www-form-urlencoded');
  #$req->content();

  my $res = $userAgent->request($req);
  LOG_FILE($savedFName, $FALSE, $res->as_string());
}#download_webpage

sub download_bin {
  my ($url, $savedFName) = @_;  D("In download_bin() -- $savedFName\t$url");
  my $outcome = get ($url);
  open FILE,"> $savedFName" || die "$!";
  binmode(FILE);
  print FILE $outcome;  
  close FILE;
}

sub send_request {
  my ($url, $reqStr) = @_;  D("In send_request() -- $url\n$reqStr");

  my $ua = LWP::UserAgent -> new();
  #$ua->agent('Mozilla/5.0');
  $ua->agent('Jakarta Commons-HttpClient/3.1');
  #request
  my $req = new HTTP::Request ('POST',$url);
  #$req->content_type('application/x-www-form-urlencoded');
  $req->content_type('text/xml;charset=UTF-8');
  $req->content($reqStr);
  #response
  my $resp = $ua->request($req);  #D($res->as_string());
  #D($resp->is_success());
  #D($resp->message());
  my $respStr = $resp->content();
  if ($respStr=~/Error/i) {
    P("** Send reqeust got ERROR! **\nExiting...\n"); exit 0;
  }
}#send_request

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;  $string =~ s/\s+$//;
    return $string;
}

sub isEmptyStr {
    my ($result, $str) = (0, @_);
    $result = 1 if (!defined($str) || $str eq "" || $str=~m/^\s+$/ig);
    return $result;
}

sub parse_args {
  P(@_);
  for (my $i=0; $i<scalar(@_); $i++) {
    if ($_[$i] eq "-debug") {
      $bDEBUG = $TRUE;   #D("bDEBUG is set to: $bDEBUG");
    } else {

    }
  }
  if (defined $^O) {$osVersion =  $^O;} else {$osVersion = "win32"; }  D("osVersion is: $osVersion");
}

my $notifCnt = 0;
sub showAsyncMsgBox {
  my ($msgStr) = @_;
  
  my $choice = 4;  #init value to 'retry'
  $notifCnt ++;
  
  my $pid = fork();
  if (not defined $pid) {
    print "resources not avilable.\n";
  } elsif ($pid == 0) {
    D("THE CHILD Thread\n");
    $choice = Win32::MsgBox($msgStr, 48+5, "Notification_$notifCnt") if ($osVersion =~ /win32/i);
    D("The choice is $choice");

    if ($choice == 4) {  #4 -- retry
      #Do nothing, continue to watch on this stock
    } else {
    }
    exit 1;
  } else {  D("THE PARENT Thread\n");  }
}
###############################################################################
sub main {
  print_usage();
  my $option = <STDIN>;    
  $option = '' if (!defined $option);
  if ('1' eq $option) {
    Test01();
  } else {
    Test02();
  }
}

sub Test01 {
  my ($url, $fileName) = ("http://www.csdn.net/", "Temp.txt");

  download_webpage($url, $fileName);
  open(hFileHandle, $fileName) || die "Cannot open file $fileName!";
  while (<hFileHandle>) {
    die "Fail to download $url!\n" if (/500.+Internal Server Error/);
  }
  close(hFileHandle);
}

sub Test02 {
  print "\@INC is @INC\n";
  my @ary = ("0x61", "0x62", "\r", "0x63", );
  LOG_FILE("./test.txt", 0, @ary);
}

sub print_usage {
  print"\n";
  printf("*** Function SELECTOR ***\n");
  printf("* 1. TEST01             *\n");
  printf("* 2. TEST02             *\n");
  printf("*************************\n");

  printf("\nChoose An Option: ");
}
###############################################################################

parse_args(@ARGV);

if (1) {
  main();
} else {
  Test();
}
