#version: 2012-03-14

#!/usr/local/bin/perl -w
use strict;
#use cwd;
use diagnostics;

use LWP::UserAgent;
use Win32;
use HTTP::Request;
use Encode;

#require './StockPrice/StockPrice.pl';

#*****************************GLOBAL  VARIABLES****************************#
my $bDEBUG = 0;
my ($TRUE, $FALSE, $SUCCESS, $FAILED) = (1,0,1,0);
my $osVersion = "";

my $NEWLINE = "\r\n";
my $SLEEP_TIME = 30;  #sleep time in seconds

my $bSpecificStkCode = $FALSE;
my @gStkCodeListAry = ();

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
  foreach (@logPara) {print tmpLogFile "$_\n";}
  close(tmpLogFile);
}

sub download_webpage {
  my ($url, $downloadFName) = @_;
  D("In download_webpage() -- $downloadFName\t$url");

  my $userAgent = new LWP::UserAgent;
  $userAgent->agent('Mozilla/4.0');

  my $req = HTTP::Request->new('GET', $url);
  #my $req = new HTTP::Request ('POST',$address);
  $req->content_type('application/x-www-form-urlencoded');
  #$req->content();

  my $res = $userAgent->request($req);
  LOG_FILE($downloadFName, $FALSE, $res->as_string());
  
}#download_webpage

sub send_request {
  my ($url, $reqStr) = @_;
  D("In send_request() -- $url\n$reqStr");

  my $ua = new LWP::UserAgent;
  #$ua->agent('Mozilla/5.0');
  $ua->agent('Jakarta Commons-HttpClient/3.1');

  my $req = new HTTP::Request ('POST',$url);
  #$req->content_type('application/x-www-form-urlencoded');
  $req->content_type('text/xml;charset=UTF-8');
  $req->content($reqStr);

  my $res = $ua->request($req);  #response
  #D($res->as_string());
  #D($res->is_success());
  #D($res->message());

  my $respStr = $res->content();
  if ($respStr=~/Error/i) {
    P("** Send reqeust got ERROR! **\nExiting...\n");
    exit 0;
  }
  
}#send_request

sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;  $string =~ s/\s+$//;
  return $string;
}

sub isEmptyStr {
  my ($str) = @_;
  my $result = 0;
  if (!defined($str) || $str eq "" || $str=~m/^\s+$/ig) {
      $result = 1;
  }
  return $result;
}
sub convToLetter {
  my ($digi, $result) = (@_, "");

  for (my $i=0; $i<length($digi); $i++) {
    my $ch = substr($digi, $i, 1);
    if ($ch =~ /\d/) {
      #$result .= chr($ch+65);
      if   ($ch eq '1') {$ch = 'Y';}
      elsif($ch eq '2') {$ch = "E";}
      elsif($ch eq '3') {$ch = "Sa";}
      elsif($ch eq '4') {$ch = "Si";}
      elsif($ch eq '5') {$ch = "W";}
      elsif($ch eq '6') {$ch = "L";}
      elsif($ch eq '7') {$ch = "Q";}
      elsif($ch eq '8') {$ch = "B";}
      elsif($ch eq '9') {$ch = "J";}
      elsif($ch eq '0') {$ch = "Z";}
    }

    $result .= $ch;
  }
  #D($result);
  return $result;
}
sub parse_args {
  P(@_);
  for (my $i=0; $i<scalar(@_); $i++) {
    my $arg = $_[$i];
    if ($arg eq "-debug") {
      $bDEBUG = $TRUE;   #D("bDEBUG is set to: $bDEBUG");

    } elsif ($arg eq "-stockcode") {
      $bSpecificStkCode = $TRUE;
      while ($i<scalar(@_)-1 && defined $_[$i+1] && $_[$i+1]=~m/^\d{6}$/
      ) {
        push(@gStkCodeListAry, $_[$i+1]);
        $i++;
      }
      D("Stockcode has: ", @gStkCodeListAry);
    }
  }

  if (defined $^O) {$osVersion =  $^O;} else {$osVersion = "win32"; }
  D("osVersion is: $osVersion");
}

