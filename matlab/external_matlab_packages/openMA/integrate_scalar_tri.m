function gn = integrate_scalar_tri( p, t, u )
% INTEGRATE_SCALAR_TRI - computes the integral of a scalar function
% defined at the nodes of a triangular mesh over the pde domain.
%
% Usage: integral = integrate_scalar_tri( p, t, u )
%
% where p and t define the triangular mesh, u is the scalar function
% (most likely a pde mode), and integral is the integral of u over the
% domain defined by p and t.
%
% u can either be node data or triangle center data.  It can also be a
% scalar and you just get the area of the domain times the scalar.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: integrate_scalar_tri.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

area = pdetrg( p, t );

if length(u) == max(size(p)) % Node data
  u = u(t(1,:)) + u(t(2,:)) + u(t(3,:));
  u = u / 3;
elseif length(u) == length(area) % Center data
  % Nothing to do.
elseif prod(size(u)) == 1
  % Nothing to do.
else
  error( 'u appears to be the wrong size.' );
end

gn = sum( u(:) .* area(:) );
