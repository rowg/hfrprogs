function [L, EOFs, EC, error, norms, trends] = EOF( U, n, norm, trend, varargin )
% EOF  Computes EOF of a matrix.
%
% Usage: [L, EOFs, EC, error, norms, trends] = EOF( M, num, norm, detrend, ... )
%
% M is the matrix on which to perform the EOF.  num is the number of EOFs to
% return.  If num='all', then all EOFs are returned.  This is the default.
%
% If norm is true, then all time series are normalized by their standard
% deviation before EOFs are computed.  Default is false.  If true,
% the fifth output argument will be the standard deviations of each
% column.  Note that the norms are not reapplied to the resulting EOFs,
% so you will need to do this to get back the final data (see equations
% below).
%
% If detrend is true, then all time series have their means removed before
% computing EOFs.  Detrending is performed after any normalization (this is
% somewhat backwards of most thinking, but this ordering of operations is to
% maintain backward compatibility with prior versions of this
% function). Default for this parameter is false.  If true, then the sixth
% output argument will be the trends removed from each column.
%
% ... are extra arguments to be given to the svds function.  These will
% be ignored in the case that all EOFs are to be returned, in which case
% the svd function is used instead. Use these with care.
%
% L are the eigenvalues of the covariance matrix ( ie. they are normalized
% by 1/(m-1), where m is the number of rows ).  EC are the expansion
% coefficients (PCs in other terminology) and error is the reconstruction
% error (L2-norm).
%
% NOTE: If data are normalized and detrended by this function, then it
% can be somewhat complex to reconstruct the original series from the
% resulting EOFs.  The following equations should help:
%
% U = ( (EC * EOFs') + repmat(trends,[size(EC,1),1]) ) .* ...
%     repmat(norms,[size(EC,1),1]);
% EOFs_nonorm = diag(norms) * EOFs;
% error_nonorm = error .* norms;
%
% Note that EOFs_nonorm will not have the property of being a unitary
% matrix that EOFs has.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: EOF.m 479 2007-09-13 00:56:26Z dmk $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'n', 'var' ) || isempty(n)
  n = 'all';
end

if ~exist( 'norm', 'var' )
  norm = false;
end

if ~exist( 'trend', 'var' )
  trend = false;
end

s = size(U);
ss = min(s);

% Normalize by standard deviation if desired.
if norm
  norms = std(U,0,1);
  U = U .* repmat(1./norms,[s(1),1]);
else
  norms = ones([1,s(2)]);
end

% Detrend if desired.
if trend
  trends = mean(U,1);
  U = U - repmat(trends,[s(1),1]);
else
  trends = zeros([1,s(2)]);
end

% Do SVD
if (ischar(n) & n == 'all') | n >= ss
  % Use svd in case we want all EOFs - quicker.
  [ C, lambda, EOFs ] = svd( full(U) ); 
else
  % Otherwise use svds.
  [ C, lambda, EOFs, flag ] = svds( U, n, varargin{:} );
  
  if flag % Case where things did not converge - probably an error.
    warning( 'EOF: svds did not seem to converge!!!' );
  end
  
end

% Compute EC's and L
EC = C * lambda; % Expansion coefficients.
L = diag( lambda )' .^ 2 / (s(1)-1); % eigenvalues.

% Compute error.
diff=(U-EC*EOFs');
error=sqrt( sum( diff .* conj(diff) ) );

