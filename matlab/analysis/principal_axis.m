function [a, LL] = principal_axis( U, V )
% PRINCIPAL_AXIS  Finds principal axis of each totals grid point
%
% Usage: [angles, variances] = principal_axis( U, V )
%
% This function returns the direction of the principal axis (in degrees) of
% each grip point of total currents data.  It removes bad data before doing
% the calculation.  The mean of each series is also removed before
% calculation.  It is assumed that U and V are matrices, each row of
% which is a grid point and each column is an element of the time series
% (as they would be in a TUV structure).
%
% It will also optionally return the variances explained by the major and
% minor axes.
%
% The negative of the angles returned can be used in rotateTotals to place
% each series on it's principal axis.
%
% NOTE: This function may become VERY slow for large matrices.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: principal_axis.m 430 2007-05-23 02:09:17Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Remove means.
UM = nanmean( U, 2 );
VM = nanmean( V, 2 );
U = U - repmat(UM,size(U)./size(UM));
V = V - repmat(VM,size(V)./size(VM));

% Locations of good data
gd = isfinite(U + V);

a = zeros( size(U,1), 1 );
LL = zeros( size(U,1), 2 );
for i = 1:size(U,1)
  hh = [ U(i,gd(i,:)); V(i,gd(i,:)) ]';

  if ~isempty(hh) && size(hh,1) > 2
    [v,d] = eig(cov(hh));
    [d,I] = sort(diag(d),1,'descend');
    v = v(:,I);

    a(i) = degrees(atan2(v(2,1),v(1,1)));
    LL(i,:) = d(:);
  else
    a(i) = NaN;
    LL(i,:) = NaN;
  end
end

  
