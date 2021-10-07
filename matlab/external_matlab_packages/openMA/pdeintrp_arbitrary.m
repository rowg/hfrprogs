function [ux,uy] = pdeintrp_arbitrary( cc, p, t, u1, u2 )
% PDEINTRP_ARBITRARY - Like PDEINTRP in the PDE Toolbox, but interpolates
% at an arbitrary set of points, not just triangle centers.
%
% Usage:        cc = pdeintrp_arbitrary( cc, p, t )
%               UI = pdeintrp_arbitrary( cc, p, t, U )
%        [UXI,UYI] = pdeintrp_arbitrary( cc, p, t, U )
%        [UXI,UYI] = pdeintrp_arbitrary( cc, p, t, UX, UY )
%
% cc is a two or five column matrix.  The first two columns specify the
% points at which the interpolation should take place.  The optional third,
% fourth and fifth columns indicates the triangles that each point lies in
% and two of the barycentric coordinates (see tri2pts for details).  These
% columns can be used to significantly speed up this function if the
% triangles have already been determined and the function will be called
% multiple times with the same triangular grid and interpolation points.
%
% p and t are the points and triangles of a triangular mesh grid.  These
% should be in the format used by the PDE toolbox (i.e. matrices with
% many columns and few rows).
%
% U is a scalar field or fields defined at the points in p in the form that
% the PDE toolbox uses (lots of rows).  If U has multiple columns, then
% the interpolation will be performed on each column.
%
% UX and UY are the components of a vector field(s) defined on the triangles
% centers (as pdegrad would produce).  As with U, multiple columns will
% each be interpolated separately.
%
% The first form of the function just returns cc with the additional columns
% that contains the extra information for speeding up this function on
% additional calls.  NOTE that this function does nothing if the input cc
% already has a third column.
%
% The second form interpolates the scalar field U at the points contained in
% cc.  In this form, the routine does linear interpolation in the triangles
% that surround the points in cc.  Each column of UI corresponds to a
% column of U.
%
% In the third form, the interpolation is on the gradient of the scalar
% field U.  In this form, the interpolation simply returns the planar
% gradient of the triangle containing each point in cc (i.e. the gradient
% is considered constant over each triangle).  Each column of UXI
% corresponds to a column of U.
%
% The last form should be used if one has already used pdegrad to calculate
% the gradient of the scalar field.  This will improve the efficiency of
% this function for multiple iterations.
%
% NOTE: This function knows nothing about vorticity and divergence modes,
% so you will need to rotate the vectors by hand if you are dealing with
% divergence-free modes (aka vorticity modes)!!
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: pdeintrp_arbitrary.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  error( 'Insufficient input arguments' );
end

% Use extra columns of cc if available for speed.
if size(cc,2) == 5
  [tn,a12,a13] = deal( cc(:,3), cc(:,4), cc(:,5) );
else
  [tn,a12,a13] = tsearch_arbitrary( p, t, cc(:,1), cc(:,2) );
end

% If 3 input arguments, just return cc with third column.
if nargin < 4
  if size(cc,2) < 3
    cc(:,3:5) = [tn,a12,a13];
  end
  ux = cc;
  return
end

switch nargout
 case 1
  % Interpolate scalar field
  ux = tri2pts( p, t, u1, tn, a12, a13 );
  
 case 2
  % Interpolate gradient of scalar field
  % Just return value inside triangle.

  % Remove points outside domain - they will be put back in the end.
  ii = isnan( tn );
  tn = tn( ~ii );
  cc = cc( ~ii, : );

  if nargin < 5
    [ux,uy] = deal( zeros( length(tn), size(u1,2) ) );
    for k = 1:size(u1,2)
      [uu,vv] = pdegrad( p, t(:,tn), u1(:,k) );
      [ux(:,k),uy(:,k)] = deal(uu',vv');
    end
  else
    [ux,uy] = deal( u1( tn, : ), u2( tn, : ) );    
  end

  % Put back NaNs
  ux( ~ii, : ) = ux;
  ux(  ii, : ) = NaN;
  
  if nargout > 1
    uy( ~ii, : ) = uy;
    uy(  ii, : ) = NaN;
  end
 otherwise
  error('Wrong number of output arguments');
end
