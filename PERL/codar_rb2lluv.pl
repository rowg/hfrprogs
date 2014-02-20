#!/usr/bin/perl -w
use File::Basename;
use Geo::Ellipsoid;
use POSIX qw(ceil floor);

#################################################################################
# USAGE: codar_rb2lluv.pl /path/rangeBinFile						  #
#													  #
# Code to convert range-bin CODAR format radial files to LLUV CODAR format	  #
# radial files.  Used as is, the LLUV format file is written to the same	  #
# directory as the given range-bin file with the LLUV format file name.		  #
# Multiple subroutines, described below, are used to accomplish the conversion. #
#													  #
#	&lluvFname											  #
#		Takes a CODAR format range-bin filename and returns a CODAR 	  #
#		format LLUV filename, ie. given RadsUABC_04-10-10_0400, 	 	  #
#		RDLi_UABC_2004_10_10_0400.ruv is returned.  If elements can't	  #
#		be obtained from the filename or other problems occur, undef is	  #
#		returned.										  #
#													  #
#	&convertFile										  #
#		Takes an input range-bin filename and output LLUV filename		  #
#		and runs the subroutines below to convert the range-bin file	  #
#		to a LLUV format file. Returns '1' upon sucess,	otherwise		  #
#		undef is returned.  								  #
#													  #
#	&slurpFile											  #
#		Given a file, it returns each line of the file as an array.		  #
#		The subroutine can read files with both linefeeds (ASCII 10)	  #
#		and returns (ASCII 13) as end-of-line indicators.  Returns 		  #
#		undef in case of failure.		  					  #
#													  #
#	&chkTime											  #
#		Given the range-bin filename and the file contents in a list	  #
#		(as returned by slurpFile), the subroutine checks for			  #
#		consistancy between the timestamp on the filename and the		  #
#		serial time reported in line 1 of the range-bin file.  Undef	  #
#		is returned if the times do not match or if no timezone is		  #
#		found.  Otherwise, the timezone and gregorian date are 		  #
#		returned.  										  #
#													  #
#	&getPos											  #
#		Given the range-bin file contents (as returned by slurpFile), 	  #
#		the radar position from line 2 is returned in decimal degrees.	  #
#		Match expressions can handle a variety of representations of 	  #
#		latitude & longitude, including decimal degrees.  The full list	  #
#		of variations handled in line 2 are documented in CODAR Radial  	  #
#		File Format Review by Mark Otero dated April 28, 2006.		  #
#		Undef is returned in case problems are encountered.	 	 	  #
#												   	  #
#	&rb2lluv											  #
#		Given the radar latitude & longitude and the array of file		  #
#		contents as returned by slurpFile, the subroutine returns		  #
#		an array of arrays containing converted data and relevant		  #
#		metadata.  Otherwise, undef is returned.					  #
#													  #
#	&mod												  #
# 		Modulus sub-routine required to get fractional output. Perl's	  #
#		'%' reduces input values to integer values while fmod 		  #
#		(in POSIX) gets the results sign from x, not y.  The subroutine	  #
#		is used by the rb2lluv subroutine.						  #
#													  #
#	&getMetadata										  #
#		Given the range-bin filename (for obtaining the site and		  #
#		beampattern type), the line that trailer metadata starts on &	  #
#		the array of file contents, a hash of metadata is returned.		  #
#		Otherwise, undef is returned.  Returned hash keys are mapped to	  #
#		the metadata keywords used in the LLUV format.				  #
#													  #
#	&writeLLUV											  #
#		Given the LLUV filename, the data array returned from &rb2luv	  #
#		and the metadata hash returned from &getMetadata, the			  #
#		subroutine writes the data and metadata to the given LLUV file	  #
#		in the LLUV format.  Returns '1' upon sucess, otherwise undef.	  #
#													  #
# NOTES: 												  #
#	Currently, only GMT/UTC/PST timezones are handled by the writeLLUV		  #
# subroutine.  This is because other timezones haven't been encountered.	  #
# Other timezones can be added to this function by expanding the %tzhash.
# The conversion is aborted if a timezone other than UTC/GMT/PST is encountered	  #
# by writeLLUV.											  #
#													  #
#	The LLUV file written is based on the Codar Table Format File Format	  #
# Specification Version 1.00 dated Feb 20, 2005 and the SeaSonde 10 LonLatUV 	  #
# (LLUV) file format version 1.02 dated Jan 11, 2006. The GeodVersion 'PGEO'	  #
# (Perl GEOdesic) has been registerd with CODAR as well as the 			  #
# 'codar_rb2lluv.pl' Processing tool.							  #
#													  #
# 	The RangeStart keyword forced to '1', regardless of the first bin in	  #
# the range-bin file.  This is the convention currently used by CODAR.		  #
#													  #
#	The ReferenceBearing keyword is always zero when written to lluv since	  #
# any reference bearing in the range-bin file is taken into account for the 	  #
# bearings reported.								  		  #
#													  #
#	The RadSmoothing value reported in the range-bin file isn't propagated	  #
# to a keyword in the lluv format because it isn't yet in use (always 0) and 	  #
# its formatting in the lluv format isn't clear yet.  Presumably, users		  #
# providing files in range-bin format with this keyword could alternatively	  #
# provide the same data in lluv format since this keyword is relatively new.	  #
#													  #
#	Standard deviation values from range-bin files will always appear in 	  #
# column 6, regardless of the column label (Spatial Quality).  Until recently,  #
# standard deviations reported in range-bin files corresponded to Temporal	  #
# Quality but this has recently changed.  Exact dates on this change aren't	  #
# available and aren't necessairly tied to the data timestamp since it depends  #
# on the code versions used to process the data.				  	  #
#													  #
# 	Column 7, Temporal Quality, is always 999.0 (bad value) and the maximum	  #
# and minimum velocities reported in columns are always equal to the velocity.  #
# This follows the current convention used by CODAR.					  #
#													  #
#	The subroutine &convertFile checks to ensure a minimum of metadata has	  #
# has been obtained before proceeding with writing the LLUV file.  Minimum 	  #
# metadata requirements are Site, TimeStamp, Origin, PatternType and a   #
# known TimeZone.											  #
#													  #
#	This code has been developed in support of the HF-Radar National		  #
# Network and the state of California's Coastal Ocean Currents Monitoring 	  #
# Program (COCMP)											  #
#													  #
# REPORTING BUGS:											  #
# Please email motero@mpl.ucsd.edu to report any bugs.  Include sample radial	  #
# files and describe the problem observed.						  #
#													  #
# v1.00												  #
# 2006/05/01 - Mark Otero									  #
#													  #
# v1.01												  #
# 2006/10/20 - Cleaned up some logical operators from bitwise operators (&, |)  #
#              to logical operators (||, &&). MO					  #
# 2006/10/20 - Cleaned up timezone handling and requre timezone to be UTC or 	  #
#              GMT. MO										  #
# 2006/12/15 - Allowed filenames to begin with "Rad" or "rad", as opposed to just "Rad"	  #
#              DMK										  #
# 2006/12/15 - Added hash to deal with PST timezone - needs to be expanded for other cases  #
#              DMK										  #
#################################################################################

