function [lon,lat,button] = m_ginput( varargin )
% M_GINPUT ginput for use with m_map - returns longitude and latitude
% instead of the true x,y used by m_map
%
% Usage: [lon,lat,button] = m_ginput( n )
%
% The function works identical to ginput except that it returns longitude
% and latitude from an m_map plot.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_ginput.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[x,y,button] = ginput( varargin{:} );

[lon,lat] = m_xy2ll( x, y );

if nargout < 3
  clear button
end

if nargout < 2
  lon = [ lon, lat ];
  clear lat
end

