#!/usr/bin/perl -w

# Per Scrip to copy files from the Web Server to
# the Archive Server into the RAID array.

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
@hd = qw{ /Volumes/HD1/HFR/CenSite/Data };

# Directorie trajectorie in wich the Script will archive the data.
$RootCenSite     = '/Volumes/HDR/HFR_Archive/Data';
$RootCenSitePlot = '/Volumes/HDR/HFR_Archive/Plots';

@Sites      = sort(qw/BIGC GCYN LMLS MLNG NPGS PESC PPIN PSUR SCRZ COMM FORT MONT/);
@SiteFolder = sort(qw/RDLi RDLm STAT Wave Waves WVLM WVLS/);
@DataExt        = sort(qw/cs cs4 hdt ruv rdt rs wl4 wl5 wv4/);
@FigExt        = sort(qw/jpg pic gif/);

# the log file will be appended with the Time info at the moment of run the script.
my $log_out = "/Volumes/HDR/HFR_Archive/Logs/Archiver/PERL/Web2Archive/Rad_Web2Archive";
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

#exit; # just check trajectories ...

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
		    		
		    		
		    				    		
		    		#@info=stat($RSite) or die "No $RSite: $!";		    		
		    		#($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $RSite;
		    		
		    		#print "STAT of $RSite \n";
		    		#print " @info \n";
		    		#print " $info[7] \n";
		    		#print LOG "STAT of $RSite \n";
		    		#print LOG " @info \n";
		    		
					
					# !!!!!!!!!!!!!!!!!   So we have CODAR HF data !!!!!!!!!!!!!!!!!!!!
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
		unless (opendir $DIR, $top) {
			warn "Couldn't open directory $top: $!; skipping. \n";
			return;
		}
		while ($file = readdir $DIR) {
			next if $file eq '.' || $file eq '..' || $file eq '.DS_Store' || $file eq '.Spotlight-V100' || $file eq '.Trashes';
					
			
			#@info=stat("$top/$file") or die "No $file: $!";
			#($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $RSite;
		    #print "STAT of $top/$file \n";
		    #print " @info \n";
		    #print LOG "STAT of $top/$file \n";
		    #print LOG " @info \n";
			
			
			# File name
			($base, $dir, $ext) = fileparse("$top/$file",'\..*');
			#print "$base \n $dir \n $ext \n";
			
			#print color 'red';
		    #print " === File: $dir  $base, with extension : $ext \n";;
		    #print color 'reset';
		    						
			#print " === File: $dir  $base, with extension : $ext \n";
			#return \($base, $dir, $ext, @info);
			
			
			
			
			# Work with Configs folders, ... not yet ....
			
			# Work with jpg files, but just from RDLi

			
			
			
			# Work with the extension of the files, see @DataExt at the Input variables section.			
			# So, lets go to copy the files to a corresponding directorie structure,
			# it will use ditto.
			foreach $temp_ext (@DataExt) {
				if ($ext eq ".$temp_ext") {
		    		print color 'yellow';
		    		#print " !!!! Processing File: $dir  $base, with extension : $ext \n";
		    		print " !!!! Processing File: $dir$base$ext \n";
		    		print color 'reset';
		    		
		    		
		    		# $$$$$ preparing to copy some @DataExt kind file $$$$$$$
		    		# What to copy?
		    		my $Source = join("",$dir,$base,$ext);
		    		
		    		# Check that the source file have more than 0 bites, it prevents future
		    		# errors with finder (see Finder -36 error)
		    		if (-z $Source) {
		    			print color 'red';
		    			print "000 The file $Source has Cero bites, it WILL NOT be archived... \n";
		    			print color 'reset';
		    			print LOG " 000 The file $Source has Cero bites, it WILL NOT be archived... \n";
		    		} else {
		    			# We have real data files !!!!!!!!!!!!!
			    		# Where to copy?
			    		# checking the name before put the file in the apropiated place.
			    		my @sparse_base = split("_",$base);
		    			# Taking the first element to compare
		    			# Kind of file
		    			my $kind = shift(@sparse_base);
			    		# Site name
			    		$Sitename = shift(@sparse_base);
		    			# TimeFolder, In Unix can not obtain the creation time of a file.
		    			# instead I will use the time name tag at the file name.
			    		$YYYY = shift(@sparse_base);
			    		if ($YYYY <= "09") {
			    			$YYYY = "20$YYYY";
		    			}	    				
		    			$MM = shift(@sparse_base);
		    			$TimeFolder = join("_",$YYYY,$MM);
			    		
			    		
			    		
			    		# Porcess the current month ... add on october 26 2006
			    		if ("$MM" eq "$mo") {
			    		
			    					    		
				    		my $Destination = join("/",$RootCenSite,$Sitename,$kind,$TimeFolder);
				    		#print "===>>> $file \n $Source \n $Destination ||| $YYYY | $MM <<<== \n";
			    			
		    				
		    				# Checking if the source file exist in the destination directory:
			    			# If the file exist it will be overwrited just if the modifided time
			    			# is the same or older than the new one.
			    			#if ($fileDestination = readdir $DIR) eq 1 {
	
			    			
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
		    					
		    					# the file exist, but it is the same?
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
				    					
				    				}			    			
				    			}		    					    				
			    				
			    			} else {
		    					# Thge file is New, just ditto it.
		    					system "ditto -rsrc -v $Source $Destination/";
 								print LOG "*** Coping $Source  to $Destination \n";		    						    				
		    				}
		    			
		    			} # end of the if that will check just files from the current month .....
		    			
		    		} # end of the ELSE		    				  		
		    		#exit;		    			    		
		    	}	# exit if Extension for Codar data files
			} # end foreach Codar data files
			
			
			
			
			
			
			
			# FIGURES ============================================
			# Work with the extension of the files, see @ExtFig at the Input variables section.			
			# So, lets go to copy the files to a corresponding directorie structure,
			# it will use ditto.
			foreach $temp_ext (@FigExt) {
				if ($ext eq ".$temp_ext") {
					# We have a figure, but what if it is not a valid figure?, checking ...
					my @sparse_baseFig = split("_",$base); $Sitename = shift(@sparse_baseFig);
										
					foreach $KindFig (@SiteFolder) {
						if ($KindFig eq $Sitename) {
							
							print color 'yellow';
							#print " !!!! Processing File: $dir  $base, with extension : $ext \n";
				    		print " !!!! Processing File: $dir$base$ext \n";
				    		print color 'reset';
				    		
				    		
				    		# $$$$$ preparing to copy some @FigExt kind file $$$$$$$
				    		# What to copy?
				    		my $SourceFig = join("",$dir,$base,$ext);
				    		
		    				# Check that the source file have more than 0 bites, it prevents future
				    		# errors with finder (see Finder -36 error)
				    		if (-z $SourceFig) {
		    						print color 'red';
					    			print "000 The file $SourceFig has Cero bites, it WILL NOT be archived... \n";
		    						print color 'reset';
		    						print LOG " 000 The file $SourceFig has Cero bites, it WILL NOT be archived... \n";
				    		} else {
					    			# We have real data files !!!!!!!!!!!!!
			    					# Where to copy?
						    		# checking the name before put the file in the apropiated place.
						    		my @sparse_baseFig = split("_",$base);
		    						# Taking the first element to compare
					    			# Kind of file
		    						my $kindFig = shift(@sparse_baseFig);
			    					# Site name
						    		my $SitenameFig = shift(@sparse_baseFig);
		    						# TimeFolder, In Unix can not obtain the creation time of a file.
		    						# instead I will use the time name tag at the file name.
						    		$YYYY = shift(@sparse_baseFig);
						    		if ($YYYY <= "09") {
			    						$YYYY = "20$YYYY";
					    			}	    				
		    						$MM = shift(@sparse_baseFig);
		    						my $TimeFolder = join("_",$YYYY,$MM);
						    				
						    		my $DestinationFig = join("/",$RootCenSitePlot,$SitenameFig,$kindFig,$TimeFolder);
			    								    					
					    					    			
					    			# Checking if the source file exist in the destination directory:
						    		# If the file exist it will be overwrited just if the modifided time
						    		# is the same or older than the new one.
		    						#if ($fileDestination = readdir $DIR) eq 1 {
		    				    			
			    						
		    						# Check if the Destination file exits ....
		    						my $DestinyFile = "$DestinationFig/$base$ext";
		    						
		    						#print "===>>> $file \n $SourceFig \n $DestinationFig ||| $kindFig -- $YYYY | $MM || $DestinyFile <<<== \n";
					    							    				    						
		    			
		    						if (-e $DestinyFile) {
		    							print color 'yellow';
			    						print "     The file $SourceFig exist .... \n";
		    							print color 'reset';
			    						print LOG "     The file $SourceFig exist .... \n";
		    							
		    							# Stating the destiny file
		    							# the file exist, but it is the same?
		    							# using File:Compare: it give me 0 is the files are equal and 1 is not.
		    							if (compare($SourceFig, $DestinyFile) == 0) {
		    								print color 'yellow';
						    				print "     Will not overwrite, is the same file ... skipped\n";
						    				print color 'reset';
						    				print LOG "     Will not overwrite, is the same file ... skipped\n";
			  			  			
			    						#	print -f $DestinyFileFig, "\n";
			    						} else {
			    						# The file is not the same, so is a new one?
			    						
			    							#if ( '@Info[9]' > '@DInfo[9]' ) {
			    							if ( (-M $SourceFig) < (-M $DestinyFile) ) {
			    								print "     Respect to Today date, the file $SourceFig is ", (-M $SourceFig), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will be rewrited to have the new one.\n";
			    								print LOG "     Respect to Today date, the file $SourceFig is ", (-M $SourceFig), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will be rewrited to have the new one.\n";
			    								
			    								system "ditto -rsrc -v $SourceFig $DestinationFig/";
			    								print LOG "*** Coping $SourceFig to $DestinationFig \n";
			    					
			    							} else {
			    								print "     Respect to Today date, the file $SourceFig is ", (-M $SourceFig), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will Not be copy is an old file... skipped\n";
			    								print LOG "     Respect to Today date, the file $SourceFig is ", (-M $SourceFig), " days old and \n     the $DestinyFile is ", (-M $DestinyFile), " days old.\n     The file will Not be copy is an old file... skipped\n";
			    								
			    							} # end if else
			    						} # end if-else for comparing the files
		    						} else {
		    							# The age file is New, just ditto it.
		    							system "ditto -rsrc -v $SourceFig $DestinationFig/";
 										print LOG "*** Coping $SourceFig  to $DestinationFig \n";		    						    				
		    						} # end if-else for existence of file
				    		} # End of if-else for size of file, more than 0 bites.
		    		
						} else {
						# Another extrange figure, that will not be archived.
						
						} # end of if-else for check that the figures just be valid kind
					} #end foreach kind of figures.


		    	}	# exit if Extension for Codar data files
			} # end foreach Codar data files, check that the extension macth
			
			
			dir_walk_CenSite("$top/$file");
		}
	} # close if	
} # close dir_walk




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
















