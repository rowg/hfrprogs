% Functions in this directory pertain principally to the loading in,
% masking, cleaning and interpolation of HF Radar radial data.  Radial data
% is stored in a uniform structure format that is created by the function
% RADIALstruct.  This RADIAL structure is designed to be uniform enough that
% it provides a standard format for radial data, but flexible enough that it
% can contain additional information that might be particular to one
% instrument or type of radial processing. There are several basic
% assumptions underlying that RADIAL structure format.  These are explained
% below:
%
% 1) In all matrix or vector variables, rows are for space and columns
%    are for time.  For a RADIAL structure with M radial grip points and
%    N timesteps, the fields in the structure should have the following
%    dimensions and types:
%
%           FileName = 1 x N cellstr
%           TimeStamp = 1 x N double
%           LonLat = M x 2 double
%           RangeBearHead = M x 3 double
%           RadComp,Error,Flag,U,V = M x N double
%
% 2) Empty RADIAL structures: At times, functions like loadRDLFile return
%    empty RADIAL structures (e.g. if a file is not found).  For
%    consistency, the sizes of the fields should be maintained as above
%    even if M or N is zero.  For this reason, RADIALstruct (the function
%    that creates an empty RADIAL structure) returns an initial LonLat
%    field, for example, that has size [0,2].  This is still empty, but
%    has the correct number of columns.  This helps when indexing this
%    variable in functions so they don't have to constantly check the
%    size of the fields.
%
% 3) OtherMatrixVars: This is initially empty, but can be a structure
%    containing variables of the same type as RadComp (i.e., they should be
%    two dimensional with size = [Num Spatial Grid Points x Num Time Steps].
%    Some functions, like subsrefRADIAL can optionally deal with the
%    variables inside this structure just like they deal with RadComp.
%
% 4) OtherMetadata: This is initially empty, but can be a free-form
%    structure that contains additional information regarding the data.
%
% 5) Bad or missing data: This should be indicated by an NaN in at least
%    the RadComp field.
%
% 6) Multiple sites: Data from more than one site can be stored in an
%    array of RADIAL structures, one for each site.  Some functions, such
%    as loadRDLFile, can create these arrays of RADIAL structures.
%    Others, such as cleanRadials can process these arrays, while others,
%    such as subsrefRADIAL cannot.
%
% 7) Angle conventions: Angles will be stored in degrees measured
%    counter-clockwise from east.  Bearing is the direction from the
%    radar site location to the radial grid point.  Heading is the
%    direction from the grid point to the radar.  On a flat earth, these
%    will differ by 180, but this is not necessarily the case on a
%    spherical earth.  Radial speed can be positive or negative, with
%    positive indicating current towards the radar (i.e., in the same
%    sense as the heading), negative is away from the radar.  Using this
%    convention, U_radial = RadComp * cosd( Heading ), V_radial = RadComp *
%    sind( Heading ).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: README.m 291 2007-02-28 22:08:48Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help README
