function d = openMA_default_mode_structure
% OPENMA_DEFAULT_MODE_STRUCTURE
%
% This function just returns a structure with the default format for
% openMA modes.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_default_mode_structure.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ d.p, d.e, d.t, d.u ] = deal([]);

[d.mode_number,d.lambda,d.laplacian] = deal(NaN);
[d.original_scalar_integral,d.original_current_norm] = deal(NaN);

d.boundary_equation = '';
d.boundary_conditions = '';
d.boundary_mode_type = '';
d.mode_type = '';

d.open_boundary_numbers = NaN;
d.special_dirichlet_boundary_number = NaN;
