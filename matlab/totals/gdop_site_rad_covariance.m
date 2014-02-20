function C = gdop_site_rad_covariance(angles,sites)
%GDOP_SITE_RAD_COVARIANCE Compute GDOP assuming radials for each site covary
%
% Usage:
%        C = gdop_site_rad_covariance(angles,sites)
%
% Input:  angles (in degrees), vector of angles, 1xN or Nx1.
%         sites - index of the site corresponding to each angle
% Output: C - the covariance matrix
%
% This calculates GDOP assuming perfect covariance of uncertainties for
% radials from the same site (but zero covariance for radials from
% different sites).  This should produce similar, but somewhat different
% results than gdop_one_rad_per_site.m
%
% IMPORTANT NOTE: This does not behave as one would expect.  If all
% measurements perfectly covary, this tends to produce a low uncertainty,
% which can't be correct.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: gdop_site_rad_covariance.m 636 2008-03-31 06:56:14Z dmk $
%
% Copyright (C) 2007 David M. Kaplan
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Compute covariance matrix for radials.
[CC1,CC2] = meshgrid( sites(:), sites(:)' );
CC = double(CC1 == CC2);

% Matrix of u,v components corresponding to radial directions
A = [ cosd(angles(:)), sind(angles(:)) ];

% Straight GDOP
C = inv( (A') * A );

% GDOP including covariance matrix
C = C * (A') * CC * A * C;
