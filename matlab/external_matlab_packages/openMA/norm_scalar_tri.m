function [nn,u] = norm_scalar_tri( p, t, u )
% NORM_SCALAR_TRI - computes norm of a scalar
% function defined on a triangular mesh.
%
% Usage: [norm,unorm] = norm_scalar_tri( p, t, u )
%
% where p and t define the triangular mesh, u is the scalar function (most
% likely a pde mode), norm is the L2 norm of u and unorm is u/norm.  The
% second output argument is optional.
%
% Note that norm is divided by the area of the domain, i.e. it is the
% squareroot of the intergral of the magnitude of u over the domain divided
% by the squareroot of the area of the domain.  This will result in a
% scalar function whose values are of order 1.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: norm_scalar_tri.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

area = pdetrg( p, t );
ii = integrate_scalar_tri( p, t, u.^2 );

nn = sqrt( ii / sum(area) );

if nargout > 1
  u = u / nn;
end
