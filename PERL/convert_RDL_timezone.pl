#!/usr/bin/perl -w
use Getopt::Std;
use File::Basename;
use File::Spec;
use strict;
use Time::Local;

# Will jump here on help request.
sub HELP_MESSAGE
{
    my ($fh) = @_;
    $fh ||= \*STDOUT;
    print $fh <<'EOH';
######################################################################
 This script converts the timezone on RDL files.  

 Usage: convert_RDL_timezone.pl [OPTIONS] <DIRNAME> <FILENAMES>

 <DIRNAME> is the directory where the conveted files will be saved.
 <FILENAMES> is a list of files to be converted.  These are given last
 so that this function works easily with things like find and xargs.

 The optional arguments [OPTIONS] are as follows:

 -h: See this help message and exit.
 -t: A timezone string (e.g., "PST").  Defaults to "GMT" if not given
 -o: The GMT offset in hours for the new timezone.  Defaults to 0.
 -d: A boolean indicating daylight savings or not.  Defaults to 0.
 -f: A boolean indicating if the filenames of converted files should be 
     modified to reflect the new time of the file.  Defaults to 1.

 Example: convert_RDL_timezone.pl -t "GMT" -o 0 -d 0 -f 0 GMT_files/ file1 file2
 
 This function works quite simply (or stupidly).  The timestamp and timezone
 information are obtained from the %TimeStamp and %TimeZone fields in the 
 RDL file.  If filenames are to be updated, then the timestamp is also obtained
 from the filename (the processing stops if this timestamp cannot be parsed or is
 not the same as that in the file).  Then the difference between the new and the 
 current GMT offset is added to the timestamp and the file is saved, possibly
 with an updated filename, in the indicated directory.

 Note that this function knows nothing about timezone strings or daylight
 savings time.  It assumes that the offset in the original file is correct and
 relative to UTC and works with that.  The new offset is also assumed to be
 relative to UTC irrespective of what timezone string you put.  Any timezone
 string specified on the command line is just used to format the new %TimeZone
 field and has no formal bearing on the result of the conversion.  Similarly 
 for the daylight savings time indicator.

 For example, if you are working with PDT during a time of daylight savings
 (e.g. summer) in the original file the timezone should be indicated as:
 
 %TimeZone: "PDT" -7.000 1
   
 Similarly, a file in winter would say:

 %TimeZone: "PDT" -8.000 0

 The disadvantage of this approach is that it is quite difficult to use this
 function to change TO a daylight savings timezone as winter files must be
 processed separately from summer files.  

 The reason for not making a more complicated algorithm is that Mac OSX does
 not seem to be very strict about the definition of timezone strings.  For
 example, PST is often used even though daylight savings is on (i.e., PDT
 should be used).  The end result is that the result of trying to figure out
 the new offset and daylight savings time state is likely to be OS dependent
 and difficult to generalize.  

 NOTE: This routine might have a problem if the text format of the files is not 
 Unix.  I have not tried this with non-Unix (or Mac OSX?) formats, so I cannot
 say.  

#####################################################################

 	$Id: convert_RDL_timezone.pl 63 2006-12-20 15:24:14Z dmk $	

 Copyright (C) 2006 David M. Kaplan
 Licence: GPL

#####################################################################
EOH

exit 0;
}

