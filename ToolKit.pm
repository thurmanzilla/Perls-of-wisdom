package ToolKit;

require Exporter;
require AutoLoader;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use File::stat;
use Term::ANSIColor;
use Time::Local "timegm";

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
###
###  Here I am exporting a bunch of utility functions and a small set
###  of variables - standard platform vars and the basic option vars.
###
@EXPORT = qw( 
  BLine
  DirGet
  FilGet
  FilPut
  FmtCsvRow
  FmtDate
  FmtNumber
  GetInputFilName
  ListBoth
  ListComp
  ListConj
  ListDiff
  ListDDiff
  ListIn
  ListIntr
  ListMaxLen
  MkCdDir
  PadIt
  Prf
  PrnBlockHead
  PrnWarn
  SelectFromList
  SysErr
  WhatTimeIsIt
  $cdate
  $ctime
  $here
  $hostname
  $me
  $noise
  $pad
  $user
  $help
  $noexec
  $Noexec
  $quiet
  $verbose
  $Verbose
  $write
  $yes
 );

$VERSION = '0.007';

###=======================================###
###    EXPORTED Basic Variables (6)...    ###
###=======================================###

our($here,$hostname,$me,$noise,$pad,$user);
our($cdate,$ctime);

###========================================###
###    EXPORTED Option Variables (8)...    ###
###========================================###

our($help,$noexec,$Noexec,$quiet,$verbose,
    $Verbose,$write,$yes)=(0,0,0,0,0,0,0,0);

###=======================================###


###  calculate/set the basic variables...
###  cdate&ctime are in SetRunTimeVals...
($here,$user)=(`pwd`,(getpwuid($>))[0]);
($me,$pad)=($FindBin::Script,$FindBin::Bin);
$noise=1;  # default noise level
($hostname)=(`hostname`);
chomp($here,$hostname,$user);

###  important variables used widely in the ToolKit...
our($DataSpace,$MsgStrings,$NoExVerbs,$RexStrings);
our($Bar,$Lar,$Rar,$Abt,$Arw,$Dng,$DNG,$Inf,$Inv,$Err,$ERR,
    $FLD,$nfd,$Not,$NoT,$NOT,$PSD,$Run,$Use,$Wrn,$WRN,$WTF);
our($rexdate,$rexshrt,$rexsort);
our($switch)=(0);

$rexdate=qr/\d{2}\/\d{2}\/\d{4}/;
$rexshrt=qr/\d{2}\/\d{2}\/\d{2}/;
$rexsort=qr/\d{4}\/\d{2}\/\d{2}/;

$Bar=colored('<-->','ansi34');
$Lar=colored('<---','ansi34');
$Rar=colored('--->','ansi34');
$Abt=colored('Aborting...','ansi160 on_blue');
$Dng=colored('Danger:','bright_red on_black') ." ";
$DNG=colored('DANGER:','red on_black') ." ";
$Inf=colored('Inform:','green on_black');
$Inv=colored('Invalid','red on_black');
$Err=colored('Error:','bright_red on_black') ." ";
$ERR=colored('ERROR:','red on_black') ." ";
$FLD=colored('FAILED','black on_red') ." ";
$nfd=colored('not found','ansi196');
$Not=colored('Notice:','cyan on_black') ." ";
$NoT=colored('>NoTice:','black on_bright_red') ." ";
$NOT=colored('NOTICE:','magenta on_black') ." ";
$PSD=colored('PASSED','ansi21 on_white') ." ";
$Run=colored('Running:','yellow on_black') ." ";
$Use=colored('Usage:','black on_magenta') ." ";
$Wrn=colored('Warning:','bright_yellow on_black') ." ";
$WRN=colored('WARNING:','yellow on_black') ." ";
$WTF=colored('=>WTF??:','blue on_bright_yellow') ." ";


###================================================###
###        Static variables used frequently        ###
###================================================###

our(@longmonths)=qw(January February March April May June July
                    August September October November December);
our(@shortmonths)=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
our(@longdays)=qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);
our(@shortdays)=qw(Mon Tue Wed Thu Fri Sat Sun);

#print "here is initial Dataspace in ToolKit:\n";
#Prf($DataSpace);

###  define any NoEx verbs you'll spew...
###   ...then set them in SetPkgEnvrnmnt
my $xcreate;
my $xmove;
my $xrun;
my $xsend;
my $xwrite;
###+++++++++++++++++++++++++++++++++++###

# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.

###================================================###
###  ---------  Subroutine definitions  ---------  ###
###================================================###

###-------------------------------------###
###-------------------------------------###
#sub template() { }
###=====================================###


###-------------------------------------###
###  this runs a stndrd automated test...
###-------------------------------------###
sub AutoTestTool() {
  my($sound,$tool)=@_;
  my $subname=(caller(0))[3];
  my($retsub,$retarg,$retopt)=(0,0,0);
  my(@outarg,@outopt)=();
  my($acmd,$ocmd)=("$tool show args","$tool show opts");
  $sound and print "$xrun:  standard automated tests on tool --\>  $tool\n";

  &BLine();
  print "Running:  $acmd\n"; @outarg=`$acmd`; $retarg=$?;
  if ($retarg) {
    print "$Err Automated arg test $FLD!!!  return code=$retarg\n";
    $retsub=3;
   } else {
    print " ...arguments test results:  @outarg";
  }
  print "Running:  $ocmd\n"; @outopt=`$ocmd`; $retopt=$?;
  if ($retopt) {
    print "$Err Automated opt test $FLD!!!  return code=$retopt\n";
    $retsub=$retarg+2;
   } else {
    print " ...options test results:    @outopt";
  }
  return($retsub);
}
###=====================================###


###-------------------------------------###
###  this runs a custom automated test...
###-------------------------------------###
sub AutoCustTest() {
  my($sound,$tool,$ctests)=@_;
  my $subname=(caller(0))[3];
  my($retsub,$tcnt)=(0,0);
  $sound and print "$xrun:    custom automated tests on tool --\>  $tool\n";
  #$tcnt=@$ctests; print "total number of test:  $tcnt\n";
  $tcnt=1;
  for my $ctest (@$ctests) {
    $ctest or next;
    my $cprn=&PadIt($ctest,18);
    print " ...test cmd #$tcnt:  $cprn      result:";
    my(@cout)=`$ctest`; my $cret=$?;
    if ($cret) {
      print "  ..test $FLD miserably!!!  return code=$cret\n";
     } else {
      print "  ..test $PSD with flying colors!!!\n";
    }
  }
  return($retsub);
}
###=====================================###


