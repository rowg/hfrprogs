#! /usr/bin/perl -w
use Getopt::Std;
use strict;
use File::Find ();
use File::Spec;
use File::Basename;

# Will jump here on help request.
sub HELP_MESSAGE
{
    my ($fh) = @_;
    $fh ||= \*STDOUT;
    print $fh <<'EOH';
######################################################################
 This script copies RDL data files to an HFR_Progs-style directory hierarchy.  

 Usage: cpdata2HFRdirs.pl [OPTIONS] <BASEDIRNAME> <NAMES>

 <BASEDIRNAME> is the directory at the base of the (future) data hierarchy.

 <NAMES> is a list of directories or files where data files are currently
 located.  These can contain wildcards just like ls or find commands.  
 Each <NAME> is searched for data files (which must begin with RDL or rdl
 to be identified as data files).  Subdirectories are also searched for
 data files.  <NAMES> are given last to work easily with things like find 
 and xargs.

 The site names, dates and file types are taken from the names of each file.
 This information is then used to determine the subdirectory of <BASEDIRNAME>
 where the file should be placed.  Subdirectories will be created if they 
 do not already exist.

 The optional arguments [OPTIONS] are as follows:

 -h: See this help message and exit.
 -m: move files instead of copying them (copy is the default)
 -l: symbolically link files instead of copying them. Overrides -m.
     NOTE: <NAMES> must be absolute path to files for this to work. 
 -f: force copy of files even if it will overwrite an existing file.
     The default is to interactively confirm overwrite of existing files.
 -b: make a backup of files to be overwritten.  See the -b option of cp 
     for more details.
 -v: Print out messages explaining what it is currently doing.

#####################################################################

 	$Id: cpdata2HFRdirs.pl 472 2007-08-21 22:52:53Z dmk $	

 Copyright (C) 2006 David M. Kaplan
 Licence: GPL

#####################################################################
EOH

exit 0;
}

######################################################################
######## START OF MAIN ################
######################################################################
use vars qw/ %opts /;

getopts('hfmbvl', \%opts);

# If wanted help, givem help.
HELP_MESSAGE() if (defined($opts{'h'}));

# Defaults options
use vars qw/ @cp /;
@cp = ("cp");
defined($opts{'m'}) and @cp=("mv"); # mv instead of cp
defined($opts{'l'}) and @cp=("ln","-s"); # mv instead of cp
defined($opts{'f'}) and push(@cp,"-f") or push(@cp,"-i");
defined($opts{'b'}) and push(@cp,"-b"); # Make backups

# Get location for saving converted files
use vars qw/ $dn /;
$dn = shift( @ARGV );

##################################################
# Some of below was generated automatically with find2perl
##################################################

# Set the variable $File::Find::dont_use_nlink if you're using AFS,
# since AFS cheats.

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

use Cwd ();
my $cwd = Cwd::cwd();

# Variables to store filenames for copying
use vars qw/ @fns @nfns /;

# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, @ARGV);
 
for (0..$#fns) {
    &cpfiles($fns[$_],$nfns[$_]);
}

######################################################################
######## END OF MAIN ################
######################################################################


sub wanted {
    my ($dev,$ino,$mode,$nlink,$uid,$gid);

    /^[Rr][Dd][Ll].*\z/s &&
    (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
    -f _ &&

    &add_files;
}

sub add_files {
    my $nfn;

    defined($opts{'v'}) and print STDERR "PARSING: $name\n";

    ($nfn = &parse_filename) || 
	( (print STDERR "WARNING: Could not parse $name. Skipping.\n") &&
	  return );

    push( @fns, $name );
    push( @nfns, $nfn );
}

# Pulls out the useful stuff and makes a new full file path based on info.
sub parse_filename {
    
    # Parse only for needed pieces
    /^([Rr][Dd][Ll][IiMm])[ -_]([^_\- ]+)[ \-_](\d{4})[ \-_](\d{2}).*\z/s ||
	return;

    my ($t,$s,$y,$m) = ($1,$2,$3,$4);
    # $t =~ tr/A-Z/a-z/; # commented to keep uppercase directory names
 
    return File::Spec->catfile( $dn, $s, $t, $y . "_" . $m, $_ ); 
}

sub cpfiles {
    my ($f1,$f2) = @_;

    my $dd = dirname($f2);

    # Need to create directory
    if (!( -d $dd )) {
	defined($opts{'v'}) and 
	    print STDERR "MKDIR: mkdir -p $dd\n";

	&my_system("mkdir","-p",$dd);
    }

    # Actually do copy
    defined($opts{'v'}) and print STDERR "COPY: @cp $f1 $f2\n";
    &my_system(@cp,$f1,$f2);

    

}

sub my_system {

    system(@_);

    # Check for failures.
    if ($? == -1) {
	die( "failed to execute: $!\n" );
    } elsif ($? & 127) {
	die( sprintf( "Child process died with signal %d\n", ($? & 127) ) );
    }
}
