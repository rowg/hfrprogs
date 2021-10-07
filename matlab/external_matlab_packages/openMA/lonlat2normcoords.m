function [x,y,xkm,ykm] = lonlat2normcoords( origin, lonlat, area )
% LONLAT2NORMCOORDS - converts lonlat coordinates to coordinates in which
% OMA domain has unit area.
%
% This function converts from a set of lon,lat coordinates to coordinates
% where the domain has unit area (the normalized coordinates).  These
% normalized coordinates are often used for generating modes as a domain of
% unit area is often numerically easier to deal with and eigenvalues can be
% compared with those of the unit square, which is well understood.
%
% Usage: [ x, y, xkm, ykm ] = lonlat2normcoords( origin, lonlat, area )
%
% where origin is a lonlat pair with the origin of Km coordinate system,
% lonlat is two column matrix with lon and lat pairs, and area is the
% area of the OMA domain.
%
% Will also return Km coordinates if desired.
%
% NOTE that this function requires the lonlat2km function from Mike Cook's
% HFradarmap toolbox.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: lonlat2normcoords.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xkm,ykm] = lonlat2km( origin(1), origin(2), lonlat(:,1), lonlat(:,2) ...
		       );
[x,y] = deal( xkm / sqrt(area), ykm / sqrt(area) );

if nargout < 4
  clear ykm
end

if nargout < 3
  clear xkm
end
