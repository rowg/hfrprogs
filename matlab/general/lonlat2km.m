function [east, north] = lonlat2km(lon_orig,lat_orig,lon,lat)
%LONLAT2KM  Convert lat/lon to distances (km) referenced to a lon/lat point.
%
%   This function will convert longitude/latitude pairs to distances in 
%   kilometers east and west of a reference longitude/latitude point.  The
%   equation was obtained from Bowditch's book "The American Practical 
%   Navigator, 1995 edition, page 552."
%
% Usage:
%   [EAST,NORTH]=LONLAT2KM(LON_ORIG,LAT_ORIG,LON,LAT)
%
%
% Inputs:  lon_orig - reference longitude.
%	   lat_orig - reference latitude.
%	   lon      - longitude scalar or vector.
%	   lat      - latitude scalar or vector.
%
% Outputs: east     - distance east from reference point (km)
%          north    - distance north from reference point (km)
%
% Example: 
%	   	[EAST,NORTH]=LONLAT2KM(-122,35.4,LON,LAT)
%          will convert the vectors LON and LAT, which contain lon/lat pairs, 
%	   to distances in km east and north of -122 W, 35.4 N, returned
%          in the vectors EAST and NORTH. 
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%	Mike Cook - NPS Oceanography Dept. - FEB 94
%   Mike Cook - JUN 94 - added more documentation and error checking.


if nargin ~= 4
  error(' You *MUST* supply 4 input arguments ')
end
	
	
con = radians(lat_orig);
ymetr = 111132.92 - 559.82 .* cos(2 .* con) + 1.175 ...
        .* cos(4 .* con) - 0.0023 .* cos(6 .* con);
xmetr = 111412.84 .* cos(con) - 93.50 .* cos(3 .* con) ...
        + 0.0118 .* cos(5 .* con);
east = (lon - lon_orig) .* xmetr ./ 1000;
north = (lat - lat_orig) .* ymetr ./ 1000;

return;
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = radians(d);
r = d .* pi ./ 180;
return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