# Global version variables
$codeVersion = '%ProcessingTool: "codar_rb2lluv.pl" 1.01';
$processedBy = '%ProcessedBy: "HFRNet"';
$greatCircle = '%GreatCircle: "WGS84" 6378137.000  298.257223563';
$geodVersion = '%GeodVersion: "PGEO" ' .  $Geo::Ellipsoid::VERSION . ' 2005 11 04';

# Get file to convert from input
$pathFile = $ARGV[0];
$file     = basename $pathFile;
$rootDir  = $pathFile;
$rootDir  =~ s%/$file%%;

# Hash to deal with some familiar timezones
my %tzhash = (
	   "UTC"        => [+0,0],
	   "GMT"        => [+0,0],
	   "PST"        => [-8,0],
	      );

# Generate LLUV filename
$lluvFile = &lluvFname($file);
die "ERROR: Input filename format $file not recognized\n"
    unless defined $lluvFile;

# Convert file
die "ERROR: Failure in conversion of $pathFile\n"
    unless &convertFile($pathFile, "$rootDir/$lluvFile");


###############
# Subroutines #
###############

sub lluvFname {
    my $file = $_[0];
    my $lluvFile;
    if ($file =~ m/^[Rr]ad([sz])(\w{4})[-_\s](\d{2})[-_](\d{2})[-_](\d{2})[-_\s](\d{2})(\d{2})(.rv)?$/) {
        my $patt = $1;
        my $site = $2;
        my $yyyy = $3;
        my $mm   = $4;
        my $dd   = $5;
        my $HH   = $6;
        my $MM   = $7;
        $yyyy += 1900 if $yyyy > 50;
        $yyyy += 2000 if $yyyy < 50;
        $patt = 'i' if $patt eq 's';
        $patt = 'm' if $patt eq 'z';
        $lluvFile = "RDL${patt}_${site}_${yyyy}_${mm}_${dd}_$HH$MM.ruv";
    } else {
        return;
    }
    return $lluvFile;
}


