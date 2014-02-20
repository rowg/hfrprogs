### Makefile - principally installs external matlab packages, but
### could do other things in the future
#
# To use (examples):
#
# make - downloads packages and then unpacks them
# make clean - removes packages and package directories
# make clean_packages - removes just packages
# make all_openMA - downloads openMA package, unpacks openMA package
#
# NOTE: This Makefile will not download a package if it has already
# been downloaded (though it will unpack the package even if that
# package already exists if the timestamp on the unpacked package
# (i.e. package directory) is older than the downloaded file).  To
# replace an existing download of a package, it must first be removed,
 
FILESEP=/

# The netcdf location can be overridden by environmental variables.
# Make sure to set this correctly before compiling mexnc
NETCDF?=/usr

# Directories
INSTALLDIR=.
MATLABDIR=$(INSTALLDIR)$(FILESEP)matlab
EXTERNALMATLABDIR = $(MATLABDIR)$(FILESEP)external_matlab_packages

# Programs - change to appropriate function for your OS
#
# Can also be specified on command line or in environment, in which case
# they will override the values below.
WGET ?= wget
TOUCH ?= touch
TAR ?= tar
UNZIP ?= unzip
RM ?= rm
LN ?= ln
MKDIR ?= mkdir
SED ?= sed
CD ?= cd
CP ?= cp
MAKE ?= make
ECHO ?= echo


# This variable contains a list of targets - separate by whitespace -
# that are installed by default by a simple "make"
TARGETS=openMA t_tide m_map arrow


# Autogenerate these targets from list
# NOTE: not all of them are currently used.
DOWNLOADTARGETS=$(addprefix download_,$(TARGETS))
UPLOADTARGETS=$(addprefix upload_,$(TARGETS))
CLEANPACKAGESTARGETS=$(addprefix clean_package_,$(TARGETS))
CLEANFILESTARGETS=$(addprefix clean_files_,$(TARGETS))
UNPACKTARGETS=$(addprefix unpack_,$(TARGETS))
ALLTARGETS=$(addprefix all_,$(TARGETS))
CLEANTARGETS=$(addprefix clean_,$(TARGETS))

# General targets
all: download_packages unpack_packages
#all: $(ALLTARGETS)

clean: clean_packages clean_files
#clean: $(CLEANTARGETS)

all_leave_packages: download_packages unpack_packages

download_packages: $(DOWNLOADTARGETS)
unpack_packages: $(UNPACKTARGETS)
clean_packages: $(CLEANPACKAGESTARGETS)
clean_files: $(CLEANFILESTARGETS)

##################################################
# OpenMA stuff
##################################################
OPENMA_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)openMA.latest.tar.gz
OPENMA_DIR=$(EXTERNALMATLABDIR)$(FILESEP)openMA

all_openMA: download_openMA unpack_openMA
clean_openMA: clean_package_openMA clean_files_openMA

download_openMA: $(OPENMA_PACKAGE)
$(OPENMA_PACKAGE):
	[ -e $(OPENMA_PACKAGE) ] || \
	$(WGET) http://www.ur097.ird.fr/team/dkaplan/software/openMA/files/openMA.latest.tar.gz -P $(EXTERNALMATLABDIR)

unpack_openMA: $(OPENMA_DIR)
$(OPENMA_DIR): $(OPENMA_PACKAGE)
	$(TAR) -zxvf $(OPENMA_PACKAGE) -C $(EXTERNALMATLABDIR)
	$(TOUCH) $(OPENMA_DIR) # Touching this directory makes date newer than zip

clean_package_openMA:
	-$(RM) $(OPENMA_PACKAGE)

clean_files_openMA:
	-$(RM) -Rf $(EXTERNALMATLABDIR)$(FILESEP)openMA

##################################################
# t_tide stuff
##################################################
T_TIDE_DIR=$(EXTERNALMATLABDIR)$(FILESEP)t_tide_v1.1
T_TIDE_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)t_tide_v1.1.zip

all_t_tide: download_t_tide unpack_t_tide
clean_t_tide: clean_package_t_tide clean_files_t_tide

download_t_tide: $(T_TIDE_PACKAGE)
$(T_TIDE_PACKAGE):
	[ -e $(T_TIDE_PACKAGE) ] || \
	$(WGET) http://www.eos.ubc.ca/%7Erich/t_tide/t_tide_v1.1.zip -P $(EXTERNALMATLABDIR)

unpack_t_tide: $(T_TIDE_DIR)
$(T_TIDE_DIR): $(T_TIDE_PACKAGE)
	$(MKDIR) $(T_TIDE_DIR)
	$(UNZIP) $(T_TIDE_PACKAGE) -d $(T_TIDE_DIR)$(FILESEP)
	$(TOUCH) $(T_TIDE_DIR) # Touching this directory makes date newer than zip

clean_package_t_tide:
	-$(RM) $(T_TIDE_PACKAGE)

