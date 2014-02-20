function [LonPerCM, LatPerCM] = LonLatPerCM( Lon, Lat, varargin )
% LONLATPERCM  Calculates the Longitude and Latitude displacement
% equivalent to 1 cm at given locations on the earth.
%
% Usage: [LonPerCM, LatPerCM] = LonLatPerCM( Lon, Lat, spheroid )
%
% This function uses m_map toolbox to make calculations
% 
% Inputs
% ------
% Lon,Lat = equal size matrices of Lon, Lat coordinates
% spheroid = see m_fdist for more details
%
% Outputs
% -------
% LonPerCM = change in Lon for 1 cm movement in longitudinal direction at
%            locations in Lon,Lat.
% LatPerCM = change in Lat for 1 cm movement in latitudinal direction at
%            locations in Lon,Lat.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: LonLatPerCM.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2003 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get XXX/CM - remember angles in True convention
LonPerCM = mod( m_fdist( Lon, Lat, 90, 0.01, varargin{:} ) - Lon, 360 );
[tt,ll] = m_fdist( Lon, Lat,  0, 0.01, varargin{:} );
LatPerCM = mod( ll - Lat, 360 );
