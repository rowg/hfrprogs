function [x, r] = varimax( x, normalize, tol, it_max )
% VARIMAX  Rotate EOF's according to varimax algorithm
%
% This is actually a generic varimax routine and knows nothing special about
% EOFs.  It expects a matrix of "loadings".  Typically (in state space
% rotation), these loadings are the expansion coefficients (aka Principal
% Component Time Series) for the truncated basis of eigenvectors (EOFs), but
% they could also be the EOFs*diag(L)^(1/2) (in the case of rotation in
% sample space).
%
% Usage: [new_loads, rotmax] = varimax( loadings, normalize, tolerance, it_max )
%
% where all but the loadings are optional.  rotmax is the rotation matrix used.
%
% normalize determines whether or not to normalize the rows or columns of
% the loadings before performing the rotation.  If normalize is true, then
% the rows are normalized by there individual lengths.  Otherwise, no
% normalization is performed (default).  After rotation, the matrix is
% renormalized. Normalizing over the rows corresponds to the Kaiser
% normalization often used in factor analysis.
%
% tolerance defaults to 1e-10 if not given.  it_max specifies the maximum
% number of iterations to do - defaults to 1000.
%
% After the varimax rotation is performed, the new EOFs (in the case that
% the EC's were rotated - state space) can be found by new_eofs =
% eofs*rotmax.
%
% This function is derived from the R function varimax in the mva
% library.    
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: varimax.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2002 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
  normalize = 0;
end

if nargin < 3
  tol = 1e-10;
end

if nargin < 4
  it_max = 1000;
end

[p, nc] = size(x);

if nc < 2, return; end

if normalize 
  rl = repmat( sqrt(diag( x*x' )), [1,nc] ); % By rows.
  % rl = repmat( sqrt(diag( x'*x ))', [p,1] ); % By columns.
  x = x ./ rl;
end

TT = eye( nc );
d = 0;

for i = 1 : it_max
  z = x * TT;
  B = x' * ( z.^3 - z * diag(squeeze( ones(1,p) * (z.^2) )) / p );
  
  [U,S,V] = svd(B);
  
  TT = U * V';

  d2 = d;
  d = sum(diag(S));
  
  % End if exceeded tolerance.
  if d < d2 * (1 + tol), break; end
  
end

% Final matrix.
x = x * TT;

% Renormalize.
if normalize
  x = x .* rl;
end

if nargout > 1
  r = TT;
end