sub convertFile {
    my ($pathFile, $lluvFile) = @_;

    # Slurp file
    my @file = &slurpFile($pathFile);
    unless (@file > 0) {
        print STDERR "ERROR reading $pathFile\n";
        return;
    }
    print "Read $pathFile\n";

    # Check time-stamp OK & get time-zone
    my @tInfo = &chkTime($pathFile, @file);
    unless (@tInfo == 2) {
        print STDERR "ERROR processing time-stamp or timezone from $pathFile\n";
        return;
    }
    print "Time-stamp obtained: @tInfo\n";

    # Get Radar Position
    my @origin = &getPos(@file);
    unless (@origin == 2) {
        print STDERR "ERROR extracting radar position from $pathFile\n";
        return;
    }
    printf "Origin obtained: %11.7f %12.7f\n", $origin[0], $origin[1];

    # Convert data from range-bin to LLUV
    my @data = &rb2lluv(@origin, @file);
    unless (@data == 16) {
        print STDERR "ERROR converting range-bin data to LLUV from $pathFile\n";
        return;
    }
    my $rangeRes  = shift(@data);
    my $tCoverage = shift(@data);
    my $rangeEnd  = shift(@data);
    my $metaStart = shift(@data);
    print "Data converted from range-bin to LLUV\n";

    # Extract metadata, add metadata collected from header
    # & verify minimum metadata has been obtained
    my %metadata = &getMetadata($pathFile, $metaStart, @file);
    unless (scalar keys %metadata > 0) {
        print STDERR "ERROR extracting metadata from $pathFile\n";
        return;
    }
    if ( $tInfo[0] eq 'UTC' || $tInfo[0] eq 'GMT' || (exists $tzhash{$tInfo[0]}) ) {
        $metadata{"TimeZone"}           = $tInfo[0];
    }
    $metadata{"TimeStamp"}              = $tInfo[1];
    $metadata{"TimeCoverage"}           = $tCoverage;
    $metadata{"Origin"}                 = $origin[0] . " " . $origin[1] ;
    $metadata{"RangeResolutionKMeters"} = $rangeRes;
    $metadata{"RangeEnd"}               = $rangeEnd;
    unless ( exists $metadata{"Site"}     && exists $metadata{"TimeStamp"}   &&
             exists $metadata{"Origin"}   && exists $metadata{"PatternType"} && 
             exists $metadata{"TimeZone"} ) {
        print STDERR "ERROR: Minimum metadata requirements not met for conversion\n";
        return;
    }
    print "Metadata extracted & minimum requirements for conversion met\n";

    # Write out as LLUV
    unless ( &writeLLUV($lluvFile, \@data, \%metadata) ) { 
        print STDERR "ERROR writing data to $lluvFile\n";
        return;
    }
    print "LLUV format file written to $lluvFile\n";
    return 1;
}


sub slurpFile {
    my $inFile = $_[0];
    unless (-e $inFile) {
        print STDERR "ERROR: $inFile couldn't be found\n";
        return;
    }
    my $inputRecordSeparator = $/;
    undef $/;
    open F, $inFile;
    my $file = <F>;
    $/ = $inputRecordSeparator;
    $file =~ s/\r/\n/g;
    my @file = split /\n/, $file;
    return @file;
}


