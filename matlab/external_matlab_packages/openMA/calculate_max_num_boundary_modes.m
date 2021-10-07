function num_bound_modes = calculate_max_num_boundary_modes( open_bound_length, ...
						  min_dist, scale_factor )
% CALCULATE_MAX_NUM_BOUNDARY_MODES - calculates the number of (sin or cos)
% boundary modes to use to get a certain spatial scale of accuracy.  
%
% Usage: num_bound_modes = calculate_max_num_boundary_modes( ...
%                               open_bound_length, min_dist, scale_factor )
%
% open_bound_length is the total length of the open boundary.
%
% min_dist is the minimum spatial scale of the mode.  
%
% scale_factor converts between the units of min_dist and the units of
% open_bound_length.  For example, if min_dist is in km, and
% open_bound_length is in the normalized units where the domain has unit
% area, then scale_factor = sqrt(domain_area).  This argument is OPTIONAL
% and DEFAULTS to 1 if absent.
%
% num_bound_modes is the number of sine or cosine boundary modes to use.
% For example, if num_bound_modes = 5, then one would typically use a
% total of 11 boundary modes (1 constant, 5 cosine and 5 sine).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: calculate_max_num_boundary_modes.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('scale_factor','var')
  scale_factor = 1;
end

min_dist = min_dist ./ scale_factor;
num_bound_modes = floor(open_bound_length / min_dist / 2);

%
% As modes are like cos( 2*pi*k*l/L), 
% the spatial scale of a mode is l = L/(2k) (a half wavelength)
% or the maximum k should be L/(2l)
%
