function eig_max = calculate_max_eigenvalue_square( min_dist, scale_factor )
% CALCULATE_MAX_EIGENVALUE_SQUARE - calculates that maximum eigenvalue that
% would produce a mode with a given spatial scale, assuming that the
% domain is a square.  This assumption works well for most domains that
% are roughly circular or rectangular.
%
% Usage: eig_max = calculate_max_eigenvalue_square( min_dist, scale_factor )
%
% min_dist is the minimum spatial scale of the mode.  
%
% scale_factor converts between the units of min_dist and the units that the
% modes will be calculated in.  For example, if min_dist is in km, and the
% modes are calculated on a domain of unit area, then scale_factor =
% sqrt(domain_area).  This argument is OPTIONAL and DEFAULTS to 1 if absent.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: calculate_max_eigenvalue_square.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('scale_factor','var')
  scale_factor = 1;
end

min_dist = min_dist ./ scale_factor;
eig_max = ( pi / min_dist ) .^ 2;