sub chkTime {
    my $pathFile = shift @_;
    my @file     = @_;

    # Get timestamp from filename
    my $fileName = basename $pathFile;
    my ($fy, $fm, $fd, $fH, $fM, $tStamp);
    if ($fileName =~ m/^[Rr]ad[sz]\w{4}[-_\s](\d{2})[-_](\d{2})[-_](\d{2})[-_\s](\d{2})(\d{2})(.rv)?$/) {
        ($fy, $fm, $fd, $fH, $fM) = ($1, $2, $3, $4, $5);
        if ($fy < 50) {
            $tStamp = $fy+2000 . " $fm $fd $fH $fM 00";
        } else {
            $tStamp = $fy+1900 . " $fm $fd $fH $fM 00";
        }
    } else {
        print STDERR "ERROR: Unable to extract time from filename using match expression\n";
        return;
    }


    # Extract time info from line 1 of range-bin file
    my $tz;
    if ($file[0] =~ 
        m/^\s*\d{1,2}:\d{2}(:\d{2})?\s*(\w{2,3}\s)?\s*\w+,\s*\w+\s*\d{1,2},\s*\d{4}\s*(\w{1,4})?\s*(\w{1,4})?\s*(-\d+)\s*$/i) {

        # Get timezone, if found
        if (defined $2) {
            if ($2 !~ /(AM|PM)/) {
                $tz = $2;
                $tz =~ s/\s+$//;
            }
        }
        $tz = $3 if (defined $3) && (!defined $tz);

	# Retrun if the timezone isn't found
        unless (defined $tz) {
  	    print STDERR "ERROR: No Timezone reported\n";
            return;
        }

        # Verify serial date against filename timestamp
        ($ly, $lm, $ld, $lH, $lM, $lS)= (gmtime($5 - 2082844800 + 2**32))[5, 4, 3, 2, 1, 0];
        $lm++;
        $ly -= 100 if $ly >= 100;
        unless ( ($ly == $fy) && ($lm == $fm) && ($ld == $fd) && ($lH == $fH) && ($lM == $fM) && ($lS == 0) ) {
            print STDERR "ERROR: Filename time-stamp $fy $fm $fd $fH $fM 0 doesn't match serial time-stamp $ly $lm $ld $lH $lM $lS\n";
            return;
        }

    # Return if line 1 couldn't be parsed
    } else {
        print STDERR "ERROR: Format unrecognized on LINE 1\n";
        return;
    }

    # If sucessful, return timezone & timestamp
    return ($tz, $tStamp);
}


sub getPos {
    my @file  = @_;
    my $dLat;
    my $dLon;

    # Check for more common position reported in degrees & decimal minutes w/various separators
    if ($file[1] =~ 
        m/^\s*(\d{1,2})(\302)?(\260|\241|\373|\s)(\d{1,2}.\d+)('|\241)(N|S)(,|\s)\s*(\d{1,3})(\302)?(\260|\241|\373|\s)(\d{1,2}.\d+)('|\241)(E|W)\s*$/i) {
        if ( (defined $1) && (defined $4) && (defined $6) && (defined $8) && (defined $11) && (defined $13) ) {
            $dLat = $1 + $4/60;
            $dLat = -1 * $dLat if $6  eq "S";
            $dLon = $8 + $11/60;
            $dLon = -1 * $dLon if $13 eq "W";
        }

    # Check for decimal degrees (ie. RFG1)
    } elsif ($file[1] =~ m/^\s*(\d{1,2}.\d+)(\302)?\241(N|S),(\d{1,3}.\d+)(\302)?\241(E|W)\s*$/i) { 
        if ( (defined $1) && (defined $3) && (defined $4) && (defined $6) ) {
            $dLat = $1; 
            $dLat = -1 * $dLat if $3 eq "S";
            $dLon = $4;
            $dLon = -1 * $dLon if $6 eq "W";
        }
    } else {
        print STDERR "ERROR: Position could not be parsed from LINE 2\n";
        return;
    }
    my @origin = ($dLat, $dLon);
    return @origin;
}


