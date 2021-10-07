function [emodes,eig_max] = openMA_pdetool_eigenmodes_solve(pde_fig,ax,bc,eig_max,nt,ni)
% openMA_pdetool_eigenmodes_solve
%
% Usage: [emodes,eig_max] = openMA_pdetool_eigenmodes_solve(pde_fig,ax,bc,eig_max,nt,ni)
%
% This function solves for the interior eigenmodes for a given domain.  It
% is assumed that openMA_pdetool_initial_setup was already run to set up the
% domain and that the initial mesh resolution has been set.  It will
% solve for eigenmodes with either Neumann or Dirichlet boundary conditions.
%
% The method uses an adaptive mesh technique to first develop a more
% precise mesh for the highest eigenvalue that will be tested.  Then it
% solves for the eigenmodes using that mesh.  All modes will be solved
% for with the same mesh. 
% 
% Modes are normalized so that the L2-norm of the currents is 1.
%
% NOTE: This function will sometimes fail after running
% openMA_pdetool_boundary_modes_solve due to a bug in the pdetool.
%
% Inputs:
%
% pde_fig = handle of pdetool figure from openMA_pdetool_initial_setup
% 
% ax = handle of pdetool axes from openMA_pdetool_initial_setup
%
% bc = a string saying which type of boundary conditions to use: 'neu' or 'dir'
%
% eig_max = maximum eigenvalue to test for eigenmodes.  eig_max can also be
% a pair of values specifying a range of eigenvalues - the first value must
% be smaller than the second value.  Defaults to finding approximately ten
% eigenvalues starting from zero.
%
% nt = maximum number of triangles to use for adaptive mesh.  Defaults to 15000.
%
% ni = maximum number of iterations for the adaptive mesh algorithm.
% Defaults to 5.
%
% Outputs:
%
% emodes = an array of structures with the modes.  For consistency
% and possible future use, each element of the array has the triangular mesh
% information, even though the grid should be the same for all modes.
% This is done just in case a better method with a different triangular
% grid for each mode is developed in the future.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_pdetool_eigenmodes_solve.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Number of border segments.
ne = size(my_getappdata(pde_fig,'dl1'),2);

% Set maximum eigenvalue to look for
if nargin < 4 | isempty( eig_max )
  n = 10; % Approximate number of eigenvalues you want.
  
  % Get initial mesh configuration and calculate total area of domain
  [pinit,einit,tinit] = pdetool_getset_mesh( pde_fig );
  pde_area = sum( pdetrg( pinit, tinit ) );
  
  % The eigenvalues for a square of area A goes as pi^2*r^2/A where
  % r^2=k^2+l^2, for two positive integers k and l.  Therefore, if you want
  % n eigenvalues, then n = pi * r^2 / 4, so the maximum eigenvalue should
  % be:
  max_rad = sqrt(4*n/pi);
  eig_max = pi^2 * max_rad^2 / pde_area;
end

% If scalar, make a two element vector.
if prod(size(eig_max)) == 1
  eig_max = [ 1e-9 eig_max ];
end

if prod(size(eig_max)) ~= 2
  warning( 'eig_max is wrong size' );
end

if nargin < 5 | isempty(nt)
  nt = 15000;
end

if nargin < 6 | isempty(ni)
  ni = 5;
end

% Default mode structure for saving modes.
dms = openMA_default_mode_structure;
dms.mode_type = 'eigen';
dms.boundary_conditions = bc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do initial elliptic problem with adaptive mesh to get good mesh.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial boundary setup
my_pdesetbd( ne, bc );

% Solve parameters:
my_setappdata(pde_fig,'solveparam',...
		 str2mat('0','1008','10','pdeadworst',...
			 '0.5','longest','0','1E-4','','fixed','Inf'))

% Set pde equations to solve elliptic problem with a=-eig_max and f=1
pdeseteq(1,'1.0',[ '(' num2str(-eig_max(end),'%0.10g') ')' ],'1.0',...
	 '0.0','0:10','0.0','0.0','[0 1]')
my_setappdata(pde_fig,'currparam', ...
		 str2mat('1.0',[ '(' num2str(-eig_max(end),'%0.10g') ')' ], ...
			 '1.0','0.0') )

% Do solution just to get a good mesh.
[u,p,e,t] = pdetool_adapt_mesh_solve(pde_fig,nt,ni);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now solve for modes.  Begin with Neumann modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial boundary setup - this shouldn't strictly speaking be necessary
% to set again - just doing it for safety.
my_pdesetbd( ne, bc );

% Set PDE coefficients just once
pdeseteq(4,'1.0','0.0','0.0','1.0','0:10','0.0','0.0',...
	 [ '[ ' num2str(eig_max(1), '%10.10g') ' ' ...
	   num2str(eig_max(2), '%10.10g') ' ]' ])

% Solve parameters:
my_setappdata(pde_fig,'solveparam',...
		 str2mat('0','1008','10','pdeadworst',...
			 '0.5','longest','0','1E-4','','fixed','Inf'))

% Solve problem.
pdetool('solve')
l=get(findobj(get(pde_fig,'Children'),'flat','Tag','winmenu'),...
      'UserData');
u=get(findobj(get(pde_fig,'Children'),'flat','Tag','PDEPlotMenu'),...
      'UserData');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop over modes and put them in the
% correct place - this is for compatibility
% with future methods of doing things that might
% use a different mesh for each mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(l)
  emodes(k) = dms;
  emodes(k).lambda = l(k);
  
  [emodes(k).p,emodes(k).e,emodes(k).t] ...
      = deal(p,e,t);
  
  uu = u(:,k);
  
  % Normalize mode.
  [ng,uu] = norm_gradient_scalar_tri( p, t, uu );

  % Record mode and original normalization.
  emodes(k).u = uu;  
  emodes(k).original_current_norm = ng;
  
  emodes(k).mode_number = k;
end

% Just in case there are no modes.
if exist('emodes') ~= 1
  emodes = [];
end


%%%--------------Subfunctions---------------%%%
function my_pdesetbd( ne, bc )

bc = lower(bc(1:3));

switch bc
 case 'neu'
  aa = '0';
 case 'dir'
  aa = '1';
 otherwise
  error('Unknown type of boundary conditions');
end

pdesetbd(1:ne,bc,1,aa,'0')

