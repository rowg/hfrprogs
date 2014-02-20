#!/usr/bin/perl -w

# Program to check the existence of CODAR data on an external hard drive, then
# it will oorganice the data into the CenSite computer.
#
# Comentaries on changes:
# 2006-09-19 -- jcfg:
#	The program use to work with the extension of the files, I will not consider
#	this option because the old CODAR files does not have extension. Instead I will
#	considerer the kind of files to archive, the user must check @DataKind.
#
#

#%%%%%%%%%%%%%%%%% Modules %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use File::Copy;
#use General::FileSystem "-die", "-debug";  # die on errors
use File::Find; #Traverse a directory tree.
#use File::CheckTree;
#use File::stat;
use File::Compare;
use File::Basename;
#use IO::Dir;
#use Time::gmtime;
#use POSIX;
# use strict;
use Term::ANSIColor; #Screen Text outputs with color
#system('clear');
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#================= Input variables ===================
#=====================================================
# Where are the Data to Archive into Censite?
# 	it can haldle one or more external har drives,
# 	just write the mount trajectorie of each one.
@hd = qw{/Volumes/HD_DVD};

# Directorie trajectorie in wich the Script will archive the data.
$RootCenSite     = '/Volumes/hd/HFR/CenSite/Data';
$RootCenSitePlot = '/Volumes//hd/HFR/CenSite/Plots';

# WARNING: change the name of the log file each time
#          or you would loose the previous files if it exist.
my $log_out = "/HFR_DVD/Logs/PERL/Archiving/LOG_dvd2hd";
# my $log_out = "/HFR/ProgramRepository/PERL/Archiving_jcfg/LOG_hd2CenSite12.log";


@Sites      = sort(qw/BIGC GCYN LMLS MLNG NPGS PESC PPIN PSUR SCRZ/);
#@SiteFolder = sort(qw/CSS CSA RDLi RDLm Rads Radz ruvs ruvz Rng STAT Wave Waves WVLM WVLS/);
#@DataExt        = sort(qw/cs cs4 hdt ruv rdt rs wl4 wl5 wv4/);
@DataKind = sort(qw/CSS CSA RDLi RDLm Rads Radz ruvs ruvz Rng STAT Wave Waves WVLM WVLS/);
@FigExt   = sort(qw/jpg pic gif/);

# the log file will be appended with the Time info at the moment of run the script.
my $log_out = "/Volumes/hd/HFR/CenSite/Logs/PERL/Archiving/dvd2hd";
#=====================================================
#=====================================================



# ================= Time Info for Logs ================
($sc,$mn,$hr,$md,$mo,$yr) = gmtime(time); 
$yr                       = $yr + 1900; 
$mo                       = $mo + 1;

if ($mo<10) {$mo = "0$mo";}
if ($md<10) {$md = "0$md";}
if ($hr<10) {$hr = "0$hr";}
if ($mn<10) {$mn = "0$mn";}
if ($sc<10) {$sc = "0$sc";}
# ====================================================

$log_out = join("_",$log_out,$yr);
$log_out = join("",$log_out,"$mo$md$hr$mn$sc.log");

#print "<$yr><$mo><$md><$hr><$mn><$sc> \n\n";
#print "$log_out \n\n";

# ============================== LOG =========================================
#my $log_out = "/LOG_archiving.log";
open LOG, "> $log_out";
my $current_fecha = `date`;

print "Running and archiving program, the DATE is: $current_fecha \n";
print "==============================================================\n";
print LOG "This is the LOG file of an archiving process stared on $current_fecha
The porpouse is to organice the HF Radar data from an external hard drive to the CenSite.\n";
print LOG "===================================================================\n\n";
#==============================================================================

#==============================================================================
print color 'green';
print     "!! External hard drive unit(s) to be archived: \n ===>>> @hd \n";
print color 'reset';
#system('df -h');
print "==============================================================\n";
print LOG "External hard drive unit(s) to be archived: \n ===>>> (@hd) \n";
#==============================================================================


#++++++++++++++ cheking existence of $RootCenSite ++++++++++++++++++
#$Dir_mode = 0644;
$Dir_mode = "0755";