sub rb2lluv {
    my @origin = (shift @_, shift @_);
    my @file   = @_;

    # Get distance to first range cell, range resolution, reference angle &
    # time coverage
    $file[2] =~ s/^\s+//;
    $file[2] =~ s/\s+$//;
    my ($d0, $rRes, $refAng, $dt) = split ' ', $file[2];
    $dt *= 60;
    unless ( (defined $d0) && (defined $rRes) && (defined $refAng) && (defined $dt) ) {
        print STDERR "ERROR: Failed to read line 3\n";
        return;
    }

    # Get number of range cells
    my $nRngCells;
    if ( $file[3] =~ m/^\s*(\d+)\s*$/ ) {
        $nRngCells = $1;
    } else { 
        print STDERR "ERROR: Failed to read line 4\n";
        return;
    }

    # Get starting range cell index
    my $rngStart; 
    if ( $file[4] =~ m/^\s*\d+\s+(\d+)\s*$/ ) {
        $rngStart = $1;
    } else {
        print STDERR "ERROR obtaining starting range bin on line 5\n";
        return;
    }

    # Loop through each range cell & build lists of bearing, speed,
    # uncertinty, range cell index & range.
    my $lineInd = 4;
    my ($rangeCell, $nVect, $nLinesPerVar, $rbVar, @vals, $i);
    my (@Bearings, @Speeds, @Uncerts, @CellInds, @Ranges);
    foreach $rangeCell ($rngStart..$nRngCells+$rngStart-1) {

        # Read total number of vectors for range cell
        if ( $file[$lineInd] =~ m/^\s*(\d+)\s+$rangeCell\s*$/ ) {
            $nVect = $1;
            $lineInd++;
        } else {
            printf STDERR "ERROR reading data from line %i\n", $lineInd + 1;
            return;
        }

	# If vectors found for range cell, read them into a list for each variable
        if ($nVect > 0) {
            $nLinesPerVar = ceil($nVect/7);
            foreach $i (1..3) {
                foreach (1..$nLinesPerVar) {
                    $file[$lineInd] =~ s/^\s+//;
                    $file[$lineInd] =~ s/\s+$//;
                    push( @vals, (split ' ', $file[$lineInd]) );
                    $lineInd++;
                }
                unless (@vals == $nVect) {
                    printf STDERR "ERROR reading data for range cell %i\n", $rangeCell;
                    return;
                }
                push @Bearings, @vals if $i == 1;
                push @Speeds,   @vals if $i == 2;
                push @Uncerts,  @vals if $i == 3;
                undef @vals;
            }
            foreach (1..$nVect) {
                push @CellInds, $rangeCell;
                push @Ranges, $d0 + ($rRes*($rangeCell-1));
            }
        }
    }

    # First metadata line index 
    my $metaStart = $lineInd++;

    # Define the ellipsoid for lat/lon, Easting/Northing conversions
    my $geo = Geo::Ellipsoid -> new(
        ellipsoid => 'WGS84',
        units     => 'degrees'
    );

    # Define constants
    my $pi      = atan2(1,1) * 4;
    my $deg2rad = $pi/180;

    # Loop through each element in the data list
    my (@Lats, @Lons, @Eastings, @Northings, @Directions, @Us, @Vs);
    foreach $i (0..$#Bearings) {

        # Add reference angle to bearings and convert bearing from polar coords reported 
        # by CODAR ( E = 0, CCW) to compass coords expected by Geo::Ellipsoid module 
        # (N = 0, CW)
        $Bearings[$i] += $refAng; 
        $Bearings[$i] = mod(90-$Bearings[$i], 360);

        # Calculate latitude, longitude, Easting & Northing from range & bearing
        ($Lats[$i],    $Lons[$i])       = $geo -> at($origin[0], $origin[1], $Ranges[$i]*1000, $Bearings[$i]);
        ($Eastings[$i], $Northings[$i]) = $geo -> displacement($origin[0], $origin[1], $Lats[$i], $Lons[$i]);
        $Eastings[$i]  /= 1000;
        $Northings[$i] /= 1000;

        # Compute bearing from radial vector to radar site
        $Directions[$i] = $geo -> bearing($Lats[$i], $Lons[$i], $origin[0], $origin[1]);
        my $directionECCW = mod(90-$Directions[$i], 360);

        # Compute radial u & v components from scalar speed & bearing
        $Us[$i] = cos($directionECCW*$deg2rad) * $Speeds[$i];
        $Vs[$i] = sin($directionECCW*$deg2rad) * $Speeds[$i];
    }

    # Put all data into 2D array (array of arrays)
    my @data = (
        [@Lons],     [@Lats],     [@Us],         [@Vs],
        [@Uncerts],  [@Eastings], [@Northings],  [@Ranges],     
        [@Bearings], [@Speeds],   [@Directions], [@CellInds]
    );
    return $rRes, $dt, $nRngCells, $metaStart, @data;
}


sub mod {
    my ($x, $y) = @_;
    my $n = floor($x/$y);
    my $val = $x - $n*$y;
    return $val;
}


