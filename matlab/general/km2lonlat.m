function [lon, lat] = km2lonlat(lon_orig,lat_orig,east,north)
%KM2LONLAT  Convert distances in km referenced to a lon/lat point to lon/lat.
%
%   This function will convert distances in kilometers east and west
%   of a reference longitude/latitude point to longitude/latitude.  The
%   equation was obtained from Bowditch's book "The American Practical 
%   Navigator, 1995 edition, page 552."
%
% Usage:
%   [LON,LAT]=KM2LONLAT(LON_ORIG,LAT_ORIG,EAST,NORTH)
%
% Inputs:
%     LON_ORIG - reference longitude (decimal degrees), a scalar.
%     LAT_ORIG - reference latitude (decimal degrees), a scalar.
%     EAST     - distance east (km) of reference point (scalar or vector).
%     NORTH    - distance north (km) of reference point (scalar of vector).
%
% Outputs: 
%     LON      - longitude (decimal degrees)
%     LAT      - latitude (decimal degrees)
%
% Example: 
%	   	[LON,LAT]=KM2LONLAT(-122,35.4,EAST,NORTH)
%          will convert the vectors EAST and NORTH, which contain distances 
%	   in km east and north of -122 W, 35.4 N to lon/lat pairs, returned
%          in the vectors LON and LAT. 
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%	Mike Cook - NPS Oceanography Dept. - FEB 94
%   Mike Cook - JUN 94 - added more documentation and error checking.


%  Check for the correct number of inputs.
if nargin ~= 4
    error(' You *MUST* supply 4 input arguments ')
end

con = radians(lat_orig);
ymetr = 111132.92 - 559.82 .* cos(2 .* con) + 1.175 ...
            .* cos(4 .* con) - 0.0023 .* cos(6 .* con);
xmetr = 111412.84 .* cos(con) - 93.50 .* cos(3 .* con) ...
            + 0.0118 .* cos(5 .* con);
lon = east .* 1000 ./ xmetr + lon_orig;
lat = north .* 1000 ./ ymetr + lat_orig;