$out = mkdir $RootCenSite,0755; #or die "*** Could not make $Dataout: $!";
if ($out ==1) {
	print "The output CenSite folder was created:\n $RootCenSite \n";
	print LOG "The output CenSite folder was created:\n $RootCenSite \n";}
else {
	print "The output CenSite folder exist:\n $RootCenSite \n";
	print LOG "The output CenSite folder exist:\n $RootCenSite \n";
}
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




foreach $Root (@hd) {
	print "\n ==============================================================\n";
	print "!===>>> Working in:\n	$Root \n";
	print LOG "\n===================================================================\n";
	print LOG "!===>>> Working in:\n	$Root \n";
	#print "!!===>>>", ($Root,@Sites), "\n";
	
# OPEN directorie of the year data.
# 	opendir(h_root,$Root) or die "*** Could not open $Root: $!";
# 		@thefiles= sort( readdir(h_root));
# 		
# 		print "Inside $Root, there are the files:\n @thefiles \n";
# 		print LOG "Inside $Root, there are the files:\n @thefiles \n";
# 	closedir(h_root);
	
	# Now we now that someting rxist, well to work!!!.
	opendir(h_root,$Root) or die "*** Could not open $Root: $!";
		next if h_root eq '.' || h_root eq '..' || h_root eq '.DS_Store' || h_root eq '.Spotlight-V100' || h_root eq '.Trashes';
		
		foreach $site_name (sort readdir(h_root)) {
		    
		    # Checking Site by site folder
		    foreach $site (@Sites) {
		    	#next if h_root eq '.' || h_root eq '..' || h_root eq '.DS_Store' || h_root eq '.Spotlight-V100' || h_root eq '.Trashes';
				    	
		    	if ( $site_name eq $site) {
		    		
		    		#$file = "$Root$site"; #Using brute force to do the next line
		    		$RSite =join("/",$Root,$site_name);
		    		
		    		print color 'green';
		    		print     "!!===>>> $RSite \n";
		    		print color 'reset';
		    		print LOG "\n			!!===>>> $RSite \n";
		    		
		    				    				    		
		    		# !!!!!!!!!   I consider that exist just CODAR HF data !!!!!!!!!!!!
					# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					# Lets see what we have in:
		    		dir_walk_CenSite($RSite);
		    		
		    	} # Close the If ($name eq $site)
		    	
		    			    	
		    } # Close For at @Sites
		}
		
	closedir(h_root);
	
	print "\n\n\n\n";


# end of foreach of each external hard drive
}


#==============================================================================
#==============================================================================

my $current_fecha2 = `date`;
print LOG "\n===============================   END   END   ================================\n";
print LOG " This is the end of the LOG file, the end DATE is: $current_fecha2";

# Closing LOG
close LOG;



#==============================================================================
#============================   Subroutiines  =================================