clean_files_t_tide:
	-$(RM) -Rf $(T_TIDE_DIR)

##################################################
# m_map stuff
##################################################
M_MAPDIR=$(EXTERNALMATLABDIR)$(FILESEP)m_map
M_MAP_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)m_map1.4.tar.gz

all_m_map: download_m_map unpack_m_map
clean_m_map: clean_package_m_map clean_files_m_map

download_m_map: $(M_MAP_PACKAGE) 
$(M_MAP_PACKAGE):
	[ -e $(M_MAP_PACKAGE) ] || \
	$(WGET) http://www.eos.ubc.ca/%7Erich/m_map1.4.tar.gz -P $(EXTERNALMATLABDIR)

unpack_m_map: $(M_MAPDIR)
$(M_MAPDIR): $(M_MAP_PACKAGE) 
	$(TAR) -zxvf $(M_MAP_PACKAGE) -C $(EXTERNALMATLABDIR)
	$(TOUCH) $(M_MAPDIR) # Touching directory makes it newer than .tar.gz

clean_package_m_map:
	-$(RM) $(M_MAP_PACKAGE)

clean_files_m_map:
	-$(RM) -Rf $(M_MAPDIR)

##################################################
# arrow stuff - this is just a single file, so simple
##################################################
ARROW_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)arrow.m

all_arrow: download_arrow unpack_arrow
clean_arrow: clean_package_arrow clean_files_arrow

download_arrow: $(ARROW_PACKAGE) 
$(ARROW_PACKAGE):
	[ -e $(ARROW_PACKAGE) ] || \
	$(WGET) http://www.mathworks.com/matlabcentral/files/278/arrow.m -P $(EXTERNALMATLABDIR)

# This is just here for consistency
unpack_arrow: $(ARROW_PACKAGE)

clean_package_arrow:
	-$(RM) $(ARROW_PACKAGE)

# This is just here for consistency
clean_files_arrow:
	-$(RM) $(ARROW_PACKAGE)

##################################################
# This gets high res coastline for m_map
# NOTE: this is not done by default
#       needs to be called with a separate "make all_gshhs"
##################################################
GSHHS_DIR=$(M_MAPDIR)$(FILESEP)private
GSHHS_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)gshhs_1.10.zip

all_gshhs: download_gshhs unpack_gshhs
clean_gshhs: clean_package_gshhs clean_files_gshhs

download_gshhs: $(GSHHS_PACKAGE)
$(GSHHS_PACKAGE):
	[ -e $(GSHHS_PACKAGE) ] || \
	$(WGET) http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version1.10/gshhs_1.10.zip  -P $(EXTERNALMATLABDIR)

unpack_gshhs: $(GSHHS_PACKAGE) $(M_MAPDIR)
	$(UNZIP) $(GSHHS_PACKAGE) -d $(GSHHS_DIR)$(FILESEP)
	$(TOUCH) $(GSHHS_DIR)$(FILESEP)gshhs* # Touching these files makes date newer than zip

clean_package_gshhs:
	-$(RM) -f $(GSHHS_PACKAGE)

clean_files_gshhs:
	-$(RM) -f $(GSHHS_DIR)$(FILESEP)gshhs*

##################################################
# This gets Sandwell & Smith global bathymetry
# NOTE: this is not done by default
#       needs to be called with a separate "make all_SandBath"\
# NOTE: this section requires sed to modify an m_file to work
##################################################
SANDBATH_DIR=$(EXTERNALMATLABDIR)$(FILESEP)SandBath
SANDBATH_IMG_FN=topo_8.2.img
SANDBATH_IMG=$(SANDBATH_DIR)$(FILESEP)$(SANDBATH_IMG_FN)
SANDBATH_MFILE=$(SANDBATH_DIR)$(FILESEP)mygrid_sand.m

all_SandBath: download_SandBath edit_SandBath_mfile
clean_SandBath: clean_files_SandBath

download_SandBath: $(SANDBATH_IMG) $(SANDBATH_MFILE)
$(SANDBATH_DIR):
	-$(MKDIR) -p $(SANDBATH_DIR)

$(SANDBATH_IMG): $(SANDBATH_DIR)
	[ -e $(SANDBATH_IMG) ] || \
	$(WGET) ftp://topex.ucsd.edu/pub/global_topo_2min/$(SANDBATH_IMG_FN) -P $(SANDBATH_DIR)
$(SANDBATH_MFILE): $(SANDBATH_DIR)
	[ -e  $(SANDBATH_MFILE) ] || \
	$(WGET) ftp://topex.ucsd.edu/pub/global_topo_2min/matlab/mygrid_sand.m -P $(SANDBATH_DIR)