main:
{
    # Deal with options
    my %opts = ();
    getopts('ht:o:d:f:', \%opts);

    # If wanted help, givem help.
    HELP_MESSAGE() if (defined($opts{'h'}));

    # Defaults options
    defined($opts{'t'}) or $opts{'t'}='GMT'; # GMT / UTC
    defined($opts{'o'}) or $opts{'o'}=0; # offset of 0
    defined($opts{'d'}) or $opts{'d'}=0; # no daylight savings
    defined($opts{'f'}) or $opts{'f'}=1; # Modify file names

    # Get location for saving converted files
    my $dn = shift( @ARGV );

    my $fn;
    foreach $fn (@ARGV) {
	print STDERR "Beginning conversion of $fn\n";

	my ($tsn,$tzn,$ts,$tzs,$tzo,$dst,@txt) = &file_load_and_parse($fn);

	if (!$tsn) {
	    print STDERR "WARNING: Filename $fn could not be loaded or parsed. Skipping.\n";
	    next;
	}

	my $ts2;
	($txt[$tsn],$txt[$tzn],$ts2) = &change_offset( $ts, $tzo, $opts{'o'}, 
						      $opts{'t'}, $opts{'d'} );

	# If desired, adjust filename
	my $nfn;
	if ($opts{'f'}) {
	    $nfn = &adjust_filename( basename($fn), $ts, $ts2 );
	    if (!$nfn) {
		print STDERR "WARNING: Could not adjust filename $fn to new time. Skipping\n";
		next;
	    }
	} else { $nfn = basename($fn); }

	# New filename
	$nfn = File::Spec->catfile( $dn, $nfn ); 

	&file_write( $nfn, @txt ) or 
	    print STDERR "WARNING: Filename $nfn (from old file $fn) could not be save. Skipping.\n";
    }

}

sub file_load_and_parse 
{
    my ($tsn, $tzs, $tzo, $dst, $ts, $tzn);

    open FILE, $_[0] or return 0;

    my @txt = ();
    my $k = 0;
    while ( <FILE> ) {
	$k = push( @txt, $_ );
	$k--;

	if ( /^\%TimeStamp:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ ) {
	    my ($y,$m,$d,$h,$mm,$s) = ($1,$2,$3,$4,$5,$6);
	    $tsn = $k;
	    $ts = timegm( $s, $mm, $h, $d, $m-1, $y );
	    
	}
	
	if ( /^\%TimeZone:\s+\"([^\"]+)\"\s+([^ \t]+)\s+([^ \t]+)/ ) {
	    ($tzs,$tzo,$dst) = ($1,$2,$3);
	    $tzn = $k;
	}
	
    }
    
    close FILE;
    return $tsn, $tzn, $ts, $tzs, $tzo, $dst, @txt;
}

sub change_offset 
{
    my ($ts,$tzo1,$tzo2,$tzs2,$dst2) = @_;

    # Difference between offsets in seconds.
    my $dd = ($tzo2 - $tzo1) * 60 * 60; 

    $ts = $ts + $dd;

    my ($s,$mm,$h,$d,$m,$y) = gmtime($ts);
    $y += 1900; # Need to get it in years since 0, not 1900
    $m += 1; # Months ranging 1..12 instead of 0..11

    my $s1 = sprintf("%%TimeStamp: %04d %02d %02d %02d %02d %02d\n",
		     $y,$m,$d,$h,$mm,$s);
    my $s2 = sprintf("%%TimeZone: \"%s\" %+0.3f %d\n",
		     $tzs2,$tzo2,$dst2);

    return $s1, $s2, $ts;
}

sub adjust_filename 
{
    my ($fn,$ts,$ts2) = @_;

    my ($s2,$mm2,$h2,$d2,$m2,$y2) = gmtime($ts2);
    $y2 += 1900;
    $m2 += 1;

    if ( $fn =~ /^(.*)(\d{4})([_-])(\d{2})([_-])(\d{2})([_-])(\d{4})(.*)$/ ) {
	my ($st,$y,$i1,$m,$i2,$d,$i3,$hhmm,$et) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);

	$hhmm =~ /(\d{2})(\d{2})/;
	my ($h,$mm) = ($1,$2);
	
	if ( timegm(0,$mm,$h,$d,$m-1,$y) != timegm( 0, (gmtime($ts))[1,2,3,4,5] ) ) {
	    return 0;
	}

	$fn = sprintf("%s%04d%s%02d%s%02d%s%02d%02d%s",$st,$y2,$i1,$m2,$i2,$d2,$i3,
		      $h2,$mm2,$et);

    } else {
	return 0;
    }

    return $fn;
}

sub file_write
{
    my $fn = shift(@_);
    my @txt = @_;

    open FILE, ">$fn" or return 0;
    
    while ( $#txt >= 0 ) {
	print FILE shift(@txt);
    }

    close FILE;

}
