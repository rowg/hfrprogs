function ip = inner_product_gradient_scalar_tri( p, t, ux1, uy1, ux2, uy2 )
% INNER_PRODUCT_GRADIENT_SCALAR_TRI - computes the "inner product"
% between two current fields defined on a single triangular grid.
%
% Usage: ip = inner_product_gradient_scalar_tri( p, t, u1, u2 )
%        ip = inner_product_gradient_scalar_tri( p, t, ux1, uy1, ux2, uy2 )
%
% The inner product is defined at the integral of the dot product of the
% two current fields divided by the total area.
%
% In the first form, u1 and u2 are scalar fields defined at the points in
% p.  The gradient of each field will be taken and then the inner product
% will be calculated.
%
% In the second form, (ux1,uy1) and (ux2,uy2) are a pair of current
% fields defined at the centers of the triangles in t.
%
% u1,u2 or uxN,uyN can have multiple columns, in which case the inner
% product will be calculated for each column.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: inner_product_gradient_scalar_tri.m 81 2007-03-21 21:38:39Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6
  [ux2,uy2] = pdegrad_multi_col( p, t, uy1 );
  [ux1,uy1] = pdegrad_multi_col( p, t, ux1 );
end

% Make sure vectors are columns not rows
if isvector(ux1)
  ux1 = ux1(:);
  uy1 = uy1(:);
  ux2 = ux2(:);
  uy2 = uy2(:);
end

area = pdetrg( p, t );

ip = sum( repmat(area(:),[1,size(ux1,2)]) .* (ux1.*ux2 + uy1.*uy2) ) / sum(area);
