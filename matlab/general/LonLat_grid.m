function [ Lon, Lat ] = LonLat_grid( ll, ur, dxy, du )
% LONLAT_GRID  Creates a regular LonLat grid given x and y spacings.
%
% Usage: [ Lon, Lat ] = LonLat_grid( LowerLeft, UpperRight, deltaXY, ...
%                                 deltaUnits )
%
% Inputs
% ------
% LowerLeft = lower left corner of grid as a Lon,Lat pair
% UpperRight = upper right corner of grid as a Lon,Lat pair
% deltaXY = Longitudinal and latitudinal spacings as a 2 element vector.
%           Units should km unless specified otherwise in deltaUnits.  If
%           a single number is given, then both spacings are considered
%           equal.
% deltaUnits = a string that is either 'km' (the default) or 'LonLat'.
%
%
% NOTE: Lon and Lat will be centered in the box defined by LowerLeft and
% UpperRight. Also, the function uses the M_Map toolbox for distance
% calculations.  Therefore m_map must be on the Matlab path.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: LonLat_grid.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'du', 'var' )
  du = 'km';
end

if numel(dxy) == 1
  dxy = [ dxy, dxy ];
end

switch du
  case 'LonLat'
    Lon = ll(1):dxy(1):ur(1);
    Lat = ll(2):dxy(2):ur(2);
  case 'km'
    dxy = 1e3 * dxy; % Convert to meters
    
    % Lat stuff is easy because are great circles - just use m_idist
    dd = m_idist( ll(1), ll(2), ll(1), ur(2) );
    dd = 0:dxy(2):dd;
    [dd,Lat] = m_fdist( ll(1), ll(2), 0, dd );
    
    % Lon is harder and more approximate
    mm = ( ll + ur ) / 2; % Middle of grid
    % meters distance of small displacement scaled up to 1 degree
    % longitude displacement
    dd = 1e4 * m_idist( mm(1), mm(2), mm(1)+1e-4, mm(2) ); 
    dd = dxy(1) / dd; % Appropriate displacement in Longitude
    Lon = ll(1):dd:ur(1);
  otherwise
    error( 'Bad deltaUnits' );
end

% Adjust Lon and Lat so that they are centered in box.
Lon = Lon + (ur(1) - Lon(end)) / 2;
Lat = Lat + (ur(2) - Lat(end)) / 2;

% Create grid
[Lon,Lat] = meshgrid( Lon, Lat );
