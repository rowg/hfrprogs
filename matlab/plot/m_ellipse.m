function [lon2,lat2,x,y] = m_ellipse( lon1, lat1, azimuth, a, b, n, varargin )
% M_ELLIPSE - A function for generating Lon,Lat ellipses
%
% This function makes a plot of a set of ellipses around a set of lon,lat
% coordinates
%
% Usage: [lon2,lat2] = m_ellipse(lon1,lat1,azimuths,A,B,n,spheroid)
%
% Inputs
% ------
% lon1,lat1 = coordinates of centers of ellipses.  This, as well as all
%             other input arguments except n and spheroid, can be matrices.
%             In this case, they will be turned into vectors and then
%             resized using repmat so that lon1,lat1,azimuths,A and B all
%             have the same size.
% azimuths = angles in degrees to major axes of ellipses measured
%            CLOCKWISE FROM NORTH.  This convention is to be consistent
%            with M_map.  THIS DIFFERS FROM REST OF TOOLBOX.
% A,B = major and minor axes of ellipses, respectively.  These should be
%       in METERS.  This is again for consistency with M_map.
% n = numbers of point to use along each ellipse.  Defaults to 100.
% spheroid = see m_fdist for details.  Has same default as in m_fdist.
%
% Outputs
% -------
% lon2,lat2 = coordinates of ellipses.  This will be a matrix with n rows
%             and as many columns as the numbers of elements in the largest
%             sized matrix of lon1,lat1,azimuths,A and B.
%
% NOTE: This functions uses the same angle and distance conventions as in
% the M_MAP toolbox itself.  These differ from the conventions used in
% the rest of the toolbox.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_ellipse.m 485 2007-09-25 20:46:05Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('n','var')
  n = 100;
end

% Reshape basic matrices
[lon1,lat1,azimuth,a,b] = deal(lon1(:)',lat1(:)',azimuth(:)',a(:)',b(: )');
m = max([numel(lon1),numel(lat1),numel(azimuth),numel(a),numel(b)]);
lon1 = repmat( lon1, [n,m/numel(lon1)] );
lat1 = repmat( lat1, [n,m/numel(lat1)] );
azimuth = repmat( azimuth, [n,m/numel(azimuth)] );
a = repmat( a, [n,m/numel(a)] );
b = repmat( b, [n,m/numel(b)] );

% Generate thetas
th = linspace(0,2*pi,n);
th = repmat(th(:),[1,m]);

% Get x and y - note y,x because of how angles are measured from north.
[y,x] = deal( a .* cos(th), b .* sin(th) );

% Get polar coordinates and add azimuth
[th,r] = cart2pol(y,x);
th = th + azimuth*pi/180;

% Use m_fdist to get lon,lat coordinates
[lon2,lat2] = m_fdist( lon1, lat1, th*180/pi, r, varargin{:} );

% Fix y and x if desired
if nargout > 2
  [y,x] = pol2cart(th,r);
end

% ALL DONE