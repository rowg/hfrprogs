function [ alpha, ux, uy ] = openMA_modes_fit( varargin )
% OPENMA_MODES_FIT - fits modes to data
%
% Usage: [alpha,ux,uy] = openMA_modes_fit( ux, uy, K, theta1, magn1, weight1, ... ) 
%        [alpha,ux,uy] = openMA_modes_fit( vfm, dfm, bm, K, cc, theta1, magn1, weight1, ... ) 
%
% vfm, dfm and bm are the vorticity-free, divergence-free and boundary mode structures
% produced by the openMA_pdetool solver functions. cc is a two column
% matrix of coordinates (in the dimensions of the modes themselves).
%
% ux and uy are matrices of the format produced by openMA_modes_interp -
% i.e. each column is a mode and each row is a grid point.  Grid points
% must be the same as those found in magn1.
%
% K is "homogenization term" introduced by Francois Lekien to avoid
% velocities becoming large.  It can be a scalar, vector of the same
% length as the total number of modes (in which case, a diagonal matrix
% with those coefficients will be used) or a square matrix with the number
% of rows equal to the total number of modes.  If it is empty, zero will
% be used for K.  Note that this definition of K includes the maximum
% current value for each mode and the "constant K" (see Kaplan & Lekien
% paper).
%
% theta1 and magn1 indicate the direction (in radians measured in the normal
% cartesian sense) and magnitude along that direction of the currents at
% each of the grid points in cc (i.e. length(theta1) == size(magn1,1) ==
% size(cc,1)).  Multiple columns of magn1 can be used for different
% timesteps.  
%
% weight1 are the weights to apply to each of the components vectors.  This
% can either be a scalar (same weight for all grip points) or a column
% vector of size(magn1(:,1)).  weight1 must be given, though it can be
% empty, in which case the weights are set to 1.  A vector of weights should
% normally sum to the total number of grid points for the formulas to work
% out naturally.
%
% You can also have theta2, magn2, weight2 if there are multiple components
% at the same grid points.  Note, however, that the weights must either
% all be vectors with as many elements as grid points, or they must all
% be empty (i.e. using a scalar weight will not work in this case).
%
% Note that this function assumes all the velocity components are good
% data.  If you have some missing data, use openMA_modes_fit_NaNs
% instead.
%
% cc must be in the coordinate system of the modes.  If you have lon,lat
% coordinates, use openMA_modes_interp_lonlat to get the coordinates in
% the modes coordinate system.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_fit.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find out type of input arguments - mode structures or matrices
if isa(varargin{1},'struct') | isempty( varargin{1} )
  [K,cc] = deal( varargin{4:5} );
  
  % This next line is usually very time consuming relative to the time it
  % takes to fit data to the interpolated modes.
  [ux,uy] = openMA_modes_interp( cc, varargin{1:3} );

  varargin = varargin(6:end);
else
  [ux,uy,K] = deal( varargin{1:3} );
  varargin = varargin(4:end);
end

if mod(length(varargin),3) ~= 0
  error( 'Bad input arguments' )
end

if isempty(K), K = 0; end

% K is a scalar or vector
if prod(size(K)) == max(size(K))
  K = diag(K);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create matrices that go into linear model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put all magnitudes together.
magn = vertcat( varargin{2:3:end} );

% Put all theta vectors together
theta = vertcat( varargin{1:3:end} );

% Put all weight vectors together
weights = vertcat( varargin{3:3:end} );
if isempty( weights )
  weights = 1;
end

% Bump up ux and uy
[u1,u2] = deal( repmat(ux,[length(varargin)/3,1]), ...
		repmat(uy,[length(varargin)/3,1]) );

% Components of modes along directions.
modes = u1 .* repmat( cos(theta), [1,size(u1,2)] ) + ...
	u2 .* repmat( sin(theta), [1,size(u2,2)] );

clear u1 u2 theta

% Look for points outside of domain.  
ii = any( isnan(modes), 2 );
if any( ii )
  modes(ii,:) = [];
  magn(ii,:) = [];
  
  if prod(size(weights)) ~= 1
    weights(ii,:) = [];
  end
  
  warning( 'openMA:openMA_modes_fit:data_outside_domain', ...
	   [ 'Some data points outside of domain or containing NaNs' ...
	     ' eliminated.  Watch out for weights!' ] );
end

q = size(modes,1); % Number of points with current components.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linear model: modes' * weights * magn = ( modes' * weights * modes + q/2 * K ) * alpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% repmat is MUCH quicker than using a diagonal matrix.
if prod(size(weights))==1
  weights = (modes * weights)';
else
  weights = (modes .* repmat( weights(:), [1,size(modes,2)] ))';
end

alpha = (weights * modes + q/2 * K) \ (weights * magn);

%keyboard

% Note, I am not sure if I should use q/2 or q here.  The prior seems
% like the correct choice if you want K to have a magnitude comparable to
% that of an individual current vector.
