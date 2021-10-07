function [LonLat,XYproj] = m_normcoords2ll( origin, XY, area )
% M_NORMCOORDS2LL - converts from coordinates in which OMA domain has unit
% area to Lon,Lat using m_map projection.
%
% This function converts from a set of coordinates where the domain has unit
% area (the "normalized" coordinates) to lon,lat.  These normalized
% coordinates are often used for generating modes as a domain of unit area
% is often numerically easier to deal with and eigenvalues can be compared
% with those of the unit square, which is well understood.  The function
% assumes that you have previously set up a m_map projection using m_proj
% and then uses the m_xy2ll to calculate the corresponding lon and lat
% coordinates of the points after adjusting for the area of the domain
% and origin.
%
% Usage: [ LonLat, XYproj ] = m_normcoords2ll( xy, area )
%        [ LonLat, XYproj ] = m_normcoords2ll( origin, xy, area )
%
% where origin is a lonlat pair that is the origin of the coordinate system,
% xy is a column matrix with coordinates in normalized system, and area is
% the area of the OMA domain in the m_map projection coordinate system.  In
% the first usage, the origin will be the default origin of the m_map
% projection coordinate system.
%
% Will also return projection coordinates if desired.
%
% NOTE that this function requires the m_map toolbox and that you have
% previously used m_proj to define the current projection!!!
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_normcoords2ll.m 73 2007-02-22 19:20:33Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  area = xy;
  xy = origin;
  origin = [0,0];
else
  [origin(1),origin(2)] = m_ll2xy( origin(1), origin(2) );
end

XYproj = XY * sqrt(area) + repmat( origin, [size(XY,1),1] );
[LonLat(:,1),LonLat(:,2)] = m_xy2ll( XYproj(:,1), XYproj(:,2) );
