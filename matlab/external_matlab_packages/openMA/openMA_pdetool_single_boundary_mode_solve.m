function [bound_mode] = openMA_pdetool_single_boundary_mode_solve(pde_fig,ax, ...
						  ob_nums,ob_func,db_num,nt,ni)
% openMA_pdetool_single_boundary_mode_solve
%
% Usage: bound_mode = openMA_pdetool_boundary_mode_solve(pde_fig,ax, ...
%                              ob_nums,ob_func,db_num,nt,ni)
%
% This function solves for a single open boundary mode ala Lipphardt et
% al. 2000.  It is assumed that openMA_pdetool_initial_setup was
% already run to set up domain and that initial mesh resolution has been
% set.
%
% An adaptive mesh technique is used to develop a triangular mesh
% appropriate for that mode.
%
% The mode will not be normalized.
%
% Inputs:
%
% pde_fig = handle of pdetool figure from openMA_pdetool_initial_setup
% 
% ax = handle of pdetool axes from openMA_pdetool_initial_setup
%
% ob_nums = a vector of IDs of the elements of the boundary that have open
% boundary conditions.  These must correspond to the IDs that pdetool
% assigns to the different boundary elements.  Furthermore, the must be
% ordered so that they form a connected set of segments that is oriented the
% same way that the boundary itself is ordered.  If this is not the case,
% the algorithm will not function properly and should generate an error.
%
% ob_func = is a string with the name of the function that
% specifies the boundary conditions.  This function must take a single
% argument, s = the distance along the open boundary, and return the
% normal component of flow at that point(s) along the boundary.  This
% function must be written by the user.  This function should accept both
% single distances and vectors of distances.
%
% db_num = the ID of a short element of the domain boundary that will be
% assigned the dirichlet boundary condition that u=0 along the segment.
% This should not be an element of the open boundary (i.e. not in ob_nums).
% This option exists because the boundary mode is only determined up to a
% constant and matlab tends to make that constant very large if no element
% of the boundary is stuck at zero, causing considerable rounding error.
% The piece of the boundary assigned dirichlet conditions should be very
% small to avoid affecting the results much.  If left off or empty, no such
% boundary element will be used.
%
% nt = maximum number of triangles to use for adaptive mesh.  Defaults to
% 15000.
%
% ni = maximum number of iterations for the adaptive mesh algorithm.
% Defaults to 5.
%
% Outputs:
%
% bound_mode = a structure that contains the mode.  Also contained in the
% mode is the (constant) laplacian corresponding to that mode, as well as
% the equation for the boundary function (basically 'ob_func(s)' ).  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_pdetool_single_boundary_mode_solve.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('ob_nums','var') || isempty(ob_nums)
  error( 'IDs of open border segments must be given.' );
end

if ~exist('db_num','var')
  db_num = [];
end

if ~exist('nt','var') || isempty(nt)
  nt = 15000;
end

if ~exist('ni','var') || isempty(ni)
  ni = 5;
end

% Default mode structure for saving modes.
bound_mode = openMA_default_mode_structure;
bound_mode.mode_type = 'boundary';
bound_mode.boundary_mode_type = 'single';
bound_mode.boundary_conditions = 'neu';
bound_mode.open_boundary_numbers = ob_nums;
bound_mode.special_dirichlet_boundary_number = db_num;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate basic stuff like distance along open border.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ob_cd,ob_sp,ob_ep,dl1] = pde_border_cummulative_distance( pde_fig, ob_nums ...
						  );
% Number of border segments.
ne = size(dl1,2);

% Trick to have all open boundary
if isa(ob_nums,'char') & ob_nums == ':'
  ob_nums = 1:ne;
end

% Get initial mesh configuration and calculate total area of domain
[pinit,einit,tinit] = pdetool_getset_mesh( pde_fig );
pde_area = sum( pdetrg( pinit, tinit ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate integral of boundary function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ss = linspace( 0, ob_cd(end), 1e4 );
xx = feval( ob_func, ss );
lint = sum( 0.5 * (xx(1:end-1)+xx(2:end)) * (ss(2)-ss(1)) );
lapl = lint / pde_area;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial boundary setup - set to Neumann with zeros for default
% This should already be done, but pdetool sometimes get confused after
% repeated applications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:ne
  pdesetbd(k,'neu',1,'0','0')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set special boundary element to force mode close to zero.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(db_num)
  pdesetbd(db_num,'dir',1,'1','0'); % Dirichlet condition u=0
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now solve for mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reinitialize mesh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pdetool_getset_mesh( pde_fig, pinit, einit, tinit );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PDE coefficients:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pdeseteq(1,'1.0','0.0',[ '-' num2str(lapl,'%10.10g') ],...
	 '0.0','0:10','0.0','0.0','[0 1]')
my_setappdata(pde_fig,'currparam', ...
		 str2mat('1.0','0.0',[ '-' num2str(lapl,'%10.10g') ], ...
			 '0.0') )
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Boundary coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for l = 1:length(ob_nums)
  d0 = ob_cd(l);
  cc = ob_sp(l,:);
  ff = [ ob_func '( ' num2str(d0,'%10.10g') ...
	 ' + sqrt((x - ' num2str(cc(1),'%10.10g') ').^2+(y - ' ...
	 num2str(cc(2),'%10.10g') ').^2) ) ' ];
  pdesetbd(ob_nums(l),'neu',1,'0',ff)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and obtain solution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[u,p,e,t] = pdetool_adapt_mesh_solve(pde_fig,nt,ni);
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assure that integral over space is zero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
a = integrate_scalar_tri( p, t, u );
u = u - a/pde_area;
  
% Make string with boundary equation
bequ = [ ob_func '( s )' ];
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save everything.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[bound_mode.u,bound_mode.p, ...
 bound_mode.e,bound_mode.t] = ...
    deal(u,p,e,t);
  
% Keep integral value for future reference
bound_mode.laplacian = lapl;

% Keep boundary function
bound_mode.boundary_equation = bequ;

% Keep integral values for future reference
bound_mode.original_scalar_integral = a;

