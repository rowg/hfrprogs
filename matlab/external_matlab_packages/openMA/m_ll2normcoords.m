function [XY,XYproj] = m_ll2normcoords( origin, LonLat, area )
% M_LL2NORMCOORDS - converts LonLat coordinates to coordinates in which
% OMA domain has unit area.  Uses m_map projection to do this.
%
% This function converts from a set of lon,lat coordinates to coordinates
% where the domain has unit area (the "normalized" coordinates).  These
% normalized coordinates are often used for generating modes as a domain of
% unit area is often numerically easier to deal with and eigenvalues can be
% compared with those of the unit square, which is well understood.  The
% function assumes that you have previously set up a m_map projection
% using m_proj and then uses the m_ll2xy to calculate the corresponding
% xproj and yproj coordinates of the points.  These are then normalized by
% the sqrt of the domain area.
%
% Usage: [ XY, XYproj ] = m_ll2normcoords( LonLat, area )
%        [ XY, XYproj ] = m_ll2normcoords( origin, LonLat, area )
%
% where origin is a LonLat pair to be used as the origin of the coordinate
% system, LonLat is two column matrix with lon and lat pairs, and area is
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
% 	$Id: m_ll2normcoords.m 73 2007-02-22 19:20:33Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  area = LonLat;
  LonLat = origin;
  origin = [0,0];
else
  [origin(1),origin(2)] = m_ll2xy( origin(1), origin(2) );
end

[XYproj(:,1),XYproj(:,2)] = m_ll2xy( LonLat(:,1), LonLat(:,2) );
XY = ( XYproj - repmat(origin,[size(LonLat,1),1]) ) / sqrt(area);
