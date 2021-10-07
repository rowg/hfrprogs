function [ alpha, cov_alpha, ux, uy ] = openMA_modes_fit_with_errors( varargin )
% OPENMA_MODES_FIT_WITH_ERRORS - fits modes to data with error propagation
%
% Usage: [alpha,cov_alpha,ux,uy] = openMA_modes_fit_with_errors( ...
%                                         ux, uy, K, theta, magn, ...
%                                         weight, covaraince_matrix ) 
%        [alpha,cov_alpha,ux,uy] = openMA_modes_fit_with_errors( ...
%                                         vfm, dfm, bm, K, cc, theta, ...
%                                         magn, weight, covariance_matrix ) 
%
% vfm, dfm and bm are the vorticity-free, divergence-free and boundary mode structures
% produced by the openMA_pdetool solver functions. cc is a two column
% matrix of coordinates (in the dimensions of the modes themselves).
%
% ux and uy are matrices of the format produced by openMA_modes_interp -
% i.e. each column is a mode and each row is a grid point.  Grid points
% must be the same as those found in magn.
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
% theta and magn indicate the direction (in radians measured in the normal
% cartesian sense) and magnitude along that direction of the currents at
% each of the grid points in cc (i.e. length(theta) == size(magn,1) ==
% size(cc,1)).  Multiple columns of magn can be used for different
% timesteps.  
%
% weight are the weights to apply to each of the components vectors.  This
% can either be a scalar (same weight for all grip points) or a column
% vector of size(magn(:,1)).  weight must be given, though it can be
% empty, in which case the weights are set to 1.  A vector of weights should
% normally sum to the total number of grid points for the formulas to work
% out naturally.
%
% The covariance_matrix will be a set of variances and covarainces among
% measured data points for each timestep.  This can take a number of
% forms: (1) a scalar, in which case a uniform error is assumed for all
% measured data. (2) a 2D matrix with the same number of rows as grid
% points and the same number of columns as timesteps, in which case it is
% assumed that each column represents the *variances* (i.e. not standard
% deviations).  The covariances are assumed zero in this case.  (3) a 3D
% matrix with the first two dimensions having the same size, that of the
% number of grid points, and the third dimension having the same size as
% the number of timesteps.  In this case, covariance_matrix(:,:,k) is the
% full covariance matrix among data points for timestep k.
%
% The output argument alpha will be as in the other fit functions
% (size(alpha,1) = number of modes, size(alpha,2) = number of timesteps).
%
% cov_alpha is the covariances among the alpha's.  It will have three
% dimensions - the first two of the same size as the number of modes, the
% last of the same size as the number of timesteps.
% diag(cov_alpha(:,:,k)) are the variances for each alpha at timestep k
% (the square-root of which would be the error estimation for the alpha's
% at timestep k).
%
% Unlike some of the other fit functions, this one does not allow
% multiple sets of theta, magn, weights, covariance_matrix for
% simplicity.  If you have multiple currents components at each grid
% points (e.g. you are using totals data), then ux and uy (or cc), theta,
% magn, weights and covariance matrix should be appropriately vertically
% concatenated.
%
% Note that this function assumes all the velocity components are good
% data.  If you have some missing data, use openMA_modes_fit_with_errors_NaNs
% instead.
%
% cc must be in the coordinate system of the modes.  If you have lon,lat
% coordinates, use openMA_modes_interp_lonlat to get the coordinates in
% the modes coordinate system.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_fit_with_errors.m 70 2007-02-22 02:24:34Z dmk $	
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

if length(varargin) ~= 4
  error( 'Bad input arguments' )
end

if isempty(K), K = 0; end

% K is a scalar or vector
if prod(size(K)) == max(size(K))
  K = diag(K);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get basic matrices that go into linear model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[theta,magn,weights,covmat] = deal( varargin{:} );

% Deal with empty weights
if isempty( weights )
  weights = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure out what type of covariance matrix we were given
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(size(covmat)) == 3
  % Must be full covariance matrix for each timestep
  cmt = 3;

  % Check to make sure size is correct
  if ~all( size(covmat) == [ size(magn,1), size(magn,1), size(magn,2) ] )
    error( 'covaraince matrix does not appear to be correct size. cmt=3' );
  end
  
elseif prod(size(covmat)) == 1
  % Scalar
  cmt = 1;
  
else % Must be a 2D matrix - now need to figure out what that means.
  if all( size(covmat) == size(magn) )
    % Case where we have multiple timesteps, and each column are the
    % variances for that timestep (covariances are zero).
    cmt = 2;
  elseif size(magn,2)==1 & ...
	all( size(covmat) == [size(magn,1),size(magn,1)] )
    % Case where we have one timestep, but use a full covariance matrix.
    cmt = 3;
  else
    error( 'covaraince matrix does not appear to be correct size. cmt=2' );
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Components of modes along directions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modes = ux .* repmat( cos(theta), [1,size(ux,2)] ) + ...
	uy .* repmat( sin(theta), [1,size(uy,2)] );

clear theta

if nargout < 3, clear ux, end
if nargout < 4, clear uy, end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove points outside of domain.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ii = any( isnan(modes), 2 );
if any( ii )
  modes(ii,:) = [];
  magn(ii,:) = [];
  
  if prod(size(weights)) ~= 1
    weights(ii,:) = [];
  end
  
  % Remove extra stuff from covmat
  switch cmt
   case 2
    covmat(ii,:) = [];
   case 3
    covmat = covmat(~ii,~ii,:);
  end
  
  warning( 'openMA:openMA_modes_fit:data_outside_domain', ...
	   [ 'Some data points outside of domain or containing NaNs' ...
	     ' eliminated.  Watch out for weights!' ] );
end

q = size(modes,1); % Number of points with current components.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linear model: modes' * weights * magn = ...
%             ( modes' * weights * modes + q/2 * K ) * alpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multiply modes and weights beforehand for speed.
if prod(size(weights))==1
  weights = modes' * weights;
else
  % repmat is MUCH quicker than using a diagonal matrix.
  weights = modes' .* repmat( weights(:)', [size(modes,2),1] );
end
% now:  weights = modes' * weights

T = (weights * modes + q/2 * K);
alpha = T \ ( weights * magn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over time steps and calculate cov_alpha for each one.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cov_alpha = zeros( [ size(alpha,1), size(alpha,1), size(alpha,2) ] );
for n = 1:size(alpha,2)
  switch cmt
   case 1 % Scalar case.
    covmagn = weights * covmat * weights';
   case 2 % Only specifying variances
    % Use repmat instead of normal matrix multiplaction for speed with
    % diagonal matrices.
    covmagn = (weights .* repmat( covmat(:,n)', [size(weights,1),1] ) ) * ...
	      weights';
   case 3 % Full covariance matrix
    covmagn = weights * covmat(:,:,n) * weights';
  end

  cov_alpha(:,:,n) = inv( T' * inv(covmagn) * T );
end
