function C = gdop_one_rad_per_site(angles,sites)
%GDOP_ONE_RAD_PER_SITE Compute GDOP using mean radial angle for each site
%
% Usage:
%        C = gdop_max_orthog(angles,sites)
%
% Input:  angles (in degrees), vector of angles, 1xN or Nx1.
%         sites - index of the site corresponding to each angle
% Output: C - the covariance matrix
%
% This calculates GDOP using only the mean radial angle from each site,
% essentially assuming that errors of all radials from each site covary
% perfectly.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: gdop_one_rad_per_site.m 486 2007-09-27 15:59:08Z dmk $
%
% Copyright (C) 2007 David M. Kaplan
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Just to make sure angles are all on same scale.
angles = mod( angles, 360 );

s = unique(sites);
a = zeros(size(s));
for k = 1:numel(s)
  a(k) = angles_mean( angles( sites == s(k) ) );
end

A = [ cosd(a(:)), sind(a(:)) ];
C = inv( (A') * A);