sub dir_walk_CenSite {
	my ($top) = @_;
	my $DIR;
	# Print file or folder.
	# print_dir->($top); # comented to have lest outputs.
	
	if (-d $top) { # file is a directory
		my $file;
		unless (opendir $DIR, $top) {warn "Couldn't open directory $top: $!; skipping. \n";return;}
		while ($file = readdir $DIR) {
			next if $file eq '.' || $file eq '..' || $file eq '.DS_Store' || $file eq '.Spotlight-V100' || $file eq '.Trashes';
			
			$TempFile = join("/",$top,$file);
			if (-f $TempFile ) {
				#@info=stat("$top/$file") or die "No $file: $!";
				#($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $RSite;
			    #print "STAT of $top/$file \n";
			    #print " @info \n";
		    	#print LOG "STAT of $top/$file \n";
			    #print LOG " @info \n";
				
				#%%%%%%%%%%%%%%%%%%%   What to do?   %%%%%%%%%%%%%%%%%%%%%%%%%
				# 1) Name of the file
				# 2) Take out the Kind of file and compare with @DataKind, to make the script faster
				# 3) Check that the files have a size
				# 4) Does the file exist?, just consider the most recent modified files....
				# 5) Does the file is a figure?, check it before start to copy the file
				# 6) Does the source file exist?, Is it the same?
				# 7) Ditto all the filtered files ....
				
			
				# 1) File name
				($base, $dir, $ext) = fileparse("$TempFile",qr{\..*});
				
				# Checking the name before put the file in the apropiated place.
				# Before split, I need to take out the kind of file,
				#		because the old radial file does not have a separation (underscore o _)
				#		between the kind of file and the sitename.
				my @sparse_base = split("_",$base);
				# counnting the number of sparse block
				$c=0;foreach (@sparse_base) { $c=$c+1;}
				#print ">>>> $base [$ext]\n";
				
				
				# MCR files:
				($base_mcr, $dir_mcr) = fileparse("$TempFile");
				#my @mcr_base1 = split("_",$base);
				#my @mcr_base2 = split(/([.])/,$base_mcr);
				# All the MCR files have the word Chan and also are separated in 4 blocks, with
				# "." or "_", the extension does not matter.
				if (($base_mcr =~ s/Chan/Chan/) || ($base_mcr =~ s/RadarData/RadarData/) || ($base_mcr =~ s/CalibFilesLog/CalibFilesLog/) ) {
				$c =4; #print "$base_mcr \n";
				}
				
				
				
				# 2) The Kind of file to process ....
				# The recent format, normally it have extension,
				# like: RDLi_MLNG_03_01_03_1000.ruv, here exist 6 bloks separated by "_".
				if ($c == 6) {
					#my @sparse_base = split("_",$base);
					# Taking the first element to compare
    				# Kind of file
   					$kind = shift(@sparse_base);
   					#$kind = ucfirst($kind); # I will just make UPPEr case the name of the folder, not the file name
   					# Site name
   					$SiteName = shift(@sparse_base);
	   				# TimeFolder, In Unix can not obtain the creation time of a file.
    				# instead I will use the time name tag at the file name.
    				$YYYY = shift(@sparse_base);
    				#if ($YYYY =~ $RE{num}{real}) {print "$YYYY <<<< \n";exit;}
    				if ($YYYY > "90" && $YYYY <= "99") { $YYYY = "19$YYYY"; }
    				if ($YYYY <= "09") { $YYYY = "20$YYYY";	}
   					$MM = shift(@sparse_base);
   					$DD = shift(@sparse_base);
   					$HH = shift(@sparse_base);
   					$mm = substr($HH,2,2);
   					$HH = substr($HH,0,2);
	    			$TimeFolder = join("_",$YYYY,$MM);    								
				}
				
				
				# The old format, normally it does not have extension,
				# like: ruvsMLNG_03_01_03_1000, here exist 5 bloks separated by "_".
				# Also the STAT files go here
				if ($c==5) {
					if ($ext eq ".hdt" || $ext eq ".rdt" || $ext eq ".rdt.new") {
						# it will consider the STAT files: 5 bloks = STAT_BIGC_YYYY_MM_DD.hdt
						#my @sparse_base = split("_",$base);
						#print "@sparse_base \n\n\n";
						# Taking the first element to compare Kind of file
   						$kind = shift(@sparse_base);
   						#$kind = ucfirst($kind); # I will just make UPPEr case the name of the folder, not the file name
	   					# Site name
   						$SiteName = shift(@sparse_base);
	   					# TimeFolder, In Unix can not obtain the creation time of a file.
    					# instead I will use the time name tag at the file name.
    					$YYYY = shift(@sparse_base);
	    				if ($YYYY > "90" && $YYYY <= "99") { $YYYY = "19$YYYY"; }
    					if ($YYYY <= "09") { $YYYY = "20$YYYY";	}
   						$MM = shift(@sparse_base);
   						$DD = shift(@sparse_base);
   						$TimeFolder = join("_",$YYYY,$MM);
	    				
	    			} else {
						# it will exclude the STAT files from here
						# Kind of file
						$kind = substr( $base,0,4);
	   					#my @sparse_base = split("_",$base);
   						#print "@sparse_base\n";
    					# Taking the first element to compare
    					# Site name
	   					$SiteName = shift(@sparse_base);
		   				$SiteName =substr( $SiteName,4,4);
   						# TimeFolder, In Unix can not obtain the creation time of a file.
   						# instead I will use the time name tag at the file name.
   						$YYYY = shift(@sparse_base);
		    			if ($YYYY > "90" && $YYYY <= "99") { $YYYY = "19$YYYY"; }
    					if ($YYYY <= "09") { $YYYY = "20$YYYY";	}
   						$MM = shift(@sparse_base);
   						$DD = shift(@sparse_base);
   						$HH = shift(@sparse_base);
	   					$HH = substr($HH,0,2);
   						$TimeFolder = join("_",$YYYY,$MM);
   						#print "La extension es: $base [$ext] \n";   						
   						
				}}
				
				# Section that will organice the MCR files. there are 3 differents MCR files at lease.
				# Working in the MCR option.
				# Skipped at this moment........
				if ($c==4) {
					print color 'Red'; print ">>>>>>>>>>>> MCR file ... Working progress ... $base_mcr\n"; print color 'reset';
					
					
					
					@sparse_mcr = split("_",$base_mcr);
					$cc=0;foreach (@sparse_mcr) { $cc=$cc+1;}
					if ($cc > 1) {
						#( $sparse_mcr[2] eq qr{\Chan\d+}) {
						print "MCR like CODAR structure: <@sparse_mcr> \n";
					} else {
				
						# Time Info				
						($Times = $base_mcr) =~ /CB./g ;
						$_ = $base_mcr;
						# extracting the name of the file, to obtain the name of the folder to archive.
						while (/(CB)/gc) { #(/(\d+)/gc) {
							$pp = pos($_);
							$TempName = substr($_,0,$pp);
							$Kind = ucfirst(substr($TempName,0,3));
							
							print "Found $1 Pos:$pp <$TempName> <$Kind>\n";
						}
					}
					
					#print "MCR==>$dir_mcr  \t$base_mcr \t$Times \n";
					# jumping to the next file, because the MCR file is going to be copy by other program
					next;
				}
				
				
				#print "c==$c | $kind | $SiteName | $TimeFolder | [$ext] \n";
								
				# $$$$$ preparing to copy some @DataKind file $$$$$$$
		    	# What to copy?
			    my $Source = join("",$dir,$base,$ext);
				
				print color 'Yellow';
		    	print " !!!! Processing File: $Source ...\n";
		    	print color 'reset';
		    	
		    	
		    	
		    	
		    	# 3) Check that the source file have more than 0 bites, it prevents future
		    	# errors with finder (see Finder -36 error)
		    	if (-z $Source) {
		    		print color 'red';
		    		print "000 The file $Source has Cero bites, it WILL NOT be archived... \n";
		    		print color 'reset';
		    		print LOG " 000 The file $Source has Cero bites, it WILL NOT be archived... \n";
		    	} else {
		    		
		    		
		    		#    We have real data files !!!!!!!!!!!!!
		    		# 4) Check that the file does not exist in the destination directory,
		    		#		if it exist, it will considerr the newest file.
		    		#    Where to copy?
		    		my $Destination = join("/",$RootCenSite,$SiteName,$kind,$TimeFolder);
			    	
			    	
			    	
			    	# 5) Checking the existence of figures, to copy it to the apropiate place.
			    	foreach $temp_ext (@FigExt) {
			    		if ($ext eq ".$temp_ext") {
			    			$Destination = join("/",$RootCenSitePlot,$SiteName,$kind,$TimeFolder);
			    			#print "===>>> $file \n $Source \n $Destination ||| $YYYY | $MM <<<== \n"; exit;
			    	}}
		    		
		    		
		    		# 6) Checking if the source file exist in the destination directory:
			    	#    If the file exist it will be overwrited just if the modifided time
			    	#    is the same or older than the new one.
		    		
		    		# Check if the Destination file exits ....
		    		my $DestinyFile = "$Destination/$base$ext";
		    		
		    		if (-e $DestinyFile) {
		    			print color 'yellow';
			    		print "     The file $Source exist .... \n";
		    			print color 'reset';
			    		print LOG "     The file $Source exist .... \n";
		    			
		    			# Stating the destiny file
		    			#@DInfo = stat($DestinyFile) or die "No $DFile: $!";
		    			# print " @Info \n @DInfo \n";
		    			
		    			# The file exist, but it is the same?
		    			# using File:Compare: it give me 0 is the files are equal and 1 is not.
		    			if (compare($Source, $DestinyFile) == 0) {
		    				print color 'yellow';
			    			print "     Will not overwrite, is the same file ... skipped\n";
			    			print color 'reset';
			    			print LOG "     Will not overwrite, is the same file ... skipped\n";
			    	
			    		#	print -f $DestinyFile, "\n";
			    		} else {
			    		# The file is not the same, so is a new one?
			    		
			    			#if ( '@Info[9]' > '@DInfo[9]' ) {
				    		if ( (-M $Source) < (-M $DestinyFile) ) {
				    			print "     Respect to Today date, the file $Source is ", (-M $Source), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will be rewrited to have the new one.\n";
				    			print LOG "     Respect to Today date, the file $Source is ", (-M $Source), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will be rewrited to have the new one.\n";
				    			
			    				system "ditto -rsrc -v $Source $Destination/";
			    				print LOG "*** Coping $Source  to $Destination \n";
			    			
				    		} else {
				    			print "     Respect to Today date, the file $Source is ", (-M $Source), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will Not be copy is an old file... skipped\n";
				    			print LOG "     Respect to Today date, the file $Source is ", (-M $Source), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will Not be copy is an old file... skipped\n";
				    			
			    			} # end of if-else to check the newest file
			    		} # end of if-else that tell us that the file are not the same
		    				
		    		} else {
		    			# The file is New, just ditto it.
		    			system "ditto -rsrc -v $Source $Destination/";
 						print LOG "*** Coping $Source  to $Destination \n";		    						    				
		    		}		    		
		    	#return;
		    	#exit;
		    	} # end of if-else to check that the file does not has a size of Cero bites
			} # end foreach Codar data files
			
			dir_walk_CenSite("$top/$file");
		}
	} # close if	
} # close dir_walk



