function [ alpha, ux, uy ] = openMA_modes_fit_NaNs( varargin )
% OPENMA_MODES_FIT_NANS - fits modes to data
%
% Usage: [alpha,ux,uy] = openMA_modes_fit_NaNs( ux, uy, K, theta1, magn1, weight1, ... ) 
%        [alpha,ux,uy] = openMA_modes_fit_NaNs( vfm, dfm, bm, K, cc, ...
%                                     theta1, magn1, weight1, ... ) 
%
% This function is identical to openMA_modes_fit, except that there can
% be some bad data (represented by NaN's or inf's).  See that function
% for additional documentation.
%
% Note also that weight1 can now have multiple columns for each column of
% data (though empty or a single column vector for weight1, as well as
% weight2, etc., is still acceptable).
%
% openMA_modes_fit could be slightly faster if there is no bad or missing
% data, but generally it is easier to use this function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_fit_NaNs.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
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

if mod(length(varargin),3) ~= 0
  error( 'Bad input arguments' )
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
  % through openMA_modes_fit.
  % Better have as many weight columns as magnitude columns.
  [BD,II,JJ] = unique( [ isfinite(magn); weights ]', 'rows' );
  BD = logical(BD(:,1:end/2))';
end

alpha = zeros( size(u1,2), size(magn,2) );

disp( [ 'openMA_modes_fit_NaNs: Loop over ' int2str(length(II)) ...
        ' "data groups" which correspond to ' int2str(size(magn,2)) ...
	' data columns.' ] );
cn = 10^(max(1,floor(log10(length(II))-1)));
disp( [ 'openMA_modes_fit_NaNs: Will count by ' int2str(cn) ...
        '.' ] );

for k = 1:length(II)
  if mod(k,cn) == 1
    disp( [ 'Loop number ' int2str(k) '.' ] );
  end
  
  mn = magn( BD(:,k), JJ == k );
  th = theta( BD(:,k) );
  uu = u1( BD(:,k), : );
  vv = u2( BD(:,k), : );
  
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

  %keyboard
  aa = openMA_modes_fit( uu, vv, K, th, mn, we );
  
  alpha( :, JJ == k ) = aa;
end
