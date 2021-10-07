function [ alpha, cov_alpha, ux, uy ] = openMA_modes_fit_with_errors_NaNs( varargin )
% OPENMA_MODES_FIT_WITH_ERRORS_NANS - fits modes to data with error
% propagation and taking NaN's into account.
%
% Usage: [alpha,cov_alpha,ux,uy] = openMA_modes_fit_with_errors_NaNs( ...
%                                        ux, uy, K, theta, magn, weights,
%                                        covaraince_matrix ) 
%        [alpha,cov_alpha,ux,uy] = openMA_modes_fit_with_errors_NaNs( ...
%                                        vfm, dfm, bm, K, cc, theta, ...
%                                        magn, weights, covaraince_matrix ) 
%
% This function is identical to openMA_modes_fit_with_errors, except that there can
% be some bad data (represented by NaN's or inf's).  See that function
% for additional documentation.
%
% Note also that weights can now have multiple columns for each column of
% data (though empty or a single column vector for weights is still
% acceptable).
%
% openMA_modes_fit_with_errors could be slightly faster if there is no bad
% or missing data, but generally it is easier to use this function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_fit_with_errors_NaNs.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find out type of input arguments - mode structures or matrices
if isa(varargin{1},'struct') | isempty( varargin{1} )
  [K,cc] = deal( varargin{4:5} );

  % This next line is usually very time consuming compared to the time it
  % takes to fit the data to the interpolated modes.
  [ux,uy] = openMA_modes_interp( cc, varargin{1:3} );

  varargin = varargin(6:end);
else
  [ux,uy,K] = deal( varargin{1:3} );
  varargin = varargin(4:end);
end

if length(varargin) ~= 4
  error( 'Bad input arguments' )
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
    error( 'covaraince matrix does not appear to be correct size.' );
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
% Deal with bad data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do this just in case we have a lot of rows missing the same data points
% and having the same weights - potentially faster than just looping over
% columns.  In particular, for all good data and a scalar weight, this
% function should take basically the same amount of time as
% openMA_modes_fit.

if prod(size(weights)) == length(weights)
  [BD,II,JJ] = unique( isfinite(magn)', 'rows' );
  BD = BD';
else 
  % If different weights for each column, must run each column separately
  % through openMA_modes_fit_with_errors.
  % Better have as many weight columns as magnitude columns.
  [BD,II,JJ] = unique( [ isfinite(magn); weights ]', 'rows' );
  BD = logical(BD(:,1:end/2))';
end

disp( [ 'openMA_modes_fit_NaNs: Loop over ' int2str(length(II)) ...
        ' "data groups" which correspond to ' int2str(size(magn,2)) ...
	' data columns.' ] );
cn = 10^(max(1,floor(log10(length(II))-1)));
disp( [ 'openMA_modes_fit_with_errors_NaNs: Will count by ' int2str(cn) ...
        '.' ] );

% Initialize matrices
alpha = zeros( size(ux,2), size(magn,2) );
cov_alpha = zeros( size(ux,2), size(ux,2), size(magn,2) );

% Loop and do fits
for k = 1:length(II)
  if mod(k,cn) == 1
    disp( [ 'Loop number ' int2str(k) '.' ] );
  end
  
  mn = magn( BD(:,k), JJ == k );
  th = theta( BD(:,k) );
  uu = ux( BD(:,k), : );
  vv = uy( BD(:,k), : );
  
  % Deal with scalar, vector and matrix weights as openMA_modes_fit can
  % only accept a single vector or a scalar.
  if prod(size(weights)) == 1
    we = weights;
  elseif prod(size(weights)) == length(weights)
    we = weights( BD(:,k) );
  else
    we = weights( BD(:,k), JJ == k );
    we = we(:,1);
  end

  % Deal with different types of covariance matrices
  switch cmt
   case 1
    cm = covmat;
   case 2
    cm = covmat( BD(:,k), JJ == k );
   case 3
    cm = covmat( BD(:,k), BD(:,k), JJ == k );
  end
  
  %keyboard
  [aa,ca] = openMA_modes_fit_with_errors( uu, vv, K, th, mn, we, cm );
  
  alpha( :, JJ == k ) = aa;
  cov_alpha( :, :, JJ == k ) = ca;
end

