function [L, EOFs, EC, EC_uncert, error, norms, trends, N] = ...
      nanEOF( U, nanact, norm, trend, varargin )
% nanEOF  Computes EOF of a real-valued matrix with missing (NaN) values
%
% Usage: [L, EOFs, EC, EC_uncert, error, norms, trends, N] = nanEOF( M, ...
%                         NANACTION, norm, detrend, ... )
%
% NOTE: This function uses the nancov, nanvar and nanmean functions from
% the stats toolbox (unfortunately).
%
% M is the matrix on which to perform the EOF.  
%
% NANACTION is either 'complete' (default) or 'pairwise'.  See the nancov
% function for more details.
%
% If norm is true, then all time series are normalized by their standard
% deviation before EOFs are computed.  Default is false.  If true,
% the sixth output argument will be the standard deviations of each
% column.  Note that the norms are not reapplied to the resulting EOFs,
% so you will need to do this to get back the final data (see equations
% below).
%
% If detrend is true, then all time series have their means removed before
% computing EOFs.  Detrending is performed after any normalization (this is
% somewhat backwards of most thinking, but this ordering of operations is to
% maintain backward compatibility with prior versions of this
% function). Default for this parameter is true (DIFFERENT FROM STANDARD EOF
% FUNCTION).  If true, then the seventh output argument will be the trends
% removed from each column.
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
% EC_uncerts are the predicted uncertainties in the EC's.  These will be
% nonzero for rows of the EC's that were based on reconstruction using rows
% that had some missing values.  These are derived following R.E. Davis
% (1977).  They will have the same units as the EC's.
%
% N is the number of measurements that went into generating each element
% of the covariance matrix.  If NANACTION is 'complete', this will be a
% single number.  If NANACTION is 'pairwise', then the result will be a
% square symmetric matrix with the N for each element of the covariance.
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
% 	$Id: nanEOF.m 482 2007-09-13 22:08:01Z dmk $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'nanact', 'var' ) || isempty(nanact)
  nanact = 'complete';
end

if ~exist( 'norm', 'var' )
  norm = false;
end

if ~exist( 'trend', 'var' )
  trend = true;
end

s = size(U);
ss = min(s);

% Normalize by standard deviation if desired.
if norm
  norms = nanstd(U,0,1);
  U = U .* repmat(1./norms,[s(1),1]);
else
  norms = ones([1,s(2)]);
end

% Detrend if desired.
if trend
  trends = nanmean(U,1);
  U = U - repmat(trends,[s(1),1]);
else
  trends = zeros([1,s(2)]);
end

disp( 'Starting to calculate covariance matrix.' );

% Compute covariance matrix
CM = nancov( full(U), nanact );

disp( 'Starting to calculate EOFs with svd.' );

% Use svd in to get EOFs and eigenvalues.
[ EOFs, L ] = svd( CM ); 
L = diag( L )'; % eigenvalues.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute EC's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( 'Starting to calculates EC and EC_uncert' );

EC = nan( s(1), size(EOFs,2) );
EC_uncert = zeros( s(1), size(EOFs,2) );

% Begin with complete rows - these are easiest
II = isfinite(U);
I = all( II, 2 );
EC(I,:) = U(I,:) * EOFs; % Expansion coefficients.

if any( all(~II,2) )
  warning('Completely missing rows! EC and EC_uncert trivial for these rows.');
end

% Now do incomplete rows with measurement uncertainty
% This uses results of Davis (1977)
for k = find(~I)'
  disp( [ 'Working on index #' int2str(k) ] );
  i = II(k,:);

  % One step fix for completely missing rows. This is a CLUDGE - completely
  % missing rows should have zero values for EC and error equal to sqrt(L).
  % But the equations below don't return that, probably (hopefuly) due to
  % small rounding errors.  This cludge forces it to known value.
  if all(~i)
    EC(k,:) = 0;
    EC_uncert(k,:) = sqrt(L);
    continue
  end
  
  gamma = EOFs(~i,:)' * EOFs(~i,:);
  H = sum( (gamma.^2) .* ( repmat(L,[numel(L),1]) - diag(L) ), 2 )';
  g = diag(gamma)';
  beta = (1-g).*L ./ ( L .* (1-g).^2 + H );
  EC(k,:) = (beta .* ( U(k,i) * EOFs(i,:) ) );
  EC_uncert(k,:) = sqrt((beta.^2) .* H + L .* (1+beta.*(g-1)).^2);
end

disp( 'Finishing up.' );

% Compute error.
diff=(U-EC*EOFs');
error=sqrt( nansum( diff .* conj(diff) ) );

% Calculate the N for the covariance calculation
if nargout >= 8
  switch nanact
    case 'complete'
      N = sum( all( isfinite(U), 2 ) );
    case 'pairwise'
      N = double(isfinite(U));
      N = N' * N;
  end
end