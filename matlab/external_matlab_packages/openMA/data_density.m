function dens = data_density( tg, gd, r, xy, type )
% DATA_DENSITY - Calculates the spatial density of grid points around a
% certain set of points for each timestep.
%
% Usage: dens = density( totalGrid, gooddata, radius, coord_pts )
%
% totalGrid is a 2-column set of coordinate points where data is located.  
%
% gooddata is a matrix where each row corresponds to a grid point (point
% in totalGrid) and each column is a timestep.  Grid points and time steps for
% which data is present should be represented by a 1, bad data by a zero.
% If gooddata=[] (i.e. is empty), then a one column matrix of ones with the
% same number of elements as grid points in totalGrid will be used.
%
% radius is a distance in Km around each grid point to look for other data
% points.  It can be a scalar, in which case a single distance is used, or
% it can be a vector with as many elements as points in coord_pts.
%
% coord_pts is a two column matrix of the coordinates of the points at which
% the density is to be determined.  It should be in the same units as
% totalGrid (i.e. either Km or lon,lat).  If this argument is absent, then
% totalGrid is used.
%
% type is a string indicating the units of totalGrid and coord_pts.  It
% can be either 'lon,lat' or 'km' (must be exact). Defaults to 'lon,lat'.
%
% NOTE that this function requires the lonlat2km function from Mike Cook's
% HFradarmap toolbox if lon,lat coordinates are used.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: data_density.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Default to grid points.
if ~exist('xy','var')
  xy = tg;
end

if ~exist('type','var')
  type = 'lon,lat';
end

if isempty(gd)
  gd = ones( size(tg,1), 1 );
end

% Put everything in KM if not already
switch type
 case 'lon,lat'
  oo = mean(tg);
  [e,n] = lonlat2km( oo(1), oo(2), tg(:,1), tg(:,2) );
  tg = [ e, n ];
  
  [e,n] = lonlat2km( oo(1), oo(2), xy(:,1), xy(:,2) );
  xy = [ e, n ];  
 case 'km'
  % Nothing to do
 otherwise
  error( 'Units not understood' )
end

% Make d a vector if it is a scalar.
if prod(size(r)) == 1
  r = repmat(r,size(xy(:,1)));
end

% Initialize density matrix.
dens = zeros( [ length(r), size(gd,2) ] );

% Loop to avoid very large matrixes
for k = 1:size(dens,1)
  dd = sqrt( (tg(:,1) - xy(k,1)).^2 + (tg(:,2) - xy(k,2)).^2 );
  dd = dd < r(k);
  
  if any(dd)
    dens(k,:) = sum( gd(dd,:), 1 );
  end
end

