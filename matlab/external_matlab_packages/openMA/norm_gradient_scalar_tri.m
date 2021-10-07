function [gn,u] = norm_gradient_scalar_tri( p, t, u )
% NORM_GRADIENT_SCALAR_TRI - computes norm of the gradient of a scalar
% function defined on a triangular mesh.
%
% Usage: [gradnorm,unorm] = norm_gradient_scalar_tri( p, t, u )
%
% where p and t define the triangular mesh, u is the scalar function
% (most likely a pde mode), gradnorm is the L2 norm of the gradient of u
% and unorm is u/gradnorm.  The second output argument is optional.
%
% Note that gradnorm is normalized by the area of the domain, i.e. it is the
% squareroot of the intergral of the magnitude of the gradient of u over the
% domain divided by the squareroot of the area of the domain.  I do this so
% that the norm has the same units as the gradient, and not the units of the
% gradient times area.  This will result in currents that are of order 1
% magnitude.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: norm_gradient_scalar_tri.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ux,uy] = pdegrad( p, t, u );
area = pdetrg( p, t );

gn = sqrt( sum( area .* (ux.^2 + uy.^2) ) / sum(area) );

if nargout > 1
  u = u / gn;
end