###-------------------------------------###
###  this checks an arg vs. a valid list...
###-------------------------------------###
sub ArgCheck() {
  my($var,$val,$valids,$type)=@_;
  my $subname=(caller(0))[3];
  &VarDef($var,$val) or return 0;

  my $invarg=colored("Error - Invalid argument:",'rgb400 on_black');
  $type or $type='exact';
  if ($type eq 'exact') {
    unless (&ListIn($val,$valids)) {
      print "\n$invarg    $var = $val\n\n";
      #print "Valid arguments are:  < @$valids >\n\n"; return(0);
    }
   } elsif ($type eq 'match') {
    for my $valid (@$valids) { $val =~ /$valid/  and return(1); }
    print "\n$invarg argument match:  $var = $val\n\n";
    #print "Valid arguments are:  < @$valids >\n\n"; return 0;
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  This complains if no arg then exits...
###-------------------------------------###
sub ArgMissed() {
  my($sound,$arg)=@_;
  my $subname=(caller(0))[3];
  print "\n$Err You must enter $arg.\n\n";
  &main::Usage && exit (1);
}
###=====================================###


###-------------------------------------###
###  this does not need any explanations...
###-------------------------------------###
sub BLine() {
  my($sound,$num)=@_;
  my $subname=(caller(0))[3];
#print "Entering subroutine:  $subname\n";
  my $lf="\n";
  if (defined($sound) && defined($num)) {
    $num and $lf=$lf x $num;
    ($sound > 0) and print "$lf";
   } elsif (defined($sound)) {
    ($sound > 0) and print "$lf";
   } else {
    print "$lf";
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  this checks type for list of refs...
###-------------------------------------###
sub chkRefType() {
  my($type,@refs)=@_;
  my $subname=(caller(0))[3];
  $type or die "\n$Err checkRefType failed.  No type given.\n\n";
  @refs or return 0;
  for (@refs) {
    $_ or next;
    my $rtype=ref($_);
    $rtype or $rtype="SCALAR";
    $type =~ tr/a-z/A-Z/;
    ($rtype eq $type) or return($rtype,$type);
    ($rtype eq $type) or die "$Err $subname - $Inv ref type (should be $type):  $rtype=$_\n\n";
  }
  return(0);
}
###=====================================###


###-------------------------------------###
###  this checks a password's strength...
###-------------------------------------###
sub ChkPassword() {
  my($sound,@passes)=@_;
  my $subname=(caller(0))[3];
  my($i,$j,$k,$l,$len)=(3,5,0,0,0);
  my($f,$p)=("","");
  my($fmt)="%+20s%-18s%-22s\n";

  #######  ========================================================  #######
  #######  +++----+++  Breakdown of regular expression:  +++----+++  #######
  #######  ========================================================  #######
  #  ^                   anchor to start of string
  #  [a-zA-Z]            password must start with a letter
  #  (?=.*[a-z])         contains at least one lowercase letter (look-ahead)
  #  (?=.*[A-Z])         contains at least one uppercase letter (look-ahead)
  #  (?=.*[0-9])         contains at least one number (look-ahead)
  #  (?=.*[!@\#\$%^&*])  contains at least one special character (look-ahead)
  #  .{4,6}              length is from:  minlen = i+2  to  max = j+1 ???
  #  $                   anchor to end of string
  #
  $f=colored("Password FAILED!","ansi160 on_ansi233");
  $p=colored("Password Passed!","ansi10 on_ansi233");
  $k=$i+1; $l=$j+1;
  &BLine();
  print "Password criteria:  min length = $k  max length = $l\n";
  &BLine();
  for my $pass (@passes) {
    $len=length($pass);
    #if ($pass =~ /^[a-zA-Z](?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@\#\$%^&*]).{2,4}$/) {
    #if ($pass =~ /^[a-zA-Z](?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@\#\$%^&*]).(\$\{i\},\$\{j\})$/) {
    if ($pass =~ /^[a-zA-Z](?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@\#\$%^&*]).{3,6}$/) {
      printf($fmt,"$p  ","\'$pass\'","length = $len");
      #print "Password passed!  ",  \'$pass\'  length = $len\n";
     } else {
      printf($fmt,"$f  ","\'$pass\'","length = $len");
      #print "Password FAILED!  \'$pass\'  length = $len\n";
    }
  }
  &BLine();

  return(1);
}
###=====================================###


###-------------------------------------###
###  some are filled with apprehension...
###-------------------------------------###
sub ChkUserDoubt() {
  my($sound,$resp)=@_;
  my $subname=(caller(0))[3];

  if (@main::ARGV && $main::ARGV[0] eq 'ask') {
    if ($resp && $resp =~ /^why$/i) {
      print colored("Why the Heck Not???",'bold green on_black')."\n\n"; exit(0);
    }
   } else {
    $yes && return(0);
  }

  $yes and $resp='yes';
  my(@nmsgs) = (
    "You should always Look Before You Leap!!! ",
    "I'm really glad you thought this over...  ",
    "Lucky you - this could have been ugly...  ",
    "You outta be way more careful next time...",
    "If you break it, it's super hard to fix...",
    "No assembly required...  HAHAHAHAHAHA !!! ",
    "Batteries included...     \>\>\>  NOT!!!  \<\<\<",
    "What, you some sort of gutless chicken??? ",
    "Indecision delays your inevitable failure.",
   );
  my(@ymsgs) = (
    "Good Luck, I think you're gonna need it...",
    "Perhaps this will finally do the trick... ",
    "If you insist, just remember last time... ",
    "OK then What Could Possibly Go Wrong...???",
    "Measure 57 times, then cut 5 or 6 times...",
    "It seemed like a Good Idea at the time... ",
    "It's Close Enough for Government Work!!!  ",
    "10.9.8.7.6.5.4.3.2.1.0... IGN,  LIFTOFF!!!",
    "Get Ready, Get Set, GO GO GO GOOOOOOOOO!!!",
   );

  my $nmsgcnt=@nmsgs;
  my $nmnum=int(rand($nmsgcnt));
  my $nmsg=$nmsgs[$nmnum];
  my $ymsgcnt=@ymsgs;
  my $ymnum=int(rand($ymsgcnt));
  my $ymsg=$ymsgs[$ymnum];

  my $question=colored("Are you really sure you want to do this? [y/n]:",'yellow on_black');
  my $nocomprendo=colored(" =>  $Err Do not comprehend answer - ",'red on_black');
  print "$question ";
  my $ans;
  if ($resp) {
    if ($resp =~ /^y(es)?/i || $resp =~ /^p(os)?/i || $resp =~ /^a(ff)?/i) {
      $ans='y'; print " ...".colored("Affirmative",'cyan on_black')."\n";
     } elsif ($resp =~ /^n[o?(eg)?]/i) {
      $ans='n'; print " ...".colored("Negative",'magenta on_black')."\n";
     } else {
      &BLine($sound);
      print "$nocomprendo";
      print "$resp\n"; exit(1);
    }
   } else {
    $ans=<STDIN>; chomp $ans; $ans =~ tr/A-Z/a-z/;
  }
  if ($ans =~ /^y(es)?/i || $ans =~ /^p(os)?/i || $ans =~ /^a(ff)?/i) {
    if ($sound) {
      my $yline=colored(" =>  $ymsg",'green on_black');
      print "$yline\n\n";
    }
    return(0);
   } elsif ($ans eq "" || $ans =~ /^n[o?(eg)?]?/i) {
    if ($sound) {
      my $nline=colored(" =>  $nmsg",'red on_black');
      print "$nline\n\n";
    }
    exit(0);
   } else {
    print "$nocomprendo";
    print "$ans\n"; exit(1);
  }
  &BLine($sound); return(0);
}
###=====================================###


###-------------------------------------###
###  this gives the julian day of a year...
###-------------------------------------###
sub ColorTest() {
  my($sound,$fore,$back)=@_;
  my $subname=(caller(0))[3];
  my $str1="Test color string #1";
  my $str2="Test color string #2";
  my($colr1,$colr2)=("","");

  &BLine();
  ($colr1,$colr2)=($fore,"on_$back");
  print "Colors:  colr1 = $colr1  colr2 = $colr2\n";
  print colored($str1,"$colr1 $colr2");
  print color('reset');
  &BLine(1,2);
  print "Reversing colors...\n";
  ($colr1,$colr2)=($back,"on_$fore");
  print "Colors:  colr1 = $colr1  colr2 = $colr2\n";
  print color("$colr1 $colr2");
  print "$str2"; print color('reset'); &BLine();
  return(0);
}
###=====================================###


###-------------------------------------###
###  this gives the julian day of a year...
###-------------------------------------###
sub DayOfYear() {
  my($y,$m,$d)=@_;
  my $subname=(caller(0))[3];
  my $doy="";
  my $t1=timegm(0,0,0,$d,$m-1,$y);
  my $t2=timegm(0,0,0,1,0,$y);
  $doy=1+int(($t1-$t2)/86_400);
  #  print "day of year is:  $doy\n";
  return($doy);
}
###=====================================###


###-------------------------------------###
###  yields diff days between two dates...
###-------------------------------------###
sub DateDiff() {
  my($date1,$date2)=@_;
  my $subname=(caller(0))[3];
  if ($date1 eq '-- NONE --') { return(666); }
  unless (($date1 =~ /${rexsort}/) &&
          ($date2 =~ /${rexsort}/)) {
    print "$ERR $subname:  Must provide 2 dates as yyyy/mm/dd.\n";
    die "  Date string arguments:  date1=$date1  date2=$date2\n\n";
  }
  my($y1,$m1,$d1)=split(/\//,$date1);
  my($y2,$m2,$d2)=split(/\//,$date2);
  my $doy1=&DayOfYear($y1,$m1,$d1);
  my $doy2=&DayOfYear($y2,$m2,$d2);
  return($doy2-$doy1+(365*($y2-$y1)));
}
###=====================================###


###-------------------------------------###
###  this returns a hashref of ze dir...
###-------------------------------------###
sub DirGet() {
  my $dir=$_[0];
  my $subname=(caller(0))[3];
  ($dir) or die "$ERR $subname:  No dirname passed.\n\n";

  (-d $dir) or die "$ERR Dir not found - \'$dir\'\n\n";
  (-r $dir) or die "$ERR Dir not readable - \'$dir\'\n\n";
  (-w $dir) or print "$Wrn Dir is read-only - \'$dir\'\n\n";

  my(@sdirs,@Doors,@links,@bfils,@cfils,@pipes,@Ports,@socks,@files);

  my $lcmd="ls -al $dir";
  my(@lout)=`$lcmd`;
  my $total=0;
  for my $line (@lout) {
    chomp($line);
    my($perm,$lnks,$user,$grp,$size,$mon,$day,$yr,$entry)=split(/\s+/,$line);
    if ($perm =~ /^-/) { push @files, $entry; next; }
    if ($perm =~ /^d/) { push @sdirs, $entry; next; }
    if ($perm =~ /^l/) { push @links, $entry; next; }
    if ($perm =~ /^D/) { push @Doors, $entry; next; }
    if ($perm =~ /^b/) { push @bfils, $entry; next; }
    if ($perm =~ /^c/) { push @cfils, $entry; next; }
    if ($perm =~ /^p/) { push @pipes, $entry; next; }
    if ($perm =~ /^P/) { push @Ports, $entry; next; }
    if ($perm =~ /^s/) { push @socks, $entry; next; }
    if ($perm =~ /^total/) { $total=$lnks; next; }
  }

  #  filter out the current+parent dirs...
  @sdirs=grep { $_ !~ /^\.{1,2}$/ } @sdirs;

  my(%ddata) = (
    'total'	=>  $total,
    'sdirs'	=>  \@sdirs,
    'Doors'	=>  \@Doors,
    'links'	=>  \@links,
    'bfils'	=>  \@bfils,
    'cfils'	=>  \@cfils,
    'pipes'	=>  \@pipes,
    'Ports'	=>  \@Ports,
    'socks'	=>  \@socks,
    'files'	=>  \@files,
   );
  return (\%ddata);
}
###=====================================###


###-------------------------------------###
###  strip ze blanks from ends of strings...
###-------------------------------------###
sub DoNothing() {
  my($msg,$fore,$back)=@_;
  my $subname=(caller(0))[3];

  my $spc=colored(" ","$fore $back");
  my $string=colored("$msg","$fore $back");
  print "$spc$spc$string$spc$spc\n";

#print "main::tvar is:  $main::tvar\n";
#print "tvar is:  $tvar\n";

  return(0);
}
###=====================================###


###-------------------------------------###
###  strip ze blanks from ends of strings...
###-------------------------------------###
sub EndStrip() {
  my(@strings)=@_;
  my $subname=(caller(0))[3];
#&Prf(\@strings);
#print "using strings:  @strings\n";
  map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; } @strings;
  return (@strings);
}
###=====================================###


###-------------------------------------###
###  this returns a listref of ze file...
###-------------------------------------###
sub FilGet() {
  my($sound,$fname,$ftype,$callname)=@_;
  my $subname=(caller(0))[3];
  my $data; $ftype or $ftype="";
  if ($sound > 2) { print "$subname:  file=\'$fname\'  ftype=\'$ftype\'\n\n"; }
  unless ($fname) {
    die "$Err $subname:  No filename defined.\n\n";
  }
  unless (-f $fname) {
    print "$Err $subname:  File not found - \'$fname\'\n\n";
    return();
  }
  unless (-r $fname) {
    print "$Err $subname:  File not readable - \'$fname\'\n\n";
    return();
  }
  unless (-w $fname) {
    print "$Wrn $subname:  File is read-only - \'$fname\'\n\n";
    return();
  }
  open(FILE,"$fname") or die "$Err $subname:  Cannot open file - $fname\n\n";
  my(@file)=(<FILE>);
  close(FILE) or die "$Err $subname:  Cannot close file - $fname\n\n";
  if ($ftype) {
    if ($ftype eq 'csv') {
      $data=&ProcessFileList($sound,\@file,$ftype);
     } else {
      die "$Err $subname:  Unrecognised file type - \'$ftype\'.\n\n";
    }
  }
  return (\@file,$data);
}
###=====================================###


###-------------------------------------###
###  this writes ze file to disk ifable... 
###-------------------------------------###
sub FilPut() {
  my($sound,$fname,$flist,$perms)=@_;
  my $subname=(caller(0))[3];
  my($rtype,$type)=&chkRefType('array',$flist);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  if (-e $fname) {
    ($sound > 2) and print "$WRN File exists - $xmove to:  $fname.bak\n";
    $noexec or &SysErr("mv $fname $fname.bak");
  }
  unless (defined($flist)) {
    $sound and print "$Wrn Empty array - will create empty file...\n\n";
  }
  ($sound > 2) and print "$xwrite file:  $fname\n\n";
  unless ($noexec) {
    open(FILE,">$fname") or die "$ERR Cannot open file:  $fname\n";
    for (@$flist) { print FILE "$_"; }
    close(FILE) or die "$ERR Cannot close file:  $fname\n";
    ($perms && -f $fname) and system("chmod $perms $fname");
  }
}
###=====================================###


###-------------------------------------###
###  Format a row for a csv file...
###-------------------------------------###
sub FmtCsvRow() {
  my($sound,$cells)=@_;
  my $subname=(caller(0))[3];
  my $frow;
  my($rtype,$type)=&chkRefType('array',$cells);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my $ccnt=scalar(@$cells);
  for (@$cells) {
    $_ or $_=""; $frow.="\"$_\",";
  }
  chop $frow; $frow.="\r\n";
  return("$frow");
}
###=====================================###


###-------------------------------------###
###  Format a date in different ways...
###-------------------------------------###
sub FmtDate() {
  my($sound,$fmt,@dates)=@_;
  my $subname=(caller(0))[3];
  my($date,$mdate,@fdates);

  for (@dates) { $_ or $_=""; }
  ($sound > 4) and print "$subname:  format=$fmt  dates=@dates\n";
#print "$subname:  format=$fmt  dates=@dates\n";
  my($mon,$day,$year,$yr,$time);

  for $date (@dates) {
    for ($mon,$day,$year,$yr,$time) { $_=""; }

#print "$subname:  format=$fmt  date=\'$date\'\n";
    $mdate=$date;
    $mdate =~ s/^\s+//; $mdate =~ s/\s+$//; $mdate =~ s/\//-/g;
    unless ($mdate) { push @fdates, "-- NONE --"; next; }
    if (index($mdate,'NONE') != -1) { push @fdates, $mdate; next; }
    if (index($mdate,'VOID') != -1) { push @fdates, $mdate; next; }

    my $err=0;
    if ($mdate =~ /^\d{8}$/) {
      ($fmt =~ /cnv|parts|sort|std/) or $err=1;
     } elsif ($mdate =~ /^\d{2}-\d{2}-\d{4}$/) {
      ($fmt =~ /flip|parts|shrt|sort/) or $err=1;
     } elsif ($mdate =~ /^\d{4}-\d{2}-\d{2}$/) {
      ($fmt =~ /flip|parts|shrt|sort/) or $err=1;
     } elsif ($mdate =~ /^\d{1,4}-\d{1,2}-\d{1,4}$/) {
      ($fmt =~ /parts|shrt|sort/) or $err=1;
     } else {
      ($fmt =~ /note/) or $err=1;
    }
    if ($err) {
      print "$Err FmtDate:  Invalid format/date ->  format=$fmt  date=$mdate\n";
      exit;
      return();
    }

    if ($mdate =~ /^\d{8}$/) {
      if ($mdate =~ /^20\d{2}/) {
        $year=$&;
        $mon=substr($mdate,4,2);
        $day=substr($mdate,6,2);
       } elsif ($mdate =~ /20\d{2}$/) {
        $year=$&;
        $mon=substr($mdate,0,2);
        $day=substr($mdate,2,2);
      }
      if ($fmt eq 'cnv') {
        push @fdates, "$year/$mon/$day";
       } elsif ($fmt eq 'parts') {
        push @fdates, ($year,$mon,$day);
       } elsif ($fmt eq 'sort') {
        push @fdates, "$year$mon$day";
       } else {
      }

     ###++  -----------------------------  ++###
     } elsif ($mdate =~ /^\d{2}-\d{2}-\d{4}$/) {
      ($mon,$day,$year)=split(/-/,$mdate);
      if ($fmt =~ /flip|sort/) {
        push @fdates, "$year/$mon/$day";
       } elsif ($fmt eq 'parts') {
        push @fdates, ($year,$mon,$day);
       } elsif ($fmt eq 'shrt') {
        $yr=substr($year,2,2);
        push @fdates, "$yr/$mon/$day";
       } else {
      }

     ###++  -----------------------------  ++###
     } elsif ($mdate =~ /^\d{4}-\d{2}-\d{2}$/) {
      ($year,$mon,$day)=split(/-/,$mdate);
      if ($fmt eq 'flip') {
        push @fdates, "$mon/$day/$year";
       } elsif ($fmt eq 'parts') {
        push @fdates, ($year,$mon,$day);
       } elsif ($fmt eq 'shrt') {
        $yr=substr($year,2,2);
        push @fdates, "$yr/$mon/$day";
       } elsif ($fmt eq 'sort') {
        push @fdates, $mdate;
       } else {
      }

     ###++  -----------------------------------  ++###
     } elsif ($mdate =~ /^\d{1,4}-\d{1,2}-\d{1,4}$/) {
      my(@parts)=split(/-/,$mdate);

      if ($parts[0] =~ /\d{4}/) {
        ($year,$mon,$day)=@parts;
       } elsif ($parts[2] =~ /\d{4}/) {
        ($mon,$day,$year)=@parts;
       } else {
        if ($sound > 2) {
          print "$subname: $DNG Indeterminate date [cannot get year]:  $date\n";
        }
	### assume day-mon-yr for stupid fucking kareo claim report...
        ($day,$mon,$yr)=@parts; $year="20$yr";
      }
      length($mon) == 1 and $mon="0$mon";
      length($day) == 1 and $day="0$day";

      if ($fmt eq 'parts') {
        push @fdates, ($year,$mon,$day);
       } elsif ($fmt eq 'shrt') {
        $yr=substr($year,2,2);
        push @fdates, "$yr/$mon/$day";
       } elsif ($fmt eq 'sort') {
        push @fdates, "$year/$mon/$day";
       } else {
      }

     ###++  ------------  ++###
     } elsif ($fmt eq 'note') {
#print "formatting:  mdate = $mdate\n";
      my(@parts)=split(/\s+/,$mdate);
      &ListIn($parts[0],\@shortdays) and shift @parts;
      ($mon,$day,$time,$year)=@parts;
      $mon=&getMonthNum($sound,$mon);
      length($mon) == 1 and $mon="0$mon";
      length($day) == 1 and $day="0$day";
      push @fdates, ($mon,$day,$year,$time);

     ###>>  ++++++++++++  <<###
     } else {
      print "$Err $subname:  Invalid date ->  format=$fmt  date=$date\n";
      return();
    }

  }

  if (@fdates == 1) { return($fdates[0]); } else { return(@fdates); }

}
###=====================================###


###-------------------------------------###
###  Format a number for special purpose...
###-------------------------------------###
sub FmtNumber() {
  my($sound,$fmt,@numbers)=@_;
  my $subname=(caller(0))[3];
  ($sound > 4) and print "$subname:  format=$fmt  numbers=@numbers\n";
  for my $number (@numbers) {
    #if (!defined($number)) { print "$ERR $subname - Undefined #.\n"; next; }
    if ($number && $number !~ /^-$|\d+/) { print "$ERR $subname - $Inv #:  \'$number\'\n"; next; }
    $number or $number=0;
    map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; } ($number);
    if ($fmt eq 'cash') {
      $number eq 0 and $number="0.00";        # change blank/null/zero into 0.00
      $number eq '-' and $number="0.00";      # change a dash (null) into 0.00
      $number =~ /e-\d+/ and $number='0.00';  # change ittybitty numbers to 0.00
      $number =~ s/\$//;                      # get rid of any stupido $ symbols
      $number =~ s/,//g;                      # get rid of all the stupid commas
      $number =~ s/^(-*\d+\.\d{2})\d*/$1/;    # strips more than 2 digits after .
      $number =~ /\./ or $number.='.00';      # add 00 cents if no . found at all
      $number =~ /\.\d$/ and $number.='0';    # add 0 cents if only 1 digit after .
      $number eq '-0.00' and $number='0.00';  # change negative zero to just 0.00
      $number =~ s/^\((\d+\.\d{2})\)$/-$1/;   # change acnting parens to negative
     } elsif ($fmt eq 'integer') {
      $number=int($number+0.5);
     } elsif ($fmt eq 'percent') {
      my $perc=$number*100;
      $number=int($perc+0.5);
    }
  }
  my $cnt=@numbers;
  ($cnt == 1) and return($numbers[0]);
  return(@numbers);
}
###=====================================###


###-------------------------------------###
###  figure the month from an integer...
###-------------------------------------###
sub getMonthName() {
  my($sound,$format,$num)=@_;
  my $subname=(caller(0))[3];
  my(@months);
  if ($num !~ /^\d{1,2}$/) {
    print "$ERR getMonthName:   Invalid month number = $num\n";
    return();
  }
  my $idx=$num-1;
  if ($format eq 'long') {
    @months=@longmonths;
   } elsif ($format eq 'short') {
    @months=@shortmonths;
   } else {
    print "$ERR $Inv getMonthName format:  $format\n";
    return (0);
  }
  defined($months[$idx]) and return ($months[$idx]);
  return (0);
}
###=====================================###


###-------------------------------------###
###  get the month integer from the name...
###-------------------------------------###
sub getMonthNum() {
  my($sound,$name)=@_;
  my $subname=(caller(0))[3];
  my $idx=0;
  if ($name !~ /^[A-Za-z]+$/) {
    print "$ERR getMonthNum:   Invalid month name = \'$name\'\n";
    return();
  }
  if (length($name) > 3) { $name=substr($name,0,3); }
  for my $smon (@shortmonths) {
    $idx++;
    if ($name =~ /^$smon/) {
      length($idx) == 1 and $idx="0$idx";
      return ($idx);
    }
  }
  ($sound > 3) and print "$ERR $Inv month name:  $name\n";
  return (0);
}
###=====================================###


###-------------------------------------###
###  get the rat bastard input filenames...
###-------------------------------------###
sub GetInputFilName {
  my($sound,$count,$filname,$callname)=@_;
  my $subname=(caller(0))[3];
  my($prn,@fnames,@filnames)=(0);
  unless ($count =~ /multi|single/) {
    print "$Err $subname - Invalid #files passed from $callname:  $count\n"; exit(13);
  }
  if ($filname =~ /\*/) {
    @filnames=`ls -1 $filname 2>&1`; chomp @filnames;
    if (index($filnames[0],'No such file') != -1) {
      print "$NOT File not found:  $filname\n"; return();
    }
    if ($count eq 'single') {
      if (@filnames > 1) { @filnames=($filnames[$#filnames]); }
    }
   } else {
    @filnames=($filname);
  }
  for (@filnames) {
    if (-f $_) { push @fnames, $_; } else { print "$WRN File not found:  $_\n"; $prn++; }
  }
  $prn and &BLine($sound);
  return(@fnames);
}
###=====================================###


###-------------------------------------###
###  this returns only elements in array1 and array2
###-------------------------------------###
sub ListBoth() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to find elements in both.\n";
    return ([()],[()]);
  }
  &chkRefType('array',@arefs);
  my($array1,$array2)=@arefs;
  my %hash; grep($hash{$_}++,@$array1);
  return([grep($hash{$_},@$array2)]);
}
###=====================================###


###-------------------------------------###
###  this returns 0 if both arrays are the
###  same, or difference if they aren't...
###-------------------------------------###
sub ListComp() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to compare.\n";
    return ([()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my($array1,$array2)=@arefs;
  my($diff)=&ListDiff($array1,$array2);
  (@$diff) and return ($diff);
  ($diff)=&ListDiff($array2,$array1);
  (@$diff) and return ($diff);
  return(0);
}
###=====================================###


###-------------------------------------###
###  this combines two arrays -and/or- removes duplicates
###-------------------------------------###
sub ListConj() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to conjugate.\n";
    return ([()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my %hash; for (@arefs) { grep($hash{$_}++,@$_); }
  return([sort(keys(%hash))]);
}
###=====================================###


###-------------------------------------###
###  this returns elements in array1 NOT in array2
###-------------------------------------###
sub ListDiff() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to differ.\n";
    return ([()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my($array1,$array2)=@arefs;
  my %hash; grep($hash{$_}++,@{$array2});
  return([grep(!$hash{$_},@{$array1})]);
}
###=====================================###


###-------------------------------------###
###  this returns two separate array refs,
###  list1 diff list2 and list2 diff list1...
###-------------------------------------###
sub ListDDiff() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to ddiffer.\n";
    return ([()],[()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my($array1,$array2)=@arefs;
  my($diff1)=&ListDiff($array1,$array2);
  my($diff2)=&ListDiff($array2,$array1);
  return ($diff1,$diff2);
}
###=====================================###


###-------------------------------------###
###  this returns true if item is in a list...
###-------------------------------------###
sub ListIn() {
  my($item,$listref)=@_;
  my $subname=(caller(0))[3];
  unless (defined($item)) {
    print "$Err $subname:  No item defined to search for.\n";
    return(0);
  }
  if ($listref) {
    for (@$listref) {
      $_ or next;
      ($_ eq $item) and return(1);
    }
   } else {
    #print "$Err $subname:  No list defined to search in.\n";
    return(0);
  }
  return(0);
}
###=====================================###


###-------------------------------------###
###  this returns elements in both array1 and array2
###-------------------------------------###
sub ListIntr() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to intersect.\n";
    return ([()],[()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my($array1,$array2)=@arefs;
  my %hash;
  grep($hash{$_}++,@{$array1});
  return([grep($hash{$_},@{$array2})]);
}
###=====================================###


###-------------------------------------###
###  this returns two separate array refs,
###  list1 intr list2 and list1 conj list2...
###-------------------------------------###
sub ListIntrConj() {
  my(@arefs)=@_;
  my $subname=(caller(0))[3];
  unless (@arefs) {
    print "$Err $subname:  No list refs defined to inter/conj.\n";
    return ([()],[()]);
  }
  my($rtype,$type)=&chkRefType('array',@arefs);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my($array1,$array2)=@arefs;
  my($intr)=&ListIntr($array1,$array2);
  my($conj)=&ListConj($array1,$array2);
  return ($intr,$conj);
}
###=====================================###


###-------------------------------------###
###  this figures out the longest element...
###-------------------------------------###
sub ListMaxLen() {
  my($lref)=$_[0];
  my $subname=(caller(0))[3];
  unless ($lref) {
    print "$Err $subname:  No list ref defined to find longest element.\n";
    return (0);
  }
  my($rtype,$type)=&chkRefType('array',$lref);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  my $max=0;
  for (@$lref) {
    my $len=length($_);
    ($len > $max) and $max=$len;
  }
  return ($max);
}
###=====================================###


###-------------------------------------###
###  create some stupid directory & cd...
###-------------------------------------###
sub MkCdDir() {
  my($sound,$dir,$mode)=@_;
  my $subname=(caller(0))[3];
  unless ($dir) {
    print "$Err $subname:  No directory passed to make/cd.\n";
    return (0);
  }
  if (-d $dir) { chdir($dir); return(1); }
  my $mcmd="mkdir"; $mode and $mcmd.=" -m $mode"; $mcmd.=" -p $dir";
  if ($sound > 2) {
    print "$xcreate dir using cmd:  $mcmd\n";
   } elsif ($sound) {
    print "$xcreate dir...\n";
  }
  $noexec or &SysErr($mcmd);
  $noexec or chdir($dir);
  return(1);
}
###=====================================###


###-------------------------------------###
###  this pads a string any way you want...
###-------------------------------------###
sub PadIt() {
  my($string,$plength,$char,$side)=@_;
  my $subname=(caller(0))[3];
  ###########################################
  ### default pad character is blank...
  ### default side to pad is starboard...
  ### plength is final length of string(s)...
  ### string can be an array reference...
  ###########################################
  my(@args)=@_;
  my(@vars)=("string","plength");
  for (@vars) {
    my $a=shift(@_);
    unless (defined($a)) {
      print "$Err $subname:  Missing argument -> \$$_\n";
      return (0);
    }
  }
  my(@strings);
  defined($char) or $char=" ";
  ###  if the first arg is a list ref, use recursion...
  my $type=ref($string);
  if ($type eq 'ARRAY') {
    for my $str (@$string) {
      my $pstr=&PadIt($str,$plength,$char,$side);
      push @strings, $pstr;
    }
    return(@strings);
  }
  my $slength=length($string);
  ($slength >= $plength) and return($string);
  $side or $side="S";
  my($len,$pstring)=($slength,$string);
  until ($len == $plength) {
    if ($side eq 'S') {
      $pstring="$pstring$char";
     } elsif ($side eq 'P') {
      $pstring="$char$pstring";
    }
    $len=length($pstring);
  }
  return($pstring);
}
###=====================================###


###-------------------------------------###
###  this prints any data structure w/ indent+depth...
###-------------------------------------###
sub Prf() {
  my($href,$depth,$indent,$colorA,$colorH)=@_;
  my $subname=(caller(0))[3];
  unless ($href) {
    print "$Err Prf:  No reference defined, cannot spew.\n";
    return(0);
  }
  if ($depth && $depth !~ /^\d+/) {
    print "$Err $subname:  Invalid depth = $depth\n";
    print "    Valid arg list: (ref,depth,indent,colorA,colorH)\n";
    exit(9);
  }
  $depth or $depth=99;
  defined($indent) or $indent=0;
  $colorA or $colorA='white';
  $colorH or $colorH='white';
  defined($depth) and $depth--;
  my $reftype=ref($href);
  if ($reftype eq 'ARRAY') {
    &prfArrayStruct($href,$depth,$indent,$colorA,$colorH);
   } elsif ($reftype eq 'HASH') {
    &prfHashStruct($href,$depth,$indent,$colorA,$colorH);
   } else {
    print "$href\n";
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  this prints a data structure w/ top level array...
###-------------------------------------###
sub prfArrayStruct() {
  my($aref,$depth,$indent,$colorA,$colorH)=@_;
  my $subname=(caller(0))[3];
  $indent or $indent=0;
  my $pref=" "x$indent;
  $indent+=2;
  if (defined($depth)) {
    ($depth < 0) and return 1;
    $depth--;
  }
  my($rtype,$type)=&chkRefType('array',$aref);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  for ($colorA,$colorH) { $_ =~ /ansi/ or $_.=" on_black"; }
  for (my $i=0; $i < @$aref; $i++) {
    my $val=$aref->[$i];
    if (ref($val) eq 'ARRAY') {
      print colored("$pref [$i] ->\n","$colorA");
      &prfArrayStruct($val,$depth,$indent,$colorA,$colorH);
    } elsif (ref($val) eq 'HASH') {
      print colored("$pref [$i] =>\n","$colorH");
      &prfHashStruct($val,$depth,$indent,$colorA,$colorH);
    } else {
      if (defined($val)) {
        chomp $val;
        print colored("$pref$val\n","$colorA");
      }
    }
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  this prints a data structure w/ top level hash...
###-------------------------------------###
sub prfHashStruct() {
  my($href,$depth,$indent,$colorA,$colorH)=@_;
  my $subname=(caller(0))[3];
  $indent or $indent=0;
  my $pref=" "x$indent;
  $indent+=2;
  if (defined($depth)) {
    ($depth < 0) and return 1;
    $depth--;
  }
  my($rtype,$type)=&chkRefType('hash',$href);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  for ($colorA,$colorH) { $_ =~ /ansi/ or $_.=" on_black"; }
  for my $attr (sort(keys(%$href))) {
    my $val=$href->{$attr};
    if (ref($val) eq 'ARRAY') {
      print colored("$pref$attr ->\n","$colorA");
      &prfArrayStruct($val,$depth,$indent,$colorA,$colorH);
    } elsif (ref($val) eq 'HASH') {
      print colored("$pref$attr =>\n","$colorH");
      &prfHashStruct($val,$depth,$indent,$colorA,$colorH);
    } else {
      if (defined($val)) {
        print colored("$pref$attr == $val\n","$colorH");
      }
    }
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  this prints a list with sep lines...
###-------------------------------------###
sub PrnBlockHead() {
  my($sound,$char,$block,$color,$head)=@_;
  my $subname=(caller(0))[3];
  my($max,$list)=(1,[]);
  unless ($char) { die "$Err $subname:  No character given for separator.\n"; }
  my($rtype,$type)=&chkRefType('array',$block);
  $rtype and die "$Err $subname - $Inv ref type: $rtype  expected: $type\n\n";
  if ($head) { $max=length($block->[0]); } else { $max=&ListMaxLen($block); }
  ($max > 81) and $max=81;
  my $str="$char"x($max);
  ($color !~ /ansi/) and $color.=" on_black";
  $str=colored($str,$color);

  if ($sound) {
    print "$str\n"; &Prf($block,"","",$color); print "$str\n";
   } else {
    push @$list, "$str\n"; push @$list, $block; push @$list, "$str\n";
    return($list);
  }
  &BLine($sound);
  return(0);
}
###=====================================###


###-------------------------------------###
###  print data structure o part thereof...
###-------------------------------------###
sub PrnDataStruct() {
  my($sound,$args,$gdata)=@_;
  my $subname=(caller(0))[3];
  if (@$args) {
    if ($args->[0] eq 'ALL') { &Prf($gdata,,,"",'cyan','magenta'); exit; }
    print colored("===>  Global data structure top level:\n", 'green on_black');
    &Prf($gdata,1,,"",'cyan','magenta');
    &BLine($sound);
    my $argv;
    my($depth,$level)=(0,0);
    my $refer=shift(@ARGV);
    my $struct=$refer;
    $refer=$gdata->{$refer};
    while (@$args) {
      $argv=shift(@$args);
      if ($argv =~ /^=\d{1}$/) {
        $level=$argv; $level =~ s/^=//;
       } else {
        my $reftype=ref($refer);
        if ($reftype ne 'HASH') {
          print "$Err HRef Not Defined:  $struct->$argv\n";;
          return();
        }
        $refer=$refer->{$argv};
        $struct.="->$argv";
      }
    }
    print colored("===> substructure:  $struct\n", 'green on_black');
    &Prf($refer,$level,"",'cyan','bright_blue');
    &BLine($sound);
  }
  return();
}
###=====================================###


###-------------------------------------###
###  this prints current run-time vars...
###-------------------------------------###
sub PrnRunTimeVals() {
  my($sound)=@_;
  my $subname=(caller(0))[3];
  &BLine($sound);
  print "Initial run-time variables:\n";
  print "  cdate     = $cdate\n";
  print "  ctime     = $ctime\n";
  print "  here      = $here\n";
  print "  hostname  = $hostname\n";
  print "  me        = $me\n";
  print "  noise     = $noise\n";
  print "  pad       = $pad\n";
  print "  user      = $user\n";
  BLine;
  print "Current option variables:\n";
  print "  help      = $help\n";
  print "  noexec    = $noexec\n";
  print "  Noexec    = $Noexec\n";
  print "  quiet     = $quiet\n";
  print "  verbose   = $verbose\n";
  print "  Verbose   = $Verbose\n";
  print "  write     = $write\n";
  print "  yes       = $yes\n";
  &BLine($sound);
  return(1);
}
###=====================================###


###-------------------------------------###
###  this prints a serious warning msg...
###-------------------------------------###
sub PrnWarn {
  my $subname=(caller(0))[3];

  my $bfore="black";
  my $yback="on_yellow";
  my $back="on_ansi236";
  my $fore="ansi6";

  my $spc=colored(" ","$fore $back");
  my $spcl=colored(" ","underline $bfore $yback");
  my $dsh=colored("-","$bfore $yback");
  my $eql=colored("=","$bfore $yback");
  my $lbs=colored("#","$bfore $yback");
  my $wrn=colored("W a r n i n g !!!","$fore $back");

  my $warn="$spc$spc$wrn$spc$spc"x3;
  my $sep1="$lbs"x7 ."$dsh"x63 ."$lbs"x7;
  my $sep2="$lbs"x7 ."$eql"x63 ."$lbs"x7;
  my $line="$lbs"x7 ."$warn" ."$lbs"x7;
  print "$sep2\n";
  print "$line\n";
  print "$sep2\n";

  return(0);
}
###=====================================###


###-------------------------------------###
###  this only handles csv files so far...
###-------------------------------------###
sub ProcessFileList() {
  my($sound,$flist,$ftype)=@_;
  my $subname=(caller(0))[3];
  my($chk,$rchk,$wchk,$row)=(0,0,0,0);
  my($char,$nrow)=("","");
  my($data,$ncells)=({},[]);
  unless ($flist) {
    die "$Err $subname:  No file reference defined.\n";
  }
  unless ($ftype) {
    die "$Err $subname:  No file type defined.\n";
  }

  if ($ftype eq 'csv') {

    ####################################################
    ###  THIS ONLY HANDLES MULTIROW FIELDS IN FILES  ###
    ###   WITH WINDOWS STYLE [ \r\n ] LINE ENDS!!!   ###
    ####################################################
    ### first find out if file has \r\n windows-style line ends...
    $wchk=grep(/\r\n$/,@$flist);
    for my $fline (@$flist) {
      (index($fline,'#') == 0) and next;  # skip comment lines...
      ($sound > 4) and print "started row $row:  $fline\n";
      ### disassemble row, change commas in fields to XXX...
      ($rchk == 0) and ($chk,$nrow,$ncells)=(0,"",[]);
      for $char (split //, $fline) {
        if ($char eq '"') {
          ### flip the switchage to off or on...
          if ($chk) { $chk=0; } else { $chk=1; }
          $nrow.=$char; next;
         } elsif ($char eq ',') {
          if ($chk) { $nrow.=" XXX "; next; } else { $nrow.=$char; next; }
         } else { $nrow.=$char; next;
        }
      }
      ### replace double DOUBLE commas for the split...
      $nrow =~ s/,\s*,/,"",/g; $nrow =~ s/,\s*,/,"",/g;
      ### now look at line end for split lines...
      ### ...and strip line end off completely...
      if ($wchk) {
        if ($nrow =~ /[^\r]\n$/) {
          $nrow =~ s/\n$/ /; $rchk++; next;
         } elsif ($nrow =~ /\r\n$/) {
          $nrow =~ s/\r\n$//; $rchk=0;
        }
       } else {
        $nrow =~ s/\n$//;
      }
      ### fix ends & blank cells from space...
      $nrow =~ s/,$/,""/; $nrow =~ s/"\s+"/""/;
      @$ncells=split(/,/,$nrow);
      ($sound > 4) and print "rebuilt row $row:  $nrow\n";
      for my $ncell (@$ncells) {
        $ncell =~ s/ XXX /,/g;       # restore commas in cell...
        $ncell =~ s/^"//;            # remove leading dbl quote...
        $ncell =~ s/"$//;            # remove trailing dbl quote...
      }
      $nrow='"'.join('","',@$ncells).'"';       # reassemble row from cells...
      $data->{'rawrow'}->{$row}="$nrow\n";
      $data->{'string'}->{$row}="@$ncells";
      $data->{'fields'}->{$row}=$ncells;
      $row++; ($sound > 4) and print "final  row# $row:  $nrow\n\n";
    }

   } else {
    die "$Wrn $subname:  Unrecognised file type:  $ftype\n";

  }

  #&Prf($data);
  return($data);
}
###=====================================###


###########################################
###  Select from list with ze user input...
###########################################
sub SelectFromList() {
  my($sound,$item,$flist)=@_;
  my $subname=(caller(0))[3];
  my($select);

  unless (@$flist) {
    print "SelectFromList  --->  Empty list - cannot select.\n\n"; return();
  }

  my $head="Found these $item in list:";
  my $mrkr="="x length($head);

  print colored(" $mrkr\n",'cyan on_black');
  print colored(" $head\n",'cyan on_black');
  print colored(" $mrkr\n",'cyan on_black');
  my $cnt=0;
  for my $i (0..$#$flist) {
    $cnt++; my $ccnt=colored("$cnt",'green on_black');
    printf("%+16s%-32s\n",$ccnt,"  $flist->[$i]");
  }
  print colored("\nPlease enter your selection: ",'green on_black');
  my $size=scalar(@$flist);
  my $range="1 - $size";
  $range=colored($range,'green on_black');

  my $choice=<STDIN>; chomp $choice; &BLine($sound);
  if ($choice eq "" && $size == 1) {
    $select=$flist->[0];
   } elsif ($choice =~ /^\d+$/) {
    if ($choice == 0 || $choice > @$flist) {
      print "$ERR Selection outside of range:  $range\n\n";
      return("");
     } else {
      $select=$flist->[$choice-1];
    }
   } else {
    print "$ERR Must enter number from:  $range\n\n";
    return("");
  }

  return($select);
}
###=====================================###
###  END END END super select subroutine...
###=====================================###


###-------------------------------------###
###  This defines the complete set of 
###  verbs based on value of noexec...
###-------------------------------------###
sub setNoExVerbs {
  my $subname=(caller(0))[3];
  my %NoExVerbs;
  if ($noexec) {
    %NoExVerbs = (
      'add'		=>  "Would add",
      'apply'		=>  "Would apply",
      'approve'		=>  "Would approve",
      'blast'		=>  "Would blast",
      'bomb'		=>  "Would bomb",
      'build'		=>  "Would build",
      'change'		=>  "Would change",
      'check'		=>  "Would check",
      'clean'		=>  "Would clean",
      'close'		=>  "Would close",
      'commit'		=>  "Would commit",
      'combine'		=>  "Would combine",
      'compare'		=>  "Would compare",
      'copy'		=>  "Would copy",
      'count'		=>  "Would count",
      'create'		=>  "Would create",
      'delete'		=>  "Would delete",
      'diff'		=>  "Would diff",
      'disable'		=>  "Would disable",
      'dist'		=>  "Would distribute",
      'erase'		=>  "Would erase",
      'exclude'		=>  "Would exclude",
      'exec'		=>  "Would execute",
      'find'		=>  "Would find",
      'finstall'	=>  "Would force install",
      'fix'		=>  "Would fix",
      'force'		=>  "Would force",
      'generate'	=>  "Would generate",
      'ogenerate'	=>  "Would over-generate",
      'rgenerate'	=>  "Would re-generate",
      'get'		=>  "Would get",
      'hijack'		=>  "Would hijack",
      'ignore'		=>  "Would ignore",
      'init'		=>  "Would initialize",
      'install'		=>  "Would install",
      'is'		=>  "would be",
      'kill'		=>  "Would kill",
      'launch'		=>  "Would launch",
      'link'		=>  "Would link",
      'hlink'		=>  "Would hard link",
      'rlink'		=>  "Would re-link",
      'slink'		=>  "Would soft link",
      'load'		=>  "Would load",
      'log'		=>  "Would log",
      'map'		=>  "Would map",
      'merge'		=>  "Would merge",
      'modify'		=>  "Would modify",
      'move'		=>  "Would move",
      'open'		=>  "Would open",
      'perm'		=>  "Would permission",
      'process'		=>  "Would process",
      'publish'		=>  "Would publish",
      'pull'		=>  "Would pull",
      'push'		=>  "Would push",
      'record'		=>  "Would record",
      'reformat'	=>  "Would reformat",
      'remove'		=>  "Would remove",
      'rename'		=>  "Would rename",
      'renumber'	=>  "Would renumber",
      'repair'		=>  "Would repair",
      'replace'		=>  "Would replace",
      'reset'		=>  "Would reset",
      'resort'		=>  "Would resort",
      'revert'		=>  "Would revert",
      'rinstall'	=>  "Would re-install",
      'rsync'		=>  "Would rsync",
      'run'		=>  "Would run",
      'search'		=>  "Would search",
      'send'		=>  "Would send",
      'setup'		=>  "Would setup",
      'show'		=>  "Would show",
      'start'		=>  "Would start",
      'stop'		=>  "Would stop",
      'strip'		=>  "Would strip",
      'switch'		=>  "Would switch",
      'ftag'		=>  "Would force tag",
      'ntag'		=>  "Would newly tag",
      'tag'		=>  "Would tag",
      'test'		=>  "Would test",
      'trample'		=>  "Would trample",
      'trash'		=>  "Would trash",
      'unpack'		=>  "Would unpack",
      'update'		=>  "Would update",
      'use'		=>  "Would use",
      'wipe'		=>  "Would wipe",
      'write'		=>  "Would write",
     );
   } else {
    %NoExVerbs = (
      'add'		=>  "Adding",
      'apply'		=>  "Applying",
      'approve'		=>  "Approving",
      'blast'		=>  "Blasting",
      'bomb'		=>  "Bombing",
      'build'		=>  "Building",
      'change'		=>  "Changing",
      'check'		=>  "Checking",
      'clean'		=>  "Cleaning",
      'close'		=>  "Closing",
      'combine'		=>  "Combining",
      'commit'		=>  "Committing",
      'compare'		=>  "Comparing",
      'copy'		=>  "Copying",
      'count'		=>  "Counting",
      'create'		=>  "Creating",
      'delete'		=>  "Deleting",
      'diff'		=>  "Diffing",
      'disable'		=>  "Disabling",
      'dist'		=>  "Distributing",
      'erase'		=>  "Erasing",
      'exclude'		=>  "Excluding",
      'exec'		=>  "Executing",
      'find'		=>  "Finding",
      'finstall'	=>  "Force installing",
      'fix'		=>  "Fixing",
      'force'		=>  "Forcing",
      'generate'	=>  "Generating",
      'ogenerate'	=>  "Over-generating",
      'rgenerate'	=>  "Re-generating",
      'get'		=>  "Getting",
      'hijack'		=>  "Hijacking",
      'ignore'		=>  "Ignoring",
      'init'		=>  "Initializing",
      'install'		=>  "Installing",
      'is'		=>  "is",
      'kill'		=>  "Killing",
      'launch'		=>  "Launching",
      'link'		=>  "Linking",
      'hlink'		=>  "Hard linking",
      'rlink'		=>  "Re-linking",
      'slink'		=>  "Soft linking",
      'load'		=>  "Loading",
      'log'		=>  "Logging",
      'map'		=>  "Mapping",
      'merge'		=>  "Merging",
      'modify'		=>  "Modifying",
      'move'		=>  "Moving",
      'open'		=>  "Opening",
      'perm'		=>  "Permissioning",
      'process'		=>  "Processing",
      'publish'		=>  "Publishing",
      'pull'		=>  "Pulling",
      'push'		=>  "Pushing",
      'record'		=>  "Recording",
      'reformat'	=>  "Reformatting",
      'remove'		=>  "Removing",
      'rename'		=>  "Renaming",
      'renumber'	=>  "Renumbering",
      'repair'		=>  "Repairing",
      'replace'		=>  "Replacing",
      'reset'		=>  "Resetting",
      'resort'		=>  "Resorting",
      'revert'		=>  "Reverting",
      'rinstall'	=>  "Re-installing",
      'rsync'		=>  "Rsyncing",
      'run'		=>  "Running",
      'search'		=>  "Searching",
      'send'		=>  "Sending",
      'setup'		=>  "Setting up",
      'show'		=>  "Showing",
      'start'		=>  "Starting",
      'stop'		=>  "Stopping",
      'strip'		=>  "Stripping",
      'switch'		=>  "Switching",
      'ftag'		=>  "Force tagging",
      'ntag'		=>  "Newly tagging",
      'tag'		=>  "Tagging",
      'test'		=>  "Testing",
      'trample'		=>  "Trampling",
      'trash'		=>  "Trashing",
      'unpack'		=>  "Unpacking",
      'update'		=>  "Updating",
      'use'		=>  "Using",
      'wipe'		=>  "Wiping",
      'write'		=>  "Writing",
     );
  }
  return(\%NoExVerbs);
}
###=====================================###
###    <---  end-of-subroutine  --->    ###
###            setNoExVerbs             ###
###=====================================###


###-------------------------------------###
###  this sets noexec if Noexec is set...
###-------------------------------------###
sub setNoexecFlag {
  my $subname=(caller(0))[3];
  $Noexec and $noexec=1;
  return($noexec);
}
###=====================================###


###-------------------------------------###
###  this sets global out noise level...
###-------------------------------------###
sub setNoiseLevel {
  my $subname=(caller(0))[3];
  $quiet    and $noise=0;
  $verbose  and $noise=2;
  $Verbose  and $noise=$Verbose;
  return($noise);
}
###=====================================###


###-------------------------------------###
###  this sets the common pkg env vars...
###-------------------------------------###
sub SetPkgEnvrnmnt {
  my $subname=(caller(0))[3];
  ###  set any NoEx verbs you'll spew...
  $xcreate     =  $NoExVerbs->{'create'};
  $xmove       =  $NoExVerbs->{'move'};
  $xrun        =  $NoExVerbs->{'run'};
  $xsend       =  $NoExVerbs->{'send'};
  $xwrite      =  $NoExVerbs->{'write'};
  ###+++++++++++++++++++++++++++++++++++###
}
###=====================================###


###-------------------------------------###
###  this sets run-time vars w/ options...
###-------------------------------------###
sub SetRunTimeVals {
  my $subname=(caller(0))[3];

  &setNoiseLevel;
  &setNoexecFlag;
  $NoExVerbs=&setNoExVerbs;
  $DataSpace->{'NoExVerbs'}=$NoExVerbs;

  my($t1,$t2,$t3,$d1,$d2,$d3,$d4,$d5)=&WhatTimeIsIt($noise,'bundle');
  $DataSpace->{'TimeSpace'}->{'Times'}->{'ctime'}=$t1;
  $DataSpace->{'TimeSpace'}->{'Times'}->{'miltime'}=$t1;
  $DataSpace->{'TimeSpace'}->{'Times'}->{'cvltime'}=$t2;
  $DataSpace->{'TimeSpace'}->{'Times'}->{'sectime'}=$t3;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'stddate'}=$d1;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'cdate'}=$d3;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'stdshrt'}=$d2;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'srtdate'}=$d3;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'mildate'}=$d4;
  $DataSpace->{'TimeSpace'}->{'Dates'}->{'cvldate'}=$d5;
  ($cdate,$ctime)=($d3,$t1);

  $MsgStrings=[($Bar,$Lar,$Rar,$Dng,$DNG,$Inf,$Inv,$Err,$ERR,$FLD,
               $nfd,$Not,$NoT,$NOT,$PSD,$Run,$Use,$Wrn,$WRN,$WTF)];
  $DataSpace->{'Messages'}=$MsgStrings;
  $RexStrings=[($rexdate,$rexshrt,$rexsort)];
  $DataSpace->{'RegExprs'}=$RexStrings;
  #&PrnRunTimeVals;
}
###=====================================###


###-------------------------------------###
###  show me the money!!! show me state..?
###-------------------------------------###
sub ShowMeTheMoney() {
  my($sound,$options,$argues,$argv)=@_;
  my $subname=(caller(0))[3];

  my($showme,$showit,$showup)=@$argv;
  my($self,$mname,$sname,$target,$vname)=([],"","","","");
  my($clr1,$clr2)=("","");
  my($cmd,$len,$line,$msg)=("",0,"","");
  my($fcnt,$lcnt,$scnt)=(0,0,0);

  my $showargs="INC \| mods \| msgs \| args \| opts \| vars \| subs \| string";

  if (!$showme) {
    print "$Err I cannot show you emptiness!\n";
    print color('ansi83');
    print " ...what do you want me to show you?\n\n";
    &ShowMeTheUsage($sound,$showargs);
  }


  ###++------------------------------------++###
  ###  main select structure begins here...  ###
  ###++------------------------------------++###

  #######  ====  +++  ====  #######
  if ($showme eq 'args') {
    my(@args)=sort(keys(%$argues));
    if ($sound) {
      print "Valid arguments defined for:  $me\n";
      map { print "  $_ = ( @{$argues->{$_}} )\n"; } @args;
     } else {
      map { print "@{$argues->{$_}} "; } @args;
    }
    &BLine($sound);


   #######  ====  +++  ====  #######
   } elsif ($showme eq 'INC') {
    $msg='===  Perl Lib @INC search path  ==='; $len=length($msg);
    print color('ansi83');
    print "="x$len ."\n"; print "$msg\n"; print "="x$len ."\n"; &BLine();
    for (@INC) { print "$_\n"; }
    &BLine(); print "="x$len ."\n";
    print color('reset');


   #######  ====  +++  ====  #######
   } elsif ($showme eq 'mods') {
    my($mod,$mods,$smods,$imods)=("",[],[],{});
    $cmd="grep";  $noexec and $cmd.=" -n";
    $cmd.=" '^use ' $pad/$me";
    $showup and print "$Not Extra argument ignored:  $showup\n\n";
    if (!$showit) {
      $msg="===  Perl Modules used in $me  ==="; $len=length($msg);
      print color('ansi83');
      print "="x$len ."\n"; print "$msg\n"; print "="x$len ."\n"; &BLine();
      #&SysErr($cmd);
      $mods=[(`$cmd`)]; print " @$mods\n";
      print "\n"."="x$len ."\n";
      print " Total #mods found in $me =  $#{$mods}";
      print "\n"."="x$len ."\n";
      print color('reset');
     } else {
      ###  get the module names used in this script...
      $mods=[(`$cmd`)];
      for (@$mods) {
        $_ =~ /strict|warn|lib "/ and next;
        $_ =~ s/^\d+:use //;
        $_ =~ s/;\n$//;
        $_ =~ s/ .*$//;
        ($mname,$sname)=split(/::/, $_); $sname or $sname="";
        $imods->{$mname}=$sname;
      }
      @$mods=sort(keys(%$imods));
      @$smods=grep(/$showit/i, @$mods);
      for $mod (@$smods) {
        for (@INC) {
          -f "$_/*$mod*" and print "$_/*$mod*\n";
        }
      }

    }


   #######  ====  +++  ====  #######
   } elsif ($showme eq 'msgs') {
    $msg="===  Internal Message Strings  ===\n"; $len=length($msg);
    print color('ansi190'); 
    print "="x$len ."\n"; print color('reset'); &BLine();
    for (@{$DataSpace->{'Messages'}}) { print "$_\n"; }
    &BLine(); print color('ansi190'); print "="x$len ."\n"; 
    print color('reset');


   #######  ====  +++  ====  #######
   } elsif ($showme eq 'opts') {
    my(@opts)=sort(keys(%$options));
    if ($sound) {
      print "Valid options defined for:  $me\n";
      map { print "  $_\n"; } @opts;
      &BLine($sound);
     } else {
      print "@opts\n";
    }


   #######  ====  +++  ====  #######
   } elsif ($showme eq 'subs') {
    my($sout)=([]);
    ### showup is only sub name for complete listing...
    ### showit could be sub name -or- target (kit/git/...)
    ### if no showit target=me and no sname
    #  set target and colors depending on args...
    if (!$showit) {
      $target="$me"; ($clr1,$clr2)=('ansi21 on_ansi253','ansi226 on_ansi234');
     } else {
      if ($showit eq 'kit') { $target="ToolKit.pm"; ($clr1,$clr2)=('ansi20 on_ansi15','ansi88');
       } elsif ($showit eq 'git') { $target="GitTool.pm"; ($clr1,$clr2)=('ansi54 on_ansi33','ansi20');
       } elsif ($showit eq 'svn') { $target="SvnTool.pm"; ($clr1,$clr2)=('ansi54 on_ansi33','ansi20');
       } else {
        if ($showup) {
          print "$Err Invalid argument list:  $showme $showit $showup\n";
          &ShowMeTheUsage($sound,$showargs);
         } else {
          $sname=$showit; $target=$me; ($clr1,$clr2)=('ansi93 on_ansi233','ansi21 on_ansi123');
        }
      }
      $showup and $sname=$showup;
    }
    #  default cmd for sub names only...
    $cmd="grep";  $noexec and $cmd.=" -n";
    $cmd.=" \"^sub \" $pad/$target";
print "using:  cmd    = $cmd\n";
print "using:  target = $target\n";
print "using:  sname  = $sname\n";
print "using:  clr1   = $clr1\n";
print "using:  clr2   = $clr2\n";
    if ($sname) {
      #  list all complete sub definitions matching sname...
      ($self)=&FilGet($sound,"$pad/$target");
      ($fcnt,$lcnt,$scnt)=(0,0,0);
      my($sn)=("");
      for (@$self) {
        $fcnt++;
        if ($_ =~ /^sub (.*$sname.*) \{$/i) {    # first line of sub definition
          $line=$_; $noexec and $line="$fcnt: $_";
          push @$sout, "\n",$line; $sn=$1; $lcnt++; $scnt++; next;
        }
        if ($lcnt) {
          $line=$_; $noexec and $line="$fcnt: $_";
          push @$sout, $line; $lcnt++;
          if ($_ =~ /^\}$/) {
            $msg="subroutine $sn:  line count = $lcnt"; $len=length($msg);
            push @$sout, "\n";
            push @$sout, "-"x$len ."\n"; push @$sout, $msg ."\n"; push @$sout, "-"x$len ."\n";
            $lcnt=0;
          }
        }
      }
      if ($scnt) {
        my $sun="subroutine"; ($scnt > 1) and $sun.="s";
        $msg="-->  $scnt $sun found with name containing \'$sname\':";
       } else {
        $msg="-->  Zero subroutines found with name containing \'$sname\'.";
      }
      my $msg0="-->  Searching $target for subroutines...\n";
      $len=length($msg);
      print color($clr1); &BLine();
      print "="x$len ."\n"; print "$msg0$msg\n"; print "="x$len;

      if ($scnt) {
        print color($clr2); &BLine();
        @$sout and print @$sout;
        print color($clr1);
        &BLine(); print "="x$len ."\n";
        $msg=" end of function definitions w/ name matching \'$sname\'";
        print "$msg\n"; print "="x$len;
       } else {
        print color('reset'); &BLine();
      }
     } else {
      $msg="###  Subroutines found in $target:  ###"; $len=length($msg);
      print color($clr1); &BLine();
      print "="x$len ."\n"; print "$msg\n"; print "="x$len;
      print color($clr2); &BLine(1,2);
      @$sout=`$cmd`; print " @$sout";
      print color($clr1); &BLine(); print "="x$len; &BLine();
      print " Total #subs =  $#{$sout}";
      &BLine(); print "="x$len;
      #system($cmd); print color($clr1); &BLine(); print "="x$len;
    }
    print color('reset'); &BLine();


   #######  ====  +++  ====  #######
   } elsif ($showme =~ /string/i) {
    $showit or die "$Err Show argument \'string\' requires additional argument.\n";
    if ($showup) {
      if ($showit eq 'all') {
        $cmd="grep -in $showup $pad/*";
        my $smsg=" ---> Searching ToolKit launchpad for string:    $showup\n";
        &PrnBlockHead($sound,'#',[($smsg)]);
        system($cmd);
        &BLine($sound); exit(0);
       } elsif ($showit eq 'kit') {
        $cmd="grep -in \"$showup\" $pad/ToolKit.pm";
        print colored("###------------------------------------###",'green on_black') ."\n";
        print colored("###  String \'$showup\' found in ToolKit.pm:  ###",'green on_black') ."\n";
        print colored("###------------------------------------###",'green on_black') ."\n";
        system($cmd);
        print colored("###====================================###",'green on_black') ."\n";
        &BLine($sound);
      }
     } else {
      $cmd="grep -in \"$showit\" $pad/$me";
      print colored("###------------------------------------###",'green on_black') ."\n";
      print colored("###  String \'$showit\' found in $me:",'green on_black') ."\n";
      print colored("###------------------------------------###",'green on_black') ."\n";
      system($cmd);
      print colored("###====================================###",'green on_black') ."\n";
      &BLine($sound);
    }

   #######  ====  +++  ====  #######
   } elsif ($showme eq 'vars') {
    #print color('ansi20');   # dark blue
    #print color('ansi24');   # pale blue
    #print color('ansi44');   # cyan
    #print color('ansi124');  # red
    #print color('ansi190');  # yellow
    #print color('ansi201');  # magenta
    #  set target and colors depending on args...
    if (!$showit) {
      $target="$me"; ($clr1,$clr2)=('ansi57 on_ansi255','ansi88 on_ansi252');
     } else {
      if ($showit eq 'kit') { $target="ToolKit.pm"; ($clr1,$clr2)=('ansi44 on_ansi201','ansi124');
       } elsif ($showit eq 'git') { $target="GitTool.pm"; ($clr1,$clr2)=('ansi24 on_ansi190','ansi124 on_ansi20');
       } elsif ($showit eq 'svn') { $target="SvnTool.pm"; ($clr1,$clr2)=('ansi124','ansi124');
       } else {
        if ($showup) {
          print "$Err Invalid argument list:  $showme $showit $showup\n";
          &ShowMeTheUsage($sound,$showargs);
         } else {
          $vname=$showit; ($clr1,$clr2)=('ansi54 on_ansi33','ansi124');
        }
      }
      $showup and $vname=$showup;
    }
    if ($vname) {
      $cmd="grep -n \\\$$vname $pad/$target";
      $msg="###  Variables matching \'$vname\' found in $target:  ###";
     } else {
      $msg="###  Run-Time & Option vars used by $me:  ###";
    }
print "using:  target = $target\n";
print "using:  vname  = $vname\n";
print "using:  clr1   = $clr1\n";
print "using:  clr2   = $clr2\n";
    $len=length($msg);
    print color($clr1); &BLine();
    print "="x$len ."\n"; print "$msg\n"; print "="x$len;
    print color($clr2); &BLine(1,2);
    if ($vname) { system($cmd); } else { &PrnRunTimeVals(0); }
    print color($clr1); &BLine(); print "="x$len; print color('reset'); &BLine();

   #######  ====  +++  ====  #######
   } else {
    print "$Err Cannot show \"$showme\" - unknown entity.\n\n";
    die "Valid show arguments are:\n [ $showargs ]\n\n";
  }


  exit(0);
}
###=====================================###


###-------------------------------------###
###  show me how to use all the money!!!
###-------------------------------------###
sub ShowMeTheUsage() {
  my($sound,$showargs)=@_;
  my $subname=(caller(0))[3];
  print color('ansi24');
  print "Valid show arguments are:\n< $showargs >\n\n";
  print color('ansi46');
  print "Valid show commands are:\n";
  print color('ansi148');
  print "  $me show INC                  = prints Perl Module search path dirs.\n";
  print "  $me show mods                 = prints da Perl modules used by $me.\n";
  print "  $me show msgs                 = prints internal message strings.\n";
  print "  $me show args                 = prints valid arguments for $me.\n";
  print "  $me show opts                 = prints valid options used by $me.\n";
  print "  $me show vars                 = prints runtime & option var values.\n";
  print "  $me show vars <string>        = searches $me for vars matching <string>.\n";
  print "  $me show vars kit <string>    = searches ToolKit.pm for vars matching <string>.\n";
  print "  $me show subs                 = prints subroutine names only in $me.\n";
  print "  $me show subs kit             = prints subroutine names in ToolKit.pm.\n";
  print "  $me show subs <string>        = prints entire sub matching <string> in $me.\n";
  print "  $me show subs kit <string>    = prints entire sub matching <string> in ToolKit.pm.\n";
  print "  $me show string <string>      = searches $me for all occurences of <string>.\n";
  print "  $me show string all <string>  = searches $pad/* for <string>.\n";
  print "  $me show string kit <string>  = searches ToolKit.pm for <string>.\n";
  print color('reset');
  exit(1);
}

###-------------------------------------###
###  this sprays vomit into the ether...
###-------------------------------------###
sub SpewMail() {
  my($sound,$mdata)=@_;
  my $subname=(caller(0))[3];

  my $msubj=$mdata->{'Subject'};    #  plain old regular string...
  my $mbody=$mdata->{'TxtBody'};    #  reference to list with body...
  my $tomail=$mdata->{'ToMail'};    #  space delim string of addrs...
  my $ccmail=$mdata->{'CcMail'};    #  comma delim string of addrs...
  my $mattch=$mdata->{'Attach'};    #  comma delim string of files...

  $tomail or die "$Err Cannot send mail to the Ghost In The Machine...\n";
  my(@addrs)=split(/\s+/,$tomail);
  my(@taddrs,$taddrs);
  for my $addr (@addrs) {
    $addr or next;
    $addr =~ /\@/ or $addr.="\@bloomberg.net";
    $taddrs.=" $addr";
    push @taddrs, $addr;
  }
  $taddrs =~ s/^ //;

  my(@body);
  $msubj ||= "Auto-email from:  $me";
  push(@body,"Subject:  $msubj\n");
  for my $taddr (@taddrs) {
    push(@body,"To:       $taddr\n");
  }
  push(@body,"From:     $user\n");
  push(@body,"\n");
  @$mbody and push @body, @$mbody;

  #my($tool)=(-x '/usr/lib/sendmail' ? '/usr/lib/sendmail' : 'sendmail');
  #my($tool)="/bb/bin/sendmsg.tsk";
  my($tool)="/bb/shared/bin/xmail";

  print "$xsend the following email:\n";
  &PrnBlockHead($sound,"-",\@body,'head');

  my $mcmd="$tool ";
  $ccmail and $mcmd.=" -c $ccmail";
  $mattch and $mcmd.=" -a $mattch";
  $mcmd.=" -s \"$msubj\"";
  $mcmd.=" $tomail";

  if ($sound > 2) {
    print "$xsend email using cmd:  $mcmd\n";
   } elsif ($sound) {
    print "$xsend email...\n";
  }

  unless ($noexec) {
    if (open(MCMD,"| $mcmd")) {
      print MCMD @body;
      close MCMD;
      $sound and print "$me:  Sent mail to - $tomail\n";
    }
  }
  return(0);
}
###=====================================###


###-------------------------------------###
###  Split a line from the csv file...
###-------------------------------------###
sub SplitCsvRow() {
  my($srow)=$_[0];
  my $subname=(caller(0))[3];

  my($chk,$nrow)=(0,"");
  for my $char (split //, $srow) {
    if ($char eq '"') {
      # flip the switch...
      if ($chk) { $chk=0; } else { $chk=1; }
      $nrow.=$char; next;
     } elsif ($char eq ',') {
      if ($chk) {
        #replace stupid comma in cell...
        $nrow.=" XXX "; next;
       } else {
        $nrow.=$char; next;
      }
     } else {
      $nrow.=$char; next;
    }
  }

  ### replace double commas for the split...
  $nrow =~ s/,,/,"",/g;
  $nrow =~ s/, ,/,\"\",/g;
  ### DOUBLE VISION....
  $nrow =~ s/,,/,"",/g;
  $nrow =~ s/, ,/,\"\",/g;
  ### just one more at the end...
  $nrow =~ s/,$/,""/;
  ### fix blank cells from outer space...
  $nrow =~ s/\" \"/\"\"/;

  ### now split to get the cell values...
  my(@ncells)=split(/,/,$nrow);
  $nrow =~ s/ XXX /,/g;        # restore commas in complete row...
  for my $ncell (@ncells) {
    $ncell =~ s/ XXX /,/g;        # restore commas in cell...
  }

  return($nrow,\@ncells);
}
###=====================================###


###-------------------------------------###
###  this checks a system call return val...
###-------------------------------------###
sub SysErr() {
  my $cmd=$_[0];
  my $subname=(caller(0))[3];
  unless ($cmd) {
    die "$Err SysErr:  System call with empty command!\n\n";
  }
  my $ret=system($cmd);
  $ret or return(0);
  my $syserr="$ERR System call returned error: ";
  my $val = $ret >> 8;
  $val and die "$syserr $val\n  cmd:  $cmd\n\n";
  die "$syserr $ret\n  cmd:  $cmd\n\n";
}
###=====================================###


###-------------------------------------###
###  this prints var name if undefined...
###-------------------------------------###
sub VarDef() {
  my($var,$val)=@_;
  my $subname=(caller(0))[3];
  unless ($val) {
    print "\n$Err Variable not defined:  $var\n\n";
    return(0);
  }
  return(1);
}
###=====================================###


###-------------------------------------###
###  get the time in many different ways...
###-------------------------------------###
sub WhatTimeIsIt() {
  my($sound,$format)=@_;
  my $subname=(caller(0))[3];
  my $tstring;
  my($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=localtime(time());
  $mon++;
  my $month=&getMonthName($sound,'short',$mon);
  my $longmonth=&getMonthName($sound,'long',$mon);
  my $fullyear=$year+1900; $year=substr($fullyear,2,2);
  my $chour=$hour; $chour > 12 and $chour=$hour-12;
  my(@ints)=($sec,$min,$hour,$chour,$day,$mon);
  ($sec,$min,$hour,$chour,$day,$mon)=&PadIt(\@ints,2,"0",'P');

  if ($format eq 'build') {
    $tstring="$month $day $hour:$min";              # build       Jun 06 09:11
   } elsif ($format eq 'cvshist') {
    $tstring="$fullyear-$mon-$day $hour:$min";      # cvshist     1944-06-06 09:11
   } elsif ($format eq 'irdrobo') {
    $tstring="$month$day";                          # irdrobo     Apr20
   } elsif ($format eq 'monmin') {
    $tstring="$mon$day$hour$min";                   # monmin      09110911
   } elsif ($format eq 'monsec') {
    $tstring="$mon$day$hour$min$sec";               # monsec      0911091111
   } elsif ($format eq 'numday') {
    $tstring="$year$mon$day";                       # numday      440606
   } elsif ($format eq 'numtime') {
    $tstring="$hour$min";                           # numtime     0911
   } elsif ($format eq 'numsec') {
    $tstring="$hour$min$sec";                       # numsec      091111
   } elsif ($format eq 'log') {
    $tstring="$year$mon$day $hour:$min";            # log         440606 09:11
   } elsif ($format eq 'milstd') {
    $tstring="$day $month $fullyear";               # milstd      06 Jun 1944
   } elsif ($format eq 'milshort') {
    $tstring="$day $month $year $hour:$min";        # milshort    06 Jun 44 09:11
   } elsif ($format eq 'millong') {
    $tstring="$day $month $fullyear $hour:$min";    # millong     06 Jun 1944 09:11
   } elsif ($format eq 'miltime') {
    $tstring="$hour:$min";                          # miltime     16:20
   } elsif ($format eq 'second') {
    $tstring="$year$mon$day$hour$min$sec";          # second      440606091111
   } elsif ($format eq 'slashshrt') {
    $tstring="$mon/$day/$year";                     # slashshrt   09/11/01
   } elsif ($format eq 'slashlong') {
    $tstring="$mon/$day/$fullyear";                 # slashlong   09/11/2001
   } elsif ($format eq 'slashtime') {
    $tstring="$mon/$day/$year $hour:$min";          # slashtime   09/11/01 09:11
   } elsif ($format eq 'slashfull') {
    $tstring="$mon/$day/$fullyear $hour:$min";      # slashfull   09/11/2001 09:11
   } elsif ($format eq 'slashsort') {
    $tstring="$fullyear/$mon/$day";                 # slashsort   2001/09/11
   } elsif ($format eq 'slashbarf') {
    $tstring="$fullyear/$mon/$day $hour:$min";      # slashbarf   2001/09/11 09:11
   } elsif ($format eq 'sortshort') {
    $tstring="$year $mon$day $hour:$min";           # sortshort   44 0606 09:11
   } elsif ($format eq 'stddate') {
    $tstring="$longmonth $day, $fullyear";          # stddate     June 06, 1944
   } elsif ($format eq 'stdlong') {
    $tstring="$month $day $fullyear $hour:$min";    # stdlong     Jun 06 1944 09:11
   } elsif ($format eq 'stdshrt') {
    $tstring="$month $day $year";                   # stdshrt     Jun 06 1944
   } elsif ($format eq 'cvltime') {
    $tstring="$chour:$min";                         # cvltime     04:20 [pm]

   } elsif ($format eq 'bundle') {
    my $t1="$hour:$min";                            # miltime     16:20
    my $t2="$chour:$min";                           # cvltime     04:20 [pm]
    my $t3="$hour:$min:$sec";                       # sectime     16:20:09
    my $d1="$mon/$day/$fullyear";                   # slashlong   09/11/2001
    my $d2="$mon/$day/$year";                       # slashshrt   09/11/01
    my $d3="$fullyear/$mon/$day";                   # slashsort   2001/09/11
    my $d4="$day $month $fullyear";                 # milstd      06 Jun 1944
    my $d5="$month $day $year";                     # stdshrt     Jun 06 1944
    return ($t1,$t2,$t3,$d1,$d2,$d3,$d4,$d5);

   } else {
    print "$Err $Inv format for WhatTimeIsIt:  $format\n"; return();
  }

  return ($tstring);
}
###=====================================###


###================================================###
###  -------  End Subroutine definitions  -------  ###
###================================================###


###================================================###
###++++++++++++------------------------++++++++++++###
###========    END ToolKit package code    ========###
###++++++++++++------------------------++++++++++++###
###================================================###

1;
__END__


###  Below is the documentation for this module.  DO NOT READ!!!

=head1 NAME

ToolKit - Perl extension for general utility thingamajigeez

=head1 SYNOPSIS

  use ToolKit;

=head1 DESCRIPTION

This module provides mucho generally useful utility type functions...

The really different thing about this module is that it most deliberately 
breaks (according to some folks) a cardinal rule about variable declaration 
and scoping.  Specifically, this module will EXPORT a set of functions and 
variables to the calling script's symbol table. 

I wanted to do this so that I had the same standard variables avaiable in 
both this module and the calling script that I could reference in exactly 
the same way every time.  These standard variables consist of the mostly 
standard platform/location/launch variables and the basic option variables.
The exported functions are a grab bag of common activities...


=head1 AUTHOR

Jack London

=head1 SEE ALSO

perl(1).

=cut