sub getMetadata {
    my $pathFile  = shift @_;
    my $metaStart = shift @_;
    my @file      = @_;

    # Establish metadata mapping hash between rb keywords and lluv keywords
    my %map = (
        "CenterFreqMHz"        => "TransmitCenterFreqMHz",
        "DopplerFreqHz"        => "DopplerResolutionHzPerBin",
        "AverFirmssPts"        => "BraggSmoothingPoints",
        "LimitMaxCurrent"      => "CurrentVelocityLimit",
        "UseSecondOrder"       => "BraggHasSecondOrder",
        "FactorDownPeakLimit"  => "RadialBraggPeakDropOff",
        "FactorDownPeakNull"   => "RadialBraggPeakNull",
        "FactorAboveNoise"     => "RadialBraggNoiseThreshold",
        "AmpAdjustFactors"     => "PatternAmplitudeCorrections",
        "AmpCalculated"        => "PatternAmplitudeCalculations",
        "PhaseAdjustFactors"   => "PatternPhaseCorrections",
        "PhaseCalculated"      => "PatternPhaseCalculations",
        "MusicParams"          => "RadialMusicParameters",
        "NumMergeRads"         => "MergedCount",
        "MinRadVectorPts"      => "RadialMinimumMergePoints",
        "FirstOrderCalc"       => "FirstOrderCalc",
        "Currents"             => "Currents",
        "RadialMerger"         => "RadialMerger",
        "SpectraToRadial"      => "SpectraToRadial",
        "RadialSlider"         => "RadialSlider",
    );

    # Extract metadata from each line and put into a hash until '!END' 
    # or all lines read.  Hash key will be metadata descriptor and value will
    # be remainder of line - ie. key = 'NumMergeRads', value = '7'.
    my ($lineInd, %trailer);
    foreach $lineInd ($metaStart..@file-1) {
        my $line = $file[$lineInd];
        last if $line =~ /!END/i;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ /^([A-Za-z]+)\s+(.*)$/;
        $trailer{$1} = $2 if (defined $1) && (defined $2);
    }
    return unless scalar keys %trailer > 0;

    # Map range-bin keywords to lluv keywords
    my ($key, $val, %metadata);
    while ( ($key, $val) = each %trailer ) {
        if ( defined $map{$key} ) {
            $metadata{ $map{$key} } = $val;
        } else {
            print STDERR "WARNING, unmatched metadata field from range-bin file: $key\t$val\n"
                unless $key eq "RadSmoothing";
        }
    }

    # Extract site and beampattern from filename
    $fileName = basename $pathFile;
    if ($fileName =~ m/^[rR]ad([sz])(\w{4})[-_\s]\d{2}[-_]\d{2}[-_]\d{2}[-_\s]\d{2}\d{2}(.rv)?$/) {
        my ($patt, $site) = ($1, $2);
        $metadata{"PatternType"} = "Ideal"    if $patt eq 's';
        $metadata{"PatternType"} = "Measured" if $patt eq 'z';
        $metadata{"Site"}        = $site;
    } else {
        print STDERR "ERROR: Unable to extract site & pattern from filename using match expression\n";
        return;
    }

    return %metadata;
}