###########################################################
#################  Subroutines ############################
sub dir_walk {
	my ($top, $code) = @_;
	my $DIR;
	
	$code->($top);
	
	if (-d $top) {
		my $file;
		unless (opendir $DIR, $top) {
			warn "Couldn't open directory $top: $!; skipping. \n";
			return;
		}
		while ($file = readdir $DIR) {
			next if $file eq '.' || $file eq '..' || $file eq '.DS_Store';
			dir_walk("$top/$file", $code);
		}
	} # close if	
} # close dir_walk



# with option for plain files and directories.
sub dir_walkG {
	my ( $top, $filefunc, $dirfunc) = @_;
	my $DIR;
	
	if (-d $top) {
		my $file;
		unless (opendir $DIR, $top) {
			warn "Couldn't open directory $code: $!; skipping. \n";
			return;
		}
		
		my @results;
		while ($file = readdir $DIR) {
			next if $file eq '.' || $file eq '..' || $file eq '.DS_Store';
			push @results, dir_walkG("$top/$file", $filefunc, $dirfunc);
		}
		return $dirfunc->($top, @results);
	}
	else {
		return $filefunc->($top);
	}
}




sub print_dir {
	print $_[0], "\n";
	if ( defined(LOG) ) {
		print LOG $_[0], "\n";
	}
}


sub file_size { -s $_[0] }


sub dir_size {
	my $dir = shift;
	my $total = -s $dir;
	my $n;
	for $n (@_) { $total += $n }
	printf "%6d %s \n", $total, $dir;
	return $total;
}



sub dir {
	my ($dir, @subdirs) = @_;
	my %new_hash;
	for (@subdirs) {
		my ($subdir_name, $subdir_struc) = @$_;
		$new_hash{$subdir_name} = $subdir_struc;
	}
	return [short($dir), \%new_hash];
}





sub extension{
	my $path = shift;
	my $ext = (fileparse($path,'\..*'))[2];
	$ext =~ s/^\.//;
	return $ext;
	
	print color 'red';
	print " The extension is: $ext \n";
	print color 'reset';
		    
}
