sub getMarketType {
  my ($stkCode) = @_;
  my $marketType = ($stkCode =~ m/^sh|^60/i) ? "sh"
                 : ($stkCode =~ m/^sz|^00[01]|^399|^15/i) ? "sz"
                 : ($stkCode =~ m/^002/)    ? "zx"
                 : ($stkCode =~ m/^30/)     ? "cy"
                 : "ot";
  return $marketType;
}
###############################################################################
sub getSymbolPriceTable {
  my ($refSymbolPriceTbl) = @_;

  if ($bSpecificStkCode) {
    for (my $i=0; $i<scalar(@gStkCodeListAry); $i++) {
      my $key = sprintf("%d_%s%s", $i+1, getMarketType($gStkCodeListAry[$i]), $gStkCodeListAry[$i] );
      $$refSymbolPriceTbl{$key} = "10|11|12";  #支撑|阻力|成本 (Yuan)
    }
    return;
  }

  my ($stocksPage, $downloadFName) = ("http://blog.csdn.net/choclover/article/details/7352863", "./Temp/WatchedStocks.htm");

  unlink $downloadFName;  download_webpage($stocksPage, $downloadFName);
  open(hFileHandle02, $downloadFName) || die "Cannot open file $downloadFName!";
  my $bContentStart = $FALSE;
  while (<hFileHandle02>) {
    last if (m/<div class="share_buttons"/);
    if (m/<div id="article_content"/) {
    	$bContentStart = $TRUE;
    }
    next if ($FALSE==$bContentStart || not m/=&gt;/ig);
				
    my $aLine = trim($_);
		D("aLine is: $aLine");
		next if ($aLine=~m/^#/ || $aLine=~m/^<p>#/);
		
    $aLine =~ s/\s+//ig;
    my @stockCodeAry  = ($aLine =~ m/\&quot;(\d+_s[hz]\d{6})/ig);
    my @stockLimitAry = ($aLine =~ m/\&quot;([\d\s\.,]+\|[\d\s\.,]+\|[\d\s\.,]+)/ig); 
    D("stockCodeAry is:", @stockCodeAry); D("stockLimitAry is:", @stockLimitAry);
    for (my $i=0; $i<scalar(@stockCodeAry); $i++) {
      $$refSymbolPriceTbl{$stockCodeAry[$i]} = $stockLimitAry[$i];
    }

  }
  
  close(hFileHandle02);
  D(keys %$refSymbolPriceTbl);  D(values %$refSymbolPriceTbl);
}

sub getSymbolPriceTable_old {
  my ($refSymbolPriceTbl) = @_;

  if ($bSpecificStkCode) {
    for (my $i=0; $i<scalar(@gStkCodeListAry); $i++) {
      my $key = sprintf("%d_%s%s", $i+1, getMarketType($gStkCodeListAry[$i]), $gStkCodeListAry[$i] );
      $$refSymbolPriceTbl{$key} = "10|11|12";
    }
    return;
  }

  my ($stocksPage, $downloadFName) = ("http://blog.sina.com.cn/s/blog_4d6091860100mhcu.html", "./Temp/WatchedStocks.htm");

  unlink $downloadFName;  download_webpage($stocksPage, $downloadFName);
  open(hFileHandle02, $downloadFName) || die "Cannot open file $downloadFName!";
  while (<hFileHandle02>) {
    last if (m/<!-- 正文结束 -->/);
    next if (!m/=&gt;/ig);

    my $aLine = trim($_);
    while (not (m!<br\s*/>!ig || m!</P>!ig) ) {
      $_ = (<hFileHandle02>);  #D($_);
      $aLine .= trim($_);
    }
    D("aLine is: $aLine");
    next if ($aLine=~m/^#/ || $aLine=~m/^<p>#/);

    $aLine =~ s/\s+//ig;
    my @stockCodeAry  = ($aLine =~ m/\"(\d+_s[hz]\d{6})/ig);
    my @stockLimitAry = ($aLine =~ m/\"([\d\s\.,]+\|[\d\s\.,]+\|[\d\s\.,]+)/ig);  #($aLine =~ m/\"([\d\s\.,]+\|[\d\s\.,]+\|*[\d\s\.,]*)/ig);
    D("stockCodeAry is:", @stockCodeAry); D("stockLimitAry is:", @stockLimitAry);
    for (my $i=0; $i<scalar(@stockCodeAry); $i++) {
      $$refSymbolPriceTbl{$stockCodeAry[$i]} = $stockLimitAry[$i];
    }
  }
  close(hFileHandle02);
  #D(keys %symbolPriceTbl);  D(values %symbolPriceTbl);
}

sub InstantPriceInfo {
  my %symbolPriceTbl = (  #hemerr
#   "sh601166" => "20|30", "sh600036" => "13|15",
#   "sh601988" => "3.2|3.8", "sh600238" => "15|22",
#   "sz002406" => "28|35", "sz002008" => "15|20",
#   "sz399001" => "11000|13000",  "sh000001" => "2800|3200",
    );

  my ($url, $downloadFName) = ("http://60.28.2.66/list=", "./Temp/price_page.html");
  my ($code, $name, $latestP, $lastP, $openP, $highestP, $lowestP, $currTime) = ();
  my ($prevTime, $latestTime) = ("", "");
  my ($higherLimit, $lowerLimit, $costLimit) = ("", "", "");
  my $noDataTimes = 0;

  getSymbolPriceTable(\%symbolPriceTbl);
  D(keys %symbolPriceTbl, values %symbolPriceTbl);

  while (1) {
    my $notifyStr = "";

    $url = "http://60.28.2.66/list=";
    my @symbolAry = sort keys %symbolPriceTbl;

    for (my $i=0; $i<scalar(@symbolAry); $i++) {
      #$str = convToLetter($symbolAry[$i]);
      $url .= substr($symbolAry[$i], index($symbolAry[$i], '_')+1);   #D($url);
      $url .= "," if ($i<scalar(@symbolAry)-1);

      #($lowerLimit, $higherLimit) = ($symbolPriceTbl{$symbolAry[$i]}=~m/(.*)\|(.*)/ig);  #D($higherLimit, $lowerLimit);
    }
    D("Target URL is: ", $url);
    download_webpage($url, $downloadFName);

    $latestTime = "";
    open(hFileHandle01, $downloadFName) || die "Cannot open file $downloadFName!";
    while (<hFileHandle01>)
    {
      die "Fail to download $url!\n" if (/500.+Internal Server Error/);
      next if (!m/var hq_str_/ig);

      my $tmpStr = $_;
      ($code, $name, $openP, $lastP, $latestP, $highestP, $lowestP, $currTime)
        = $tmpStr =~ m/var hq_str_(\S+)=\"([^,]+),(\d+\.?\d*),(\d+\.?\d*),(\d+\.?\d*),(\d+\.?\d*),(\d+\.?\d*),.*,(\d+:\d{2}:\d{2})\"/i;
      D($code, $latestP, $lastP, $openP, $highestP, $lowestP, $currTime);

      #P($currTime, $prevTime);
      $currTime = 0 if (not defined $currTime);
      if ($currTime le $prevTime)   #earlier or equal to the $prevTime
      #if (0)  #hemerr
      {
        last;
      }
      $latestTime = $currTime if ($currTime ge $latestTime);

      my $prefix=1;
      if (defined $code) {
        while ($prefix < 50) {
          my $newCode = "$prefix\_$code";  #D($newCode);
          if (exists $symbolPriceTbl{$newCode}) {
            $code = "$prefix\_$code";  #D($code);  #exit 1;
            last;
          }
          $prefix++;
        }
      }

      if (defined $code && $prefix<50) {
        #printf("%s(%s%s):  \tLA-%.2f  LO-%.2f  HI-%.2f  UP-%.2f\n", convToLetter($code), substr($name, 0, 2), substr($name, 4, 2), $latestP, $lowestP, $highestP, ($latestP/$openP-1)*100 );
        my $stkName = substr($name, 2, 4);
        #$stkName = encode("utf8", decode("gbk", $stkName) ) if ($osVersion !~ /win32/i);

        my $tmpStr = sprintf("%s(%s):\tUP:%-6.2f  LA:%-6.2f  LO:%-6.2f  HI:%-6.2f  \n",
                             convToLetter(substr($code, index($code, '_')+3)),
                             $stkName,
                             ($latestP/$lastP-1)*100,
                             $latestP, $lowestP, $highestP,  );
        print $tmpStr;
        $notifyStr .= $tmpStr;

        #D($symbolPriceTbl{$code});
        ($lowerLimit, $higherLimit, $costLimit) = ($symbolPriceTbl{$code}=~m/^(.*)\|(.*)\|(.*)/ig);
        $costLimit = 999 if (not defined $costLimit);
        D("higherLimit: $higherLimit, lowerLimit: $lowerLimit, costLimit: $costLimit");
        my @lowerLimitAry = split(',', $lowerLimit);  D($lowerLimit, @lowerLimitAry);
        my @higherLimitAry = split(',', $higherLimit);  D($higherLimit, @higherLimitAry);

        my $msgStr = "";
        if (defined $costLimit && $lastP < $costLimit && $latestP >= $costLimit ) {
          $msgStr = convToLetter( ($code=~m/(s[hz]\d{6})/i)[0] ) . " has exceeded Cost Limit: $costLimit\n";
          P($msgStr);
          $costLimit = 0;
        }
        if ($latestP > $higherLimitAry[0]) {
          #D($symbolPriceTbl{$code});
          $msgStr = sprintf("UP! %s is higher than Upper Limit: $higherLimitAry[0]\n", convToLetter(($code=~m/(s[hz]\d{6})/i)[0]) );
          P($msgStr);

          if (scalar(@higherLimitAry) <= 1)  {
            $higherLimit = $higherLimitAry[0] * 1.05;
          } else {
            shift @higherLimitAry;   #remove the first limit
            $higherLimit = "";
            foreach (@higherLimitAry) {
              $higherLimit .= "$_,";
            }
          }
          D($higherLimit);

        } elsif ($latestP < $lowerLimitAry[0] && $latestP > 0) {
          $msgStr = sprintf("DW! %s is lower than Lower Limit: $lowerLimitAry[0]\n", convToLetter(($code=~m/(s[hz]\d{6})/i)[0]) );
          P($msgStr);
          #$lowerLimit *= 0.95;
          if (scalar(@lowerLimitAry) <= 1)  {
            $lowerLimit = sprintf("%.2f", $lowerLimitAry[0] * 0.95);
          } else {
            shift @lowerLimitAry;  #remove the first limit
            $lowerLimit = "";
            foreach (@lowerLimitAry) {
              $lowerLimit .= "$_,";
            }
          }
          D("lowerLimit is: $lowerLimit");
        }

        $symbolPriceTbl{$code} = "$lowerLimit|$higherLimit|$costLimit";

        if (trim($msgStr) ne "") {
          $msgStr .= " ($latestTime)";
          showAsyncMsgBox($msgStr, $code, \%symbolPriceTbl);
        }
      }
    }#while (<hFileHandle01>)
    close(hFileHandle01);

    if ($latestTime gt $prevTime) {
      $prevTime = $latestTime;  #P("prevTime is: $prevTime");
      #$latestTime=~s/:/\//ig;
      my $tmpStr = sprintf("\nTime: %s\n%s\n", $latestTime, '-' x 80);
      P($tmpStr);

      $notifyStr .= $tmpStr;
      LOG_FILE("./priceresult.txt", $FALSE, $notifyStr) if (not isEmptyStr($notifyStr));

    } else {
      P("No more new data ---");
      $noDataTimes++;
      last if ($noDataTimes >= 3) ;
    }

    if (scalar(keys %symbolPriceTbl) <=0) {
      last;
    } else {
      sleep($SLEEP_TIME);
      $notifyStr = "";
    }
  }#while (1)

  P("Bye!!--");
  $downloadFName = "./PriceResult.txt";

}

my $notifCnt = 0;
sub showAsyncMsgBox {
  my ($msgStr, $code, $refSymbolPriceTbl) = @_;

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
      P("Deleting code: $code");
      delete $$refSymbolPriceTbl{$code};
    }
    exit 1;

  } else {
    D("THE PARENT Thread\n");
  }
}

sub Test {

}


###############################################################################
parse_args(@ARGV);

if (1) {
  InstantPriceInfo();
} else {
  Test();
}