sub writeLLUV {
    my ($lluvFile, $dataRef, $metaRef) = @_;
    return unless open LLUV, "> $lluvFile";

    # Begin writing metadata
    print LLUV "%CTF: 1.00\n";
    print LLUV "%FileType: LLUV rdls \"RadialMap\"\n";
    print LLUV "%LLUVSpec: 1.02  2006 01 11\n";
    print LLUV "%Manufacturer: CODAR Ocean Sensors. SeaSonde\n";
    print LLUV "%Site: $metaRef->{'Site'} \"\"\n";
    print LLUV "%TimeStamp: $metaRef->{'TimeStamp'}\n";

    # Since GMT offset & daylight savings in included in TimeZone key, only report
    # GMT & UTC times.  Could create a hash of timezones & GMT offsets, then would
    # need to determine if daylight savings.  For now, only convert GMT and UTC 
    # timezones.
    if (exists $metaRef->{'TimeZone'}) {
        my $tz = $metaRef->{'TimeZone'};
        if ( ($tz eq 'GMT') || ($tz eq 'UTC') ) {
            print LLUV "%TimeZone: \"$tz\" +0.000 0\n" 
        } elsif (exists $tzhash{$tz}) {
	    print LLUV "%TimeZone: \"$tz\" " . 
		(sprintf( "%+0.3f %d",$tzhash{$tz}[0],$tzhash{$tz}[1])) .
		"\n"
	} else {
            print STDERR "ERROR: Non-UTC/GMT Timezone detected, aborting!\n";
            close LLUV;
            unlink $lluvFile;
            return;
        }
    }

    print  LLUV "%TimeCoverage: $metaRef->{'TimeCoverage'} Minutes\n"
        if exists $metaRef->{'TimeCoverage'};
    printf LLUV "%%Origin: %11.7f %12.7f\n", (split ' ', $metaRef->{'Origin'})[0, 1];
    print  LLUV "$greatCircle\n";
    print  LLUV "$geodVersion\n";
    printf LLUV "%%RangeResolutionKMeters: %6.3f\n",
        $metaRef->{'RangeResolutionKMeters'}
        if exists $metaRef->{'RangeResolutionKMeters'};
    printf LLUV "%%TransmitCenterFreqMHz: %9.6f\n",
        $metaRef->{'TransmitCenterFreqMHz'}
        if exists $metaRef->{'TransmitCenterFreqMHz'};
    printf LLUV "%%DopplerResolutionHzPerBin: %11.9f\n",
        $metaRef->{'DopplerResolutionHzPerBin'}
        if exists $metaRef->{'DopplerResolutionHzPerBin'};
    printf LLUV "%%BraggSmoothingPoints: %d\n",
        $metaRef->{'BraggSmoothingPoints'}
        if exists $metaRef->{'BraggSmoothingPoints'};
    printf LLUV "%%CurrentVelocityLimit: %6.1f\n",
        (split ' ', $metaRef->{'CurrentVelocityLimit'})[0]
        if exists $metaRef->{'CurrentVelocityLimit'};
    printf LLUV "%%BraggHasSecondOrder: %d\n",
        $metaRef->{'BraggHasSecondOrder'}
        if exists $metaRef->{'BraggHasSecondOrder'};
    printf LLUV "%%RadialBraggPeakDropOff: %6.3f\n",
        $metaRef->{'RadialBraggPeakDropOff'}
        if exists $metaRef->{'RadialBraggPeakDropOff'};
    printf LLUV "%%RadialBraggPeakNull: %5.3f\n",
        $metaRef->{'RadialBraggPeakNull'}
        if exists $metaRef->{'RadialBraggPeakNull'};
    printf LLUV "%%RadialBraggNoiseThreshold: %5.3f\n",
        $metaRef->{'RadialBraggNoiseThreshold'}
        if exists $metaRef->{'RadialBraggNoiseThreshold'};
    printf LLUV "%%PatternAmplitudeCorrections: %6.4f %6.4f\n", 
        (split ' ', $metaRef->{'PatternAmplitudeCorrections'})[0, 1]
        if exists $metaRef->{'PatternAmplitudeCorrections'};
    printf LLUV "%%PatternAmplitudeCalculations: %6.4f %6.4f\n", 
        (split ' ', $metaRef->{'PatternAmplitudeCalculations'})[0, 1]
        if exists $metaRef->{'PatternAmplitudeCalculations'};
    printf LLUV "%%PatternPhaseCorrections: %5.2f %5.2f\n",
        (split ' ', $metaRef->{'PatternPhaseCorrections'})[0, 1]
        if exists $metaRef->{'PatternAmplitudeCalculations'};
    printf LLUV "%%PatternPhaseCalculations: %4.2f %4.2f\n",
        (split ' ', $metaRef->{'PatternPhaseCalculations'})[0, 1]
        if exists $metaRef->{'PatternPhaseCalculations'};
    printf LLUV "%%RadialMusicParameters: %6.3f %6.3f %6.3f\n",
        (split ' ', $metaRef->{'RadialMusicParameters'})[0, 1, 2]
        if exists $metaRef->{'RadialMusicParameters'};
    printf LLUV "%%MergedCount: %d\n",
        $metaRef->{'MergedCount'}
        if exists $metaRef->{'MergedCount'};
    printf LLUV "%%RadialMinimumMergePoints: %d\n",
        $metaRef->{'RadialMinimumMergePoints'}
        if exists $metaRef->{'RadialMinimumMergePoints'};
    printf LLUV "%%FirstOrderCalc: %d\n",
        $metaRef->{'FirstOrderCalc'}
        if exists $metaRef->{'FirstOrderCalc'};
    print  LLUV "%RangeStart: 1\n";
    printf LLUV "%%RangeEnd: %d\n",
        $metaRef->{'RangeEnd'}
        if exists $metaRef->{'RangeEnd'};
    print  LLUV "%ReferenceBearing: 0 DegNCW\n";
    print  LLUV "%PatternType: $metaRef->{'PatternType'}\n";

    # Print data
    print  LLUV "%TableType: LLUV RDL5\n";
    print  LLUV "%TableColumns: 16\n";
    print  LLUV "%TableColumnTypes: LOND LATD VELU VELV VFLG ESPC ETMP MAXV MINV XDST YDST RNGE BEAR VELO HEAD SPRC\n";
    printf LLUV "%%TableRows: %d\n", scalar @{$dataRef->[0]};
    print  LLUV "%TableStart:\n";
    print  LLUV "%%   Longitude   Latitude    U comp   V comp  VectorFlag    Spatial    Temporal     Velocity    Velocity  X Distance  Y Distance  Range   Bearing  Velocity  Direction   Spectra\n";
    print  LLUV "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Maximum     Minimum      (km)        (km)      (km)  (deg NCW)  (cm/s)   (deg NCW)   RngCell\n";
    my ($i, $j);
    foreach $i (0..$#{$dataRef->[0]}) {
        foreach $j (0..$#$dataRef) {
            printf LLUV "  %12.7f", $dataRef->[$j][$i]   if $j ==  0; # Longitude
            printf LLUV " %11.7f" , $dataRef->[$j][$i]   if $j ==  1; # Latitude
            printf LLUV " %8.3f"  , $dataRef->[$j][$i]   if $j ==  2; # U
            printf LLUV " %8.3f"  , $dataRef->[$j][$i]   if $j ==  3; # V
            if ($j == 4) {
                printf LLUV " %10d"  , 0;                             # VectorFlag
                if ($dataRef->[$j][$i] eq 'NAN(001)') {
                    printf LLUV " %11s", 'nan';                       # SpatialQuality (NaN)
                } else {    
                    printf LLUV " %11.3f", $dataRef->[$j][$i];        # SpatialQuality
                }
                printf LLUV " %11.3f", 999;                           # TemporalQuality
                printf LLUV " %11.3f", $dataRef->[$j+5][$i];          # VelMax
                printf LLUV " %11.3f", $dataRef->[$j+5][$i];          # VelMin
            }
            printf LLUV " %11.4f" , $dataRef->[$j][$i]   if $j ==  5; # Xdistance
            printf LLUV " %11.4f" , $dataRef->[$j][$i]   if $j ==  6; # Ydistance
            printf LLUV " %8.3f"  , $dataRef->[$j][$i]   if $j ==  7; # Range
            printf LLUV " %7.1f"  , $dataRef->[$j][$i]   if $j ==  8; # Bearing
            printf LLUV " %9.2f"  , $dataRef->[$j][$i]   if $j ==  9; # Velocity
            printf LLUV " %9.1f"  , $dataRef->[$j][$i]   if $j == 10; # Direction
            printf LLUV " %9d\n"  , $dataRef->[$j][$i]   if $j == 11; # RangeCell
        }
    }
    print  LLUV "%TableEnd:\n";
    print  LLUV "%%\n";

    # Print remaining metadata
    my @now = gmtime;
    $now[5] += 1900;
    $now[4] += 1;
    foreach $i (1..5) { $now[$i] = "0$now[$i]" if $now[$i] < 10 }
    printf LLUV "%%ProcessedTimeStamp: %4s %2s %2s %2s %2s %2s\n", (@now)[5, 4, 3, 2, 1, 0];
    print  LLUV "$processedBy\n";
    print  LLUV "$codeVersion\n";
    printf LLUV "%%ProcessingTool: \"Currents\" %s\n",
        $metaRef->{'Currents'}
        if exists $metaRef->{'Currents'};
    printf LLUV "%%ProcessingTool: \"RadialMerger\" %s\n",
        $metaRef->{'RadialMerger'}
        if exists $metaRef->{'RadialMerger'};
    printf LLUV "%%ProcessingTool: \"SpectraToRadial\" %s\n",
        $metaRef->{'SpectraToRadial'}
        if exists $metaRef->{'SpectraToRadial'};
    printf LLUV "%%ProcessingTool: \"RadialSlider\" %s\n",
        $metaRef->{'RadialSlider'}
        if exists $metaRef->{'RadialSlider'};
    print  LLUV "%End:\n";

    # Close file & return
    close LLUV;
    return 1;
}
