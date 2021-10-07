function [ux,uy] = openMA_modes_group_same_grid( nm, dm, bm )
% OPENMA_MODES_GROUP_SAME_GRID - Simple function to group modes 
% together that were created on a single triangular grid.
%
% Usage: [uu] = openMA_modes_group_same_grid( vfm, dfm, bm )
%        [ux,uy] = openMA_modes_group_same_grid( vfm, dfm, bm )
%
% You would use this function if you created a bunch of modes using, for
% example, openMA_pdetool_neumann_modes_solve, etc., but did so on a single
% triangular mesh (i.e. you turned off adaptive mesh).  This function just
% runs through modes and puts them in matrices.  It works similar to
% openMA_modes_interp, but no interpolation is done and it is assumed all
% modes are on the same grid as the first vfm mode.
%
% If the function is given one output arguments, then the modes
% themselves are returned.  If the function is given two output
% arguments then the current fields of each mode, evaluated at the
% triangle center, is returned.
%
% The different modes groups can be left off or empty and the function will
% work as expected.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_modes_group_same_grid.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('dm','var')
  dm = [];
end

if ~exist('bm','var')
  bm = [];
end

nnn = length(nm) + length(dm) + length(bm);

if nnn == 0
  warning( 'No data given' )
  ux = [];
  if nargout > 1, uy = []; end
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put modes together.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargout <= 1
  % Need to do this to deal with missing mode structures.
  ux = [];
  try
    ux = [ ux, nm.u ];
  end
  try
    ux = [ ux, dm.u ];
  end
  try
    ux = [ ux, bm.u ];
  end

  return
else 
  % Need to do this for missing mode structures.
  try
    p = nm(1).p;
    t = nm(1).t;
  catch 
    try
      p = dm(1).p;
      t = dm(1).t;
    catch
      p = bm(1).p;
      t = bm(1).t;  
    end
  end      
  
  % Want vector velocities from pdegrad.
  [ux,uy] = deal( zeros(size(t,2),nnn) );
  
  nn = 0; % Counter.
  
  % Neumann
  if ~isempty( nm )
    nn = nn(end) + (1:length(nm));
    [ ux(:,nn), uy(:,nn) ] = pdegrad_multi_col( p, t, [ nm.u ] );
  end
  
  % Dirichlet
  if ~isempty( dm )
    nn = nn(end) + (1:length(dm));
    [ a, b ] = pdegrad_multi_col( p, t, [ dm.u ] );
    [ ux(:,nn), uy(:,nn) ] = deal( -b, a ); % -b fixes sign
  end
  
  % Boundary
  if ~isempty( bm )
    nn = nn(end) + (1:length(bm));
    [ ux(:,nn), uy(:,nn) ] = pdegrad_multi_col( p, t, [ bm.u ] );
  end
  
end

