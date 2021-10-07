function [ ux, uy ] = pdegrad_multi_col( p, t, u, varargin )
% PDEGRAD_MULTI_COL - computes gradient of multiple scalar fields at
% once.  
%
% Usage: [ ux, uy ] = pdegrad_multi_col( p, t, u )
%
% Where u can have multiple columns, each of which is a scalar field.  ux
% and uy will have one row for each triangle and one column for each
% column of u.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: pdegrad_multi_col.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ux,uy] = deal( zeros( size(t,2), size(u,2) ) );

for k = 1:size(u,2)
  [uux,uuy] = pdegrad( p, t, u(:,k), varargin{:} );
  [ux(:,k),uy(:,k)] = deal( uux(:), uuy(:) );
end

