function l = laplacian_tri( p, t, u )
% LAPLACIAN_TRI
%
% Usage: laplacian = laplacian_tri( p, t, u )
%
% Compute the laplacian of u on the triangular mesh defined by p and t. 
%
% Laplacian will be defined at triangle midpoints, not the nodes (as u
% should be).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: laplacian_tri.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Gradient
[ux,uy] = pdegrad( p, t, u );

% Get gradient at nodes - this involves some information loss
uxn = pdeprtni( p, t, ux );
uyn = pdeprtni( p, t, uy );

% Now take gradient of gradient
[uxx,uxy] = pdegrad( p, t, uxn );
[uyx,uyy] = pdegrad( p, t, uyn );

% Sum is the laplacian
l = uxx + uyy;
