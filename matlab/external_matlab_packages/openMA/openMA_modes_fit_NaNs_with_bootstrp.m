function [alpha,bstrp,ux,uy]=openMA_modes_fit_NaNs_with_bootstrp(nb,varargin)
% OPENMA_MODES_FIT_NANS_WITH_BOOTSTRP - fits modes to data
%
% Use:[alpha,bstrp,ux,uy]=openMA_modes_fit_NaNs_with_bootstrp(nbstrp,ux,uy,K,theta1,magn1,weight1, ... )
%     [alpha,bstrp,ux,uy]=openMA_modes_fit_NaNs_with_bootstrp(nbstrp,vfm,dfm,bm,K,cc,theta1,magn1, ... )
%
% This function is identical to openMA_modes_fit_NaNs, except that the fits
% are performed nbstrp times using a randomly determined resampling of the
% grid points each time.  alpha will have a third dimension with size
% nbstrp.  The bstrp return argument contains the resamplings.  Note that
% these resamplings are numbered based on the number of data current vectors
% after removing bad data (NaNs) and joining the different components into a
% single large matrix.
%
% Note that for each resampling the weights will be renormalized so that
% they sum to the same sum as the original weights.
%
% See openMA_modes_fit_NaNs for more details on the other arguments of this
% function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_fit_NaNs_with_bootstrp.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nb < 1
  error( 'nbstrp must be greater than or equal to 1.' );
end

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

if prod(size(weights)) == length(weights) % If weights are a vector, same
                                          % for all columns.
  [BD,II,JJ] = unique( isfinite(magn)', 'rows' );
  BD = BD';
else 
  % If different weights for each column, must run each column separately
  % through openMA_modes_fit.
  % Better have as many weight columns as magnitude columns.
  [BD,II,JJ] = unique( [ isfinite(magn); weights ]', 'rows' );
  BD = logical(BD(:,1:end/2))';
end

alpha = zeros( size(u1,2), size(magn,2), nb );
if nargout > 1
  bstrp = repmat( NaN, [ size(magn), nb ] );
end

disp( [ 'openMA_modes_fit_NaNs_with_bootstrp: Loop over ' int2str(length(II)) ...
        ' "data columns".' ] );
cn = 10^(max(1,floor(log10(length(II))-1)));
disp( [ 'openMA_modes_fit_NaNs_with_bootstrp: Will count by ' int2str(cn) ...
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

  wes = sum(we);
  
  % Create resamplings.
  rs = ceil( size(mn,1) * rand( [ size(mn,1), 1, nb ] ) );

  if nargout > 1
    bstrp( BD(:,k), JJ==k, : ) = repmat( rs, [1,sum(JJ==k),1] );
  end
  
  rs = squeeze(rs);
  
  % Loop and fit.
  for w = 1:nb
    if prod(size(we)) == 1
      wew = we;
    else
      wew = we( rs(:,w) );
      wew = wes * wew / sum(wew);
    end
    
    aa = openMA_modes_fit( uu(rs(:,w),:), vv(rs(:,w),:), K, th(rs(:,w)), mn(rs(:,w),:), wew );
    alpha( :, JJ == k, w ) = aa;
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout < 3
  clear ux
end

if nargout < 4
  clear uy
end