# Sets mygrid_sand.m so that it will look for database in the same
# directory as the mfile itself.
edit_SandBath_mfile: $(SANDBATH_MFILE)
	$(CP) $(SANDBATH_MFILE) $(SANDBATH_MFILE).orig
	$(SED) "s/^DatabasesDir *= *[^;]*/DatabasesDir=fileparts(mfilename('fullpath'))/" $(SANDBATH_MFILE).orig > tmp_SANDBATH.m
	$(SED) "s/topo_[0-9]\.[0-9]\.img/$(SANDBATH_IMG_FN)/g" tmp_SANDBATH.m > $(SANDBATH_MFILE)
	$(RM) tmp_SANDBATH.m

clean_SandBath_mfile:
	-$(RM) $(SANDBATH_MFILE)

clean_files_SandBath:
	-$(RM) -f $(SANDBATH_DIR)

##################################################
# mexnc stuff - not done by default - call with a separate "make all_mexnc"
# NOTE: for netcdf to work you need to dowload the mexnc stuff AND
# the netcdf toolbox.  Neither is done by default.  
#
# NOTE: This downloads and unpacks mexnc, but doesn't try to compile it.  
#       you shouldn't if you have a mac or pc running windows, not sure about linux.
#       This download seems to be updated frequently, and therefore the file
#       below my need to be updated frequently.
#       See the download page for more information, at:
#       http://mexcdf.sourceforge.net/index.html
##################################################
MEXNCDIR=$(EXTERNALMATLABDIR)$(FILESEP)mexnc
MEXNCPACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)mexnc.R2007b-2.0.29.tar.gz

all_mexnc: download_mexnc unpack_mexnc
clean_mexnc: clean_package_mexnc clean_files_mexnc

download_mexnc: $(MEXNCPACKAGE)
$(MEXNCPACKAGE):
	[ -e $(MEXNCPACKAGE) ] || \
	$(WGET) http://superb-east.dl.sourceforge.net/sourceforge/mexcdf/mexnc.R2007b-2.0.29.tar.gz -P $(EXTERNALMATLABDIR)

# http://downloads.sourceforge.net/mexcdf/mexnc-2.0.20.0.tar.gz?modtime=1158757813&big_mirror=0
# The above URL gets mexnc, but suffers from redirect problems that don't mesh well with make.

unpack_mexnc: $(MEXNCDIR)
$(MEXNCDIR): $(MEXNCPACKAGE) 
	$(TAR) -zxvf $(MEXNCPACKAGE) -C $(EXTERNALMATLABDIR)
	$(TOUCH) $(MEXNCDIR) # Touching directory makes it newer than .tar.gz

clean_package_mexnc:
	-$(RM) $(MEXNCPACKAGE)

clean_files_mexnc:
	-$(RM) -Rf $(MEXNCDIR)

##################################################
# This tries to compile mexnc library.  Probably don't have to do this
# if you have a common os (mac OS X or windohz, not sure about linux)
# NETCDF variable must be set to location of library for this to work.
##################################################
# This command creates a version of NETCDF variable with slashes protected.
NETCDFFIX=$(shell $(ECHO) $(NETCDF) | $(SED) 's/\//\\\//g')

compile_mexnc: $(MEXNCDIR) 
	$(CD) $(MEXNCDIR); $(CP) mexopts.sh mexopts.sh.orig
	$(CD) $(MEXNCDIR); $(SED) 's/NETCDF="[^"]*"/NETCDF="$(NETCDFFIX)"/' mexopts.sh.orig > mexopts.sh
	$(CD) $(MEXNCDIR); $(MAKE)

##################################################
# Chuck Denham's matlab netcdf toolbox - not done by default - call with a 
# separate "make all_netcdf"
# NOTE: for netcdf to work you need to dowload this netcdf toolbox AND
# the mexnc stuff.  Neither is done by default.  
##################################################
NETCDF_DIR=$(EXTERNALMATLABDIR)$(FILESEP)netcdf_toolbox
NETCDF_PACKAGE=$(EXTERNALMATLABDIR)$(FILESEP)netcdf_toolbox-1.0.12.tar.gz

all_netcdf: download_netcdf unpack_netcdf
clean_netcdf: clean_package_netcdf clean_files_netcdf

download_netcdf: $(NETCDF_PACKAGE) 
$(NETCDF_PACKAGE):
	[ -e $(NETCDF_PACKAGE) ] || \
	$(WGET) http://superb-east.dl.sourceforge.net/sourceforge/mexcdf/netcdf_toolbox-1.0.12.tar.gz -P $(EXTERNALMATLABDIR)

unpack_netcdf: $(NETCDF_DIR)
$(NETCDF_DIR): $(NETCDF_PACKAGE) 
	$(TAR) -zxvf $(NETCDF_PACKAGE) -C $(EXTERNALMATLABDIR)
	$(TOUCH) $(NETCDF_DIR) # Touching directory makes it newer than .tar.gz

clean_package_netcdf:
	-$(RM) $(NETCDF_PACKAGE)

clean_files_netcdf:
	-$(RM) -Rf $(NETCDF_DIR)

