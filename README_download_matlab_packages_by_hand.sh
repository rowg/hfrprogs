#!/bin/sh

# README Explaining how to install by hand external matlab packages

# If you are using a Windows machine or Mac OSX machine that does not
# have installed the tools needed for using the Makefile to
# automatically install the external matlab packages needed by
# HFR_Progs, then you will need to install them by hand.  This README
# provides basic instructions for doing so.  This file is also a Bash
# script that can be used to install the most important packages in
# lieu of using the Makefile, but the Makefile is more powerful and is
# preferred if your machine is capable of using it.  Also, the
# Makefile should be up to date, but this file may become out of date
# with time.

# The following toolboxes or m_files are used by HFR_Progs:

# m_map, openMA, t_tide, arrow.m, mexnc (roughly in order of importance)

# All but m_map are somewhat optional, though certain aspects of the
# toolbox may not function is you do not install the full suite of
# external packages.

# You may also wish to install high resolution coastlines and
# bathymetry for use with M_map:

# gshhs (recommended for full functionality), Sandwell & Smith Bathymetry

# To install these, you will need to download them from their
# respective websites, following the installation instructions for
# each site.  The packages will need to be unpacked somewhere that is
# on the Matlab path.  The HFR_Progs/matlab/external_matlab_packages
# directory is a convenient place where the packages will be
# automatically placed on the Matlab path if the matlab/startup.m
# script is used.

# Below is a list of websites that contain installation instructions
# for each package:

# M_map: http://www.eos.ubc.ca/~rich/map.html
# openMA: https://cencalarchive.org/~cocmpmb/cocmp-wiki/index.php/Documentation:OpenMA_Matlab_Toolbox
# T_tide: http://www.eos.ubc.ca/~rich/#T_Tide
# arrow.m: http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=278
# mexnc: http://mexcdf.sourceforge.net/index.html
# gshhs: http://www.eos.ubc.ca/~rich/private/mapug.html#p9.5
# Sandwell & Smith Bathymetry: http://www.eos.ubc.ca/~rich/private/mapug.html#p8.1

# Below is a script that should work on *nix systems with Bash installed:

##################################################
# Some base directories - edit these as needed
##################################################
FILESEP=/
INSTALLDIR=.
MATLABDIR=${INSTALLDIR}${FILESEP}matlab
EXTERNALMATLABDIR=${MATLABDIR}${FILESEP}external_matlab_packages

mkdir -p ${EXTERNALMATLABDIR}

##################################################
# m_map stuff
##################################################
M_MAPDIR=${EXTERNALMATLABDIR}${FILESEP}m_map
M_MAP_PACKAGE=${EXTERNALMATLABDIR}${FILESEP}m_map1.4.tar.gz

wget http://www.eos.ubc.ca/%7Erich/m_map1.4.tar.gz -P ${EXTERNALMATLABDIR}
tar -zxvf ${M_MAP_PACKAGE} -C ${EXTERNALMATLABDIR}

##################################################
# OpenMA stuff
##################################################
OPENMA_PACKAGE=${EXTERNALMATLABDIR}${FILESEP}openMA.latest.tar.gz
OPENMA_DIR=${EXTERNALMATLABDIR}${FILESEP}openMA

wget http://www.ur097.ird.fr/team/dkaplan/software/openMA/files/openMA.latest.tar.gz -P ${EXTERNALMATLABDIR}
tar -zxvf ${OPENMA_PACKAGE} -C ${EXTERNALMATLABDIR}

##################################################
# t_tide stuff
##################################################
T_TIDE_DIR=${EXTERNALMATLABDIR}${FILESEP}t_tide_v1.1
T_TIDE_PACKAGE=${EXTERNALMATLABDIR}${FILESEP}t_tide_v1.1.zip

wget http://www.eos.ubc.ca/%7Erich/t_tide/t_tide_v1.1.zip -P ${EXTERNALMATLABDIR}
unzip ${T_TIDE_PACKAGE} -d ${T_TIDE_DIR}${FILESEP}

##################################################
# arrow stuff - this is just a single file, so simple
##################################################
ARROW_PACKAGE=${EXTERNALMATLABDIR}${FILESEP}arrow.m

wget http://www.mathworks.com/matlabcentral/files/278/arrow.m -P ${EXTERNALMATLABDIR}

##################################################
# GSHHS is commented out by default because files are
# large and take a long time to download, but installing
# this is HIGHLY recommended for basic functioning 
# of the toolbox.
##################################################

# ##################################################
# # GSHHS stuff
# ##################################################
# GSHHS_DIR=${M_MAPDIR}${FILESEP}private
# GSHHS_PACKAGE=${EXTERNALMATLABDIR}${FILESEP}gshhs_1.3.zip

# wget http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version1.5/gshhs_1.3.zip  -P ${EXTERNALMATLABDIR}
# unzip ${GSHHS_PACKAGE} -d ${GSHHS_DIR}${FILESEP}
