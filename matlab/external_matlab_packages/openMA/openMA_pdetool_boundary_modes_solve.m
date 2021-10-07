function [bound_modes] = openMA_pdetool_boundary_modes_solve(pde_fig,ax, ...
						  n_modes,ob_nums,db_num,nt,ni)
% openMA_pdetool_boundary_modes_solve
%
% Usage: bound_modes = openMA_pdetool_boundary_modes_solve(pde_fig,ax,n_modes,ob_nums,db_num,nt,ni)
%
% This function solves for constant, cosine and sine boundary modes of a
% given pde domain. It is assumed that openMA_pdetool_initial_setup was
% already run to set up domain and that initial mesh resolution has been
% set.
%
% For each mode, an adaptive mesh technique is used to develop a
% triangular mesh appropriate for that mode.
%
% Modes are normalized so that the L2-norm of the currents is 1.  This
% will affect the normalization of the boundary functions used to define
% the modes.  This information is maintained in the outputs through the
% value of the laplacian and the textual form of the equation of the
% boundary function.
%
% Inputs:
%
% pde_fig = handle of pdetool figure from openMA_pdetool_initial_setup
% 
% ax = handle of pdetool axes from openMA_pdetool_initial_setup
%
% n_modes = a three element vector with the number of constant modes (0
% or 1), cosine modes and sine modes.
%
% ob_nums = a vector of IDs of the elements of the boundary that have open
% boundary conditions.  These must correspond to the IDs that pdetool
% assigns to the different boundary elements.  Furthermore, the must be
% ordered so that they form a connected set of segments that is oriented the
% same way that the boundary itself is ordered.  If this is not the case,
% the algorithm will not function properly and should generate an error.
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
% bound_modes = an array of structures with the constant, cosine and sine
% boundary modes.  Each structure of the array is one mode.  Each mode
% contains the mode data, as well as metadata about what type and number
% mode it is.  In the equation for the boundary function, s denotes position
% along the open boundary and S denotes the total length of the open
% boundary.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_pdetool_boundary_modes_solve.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of sin and cosine modes to solve for
if ~exist('n_modes','var') || isempty(n_modes)
  n_modes = [1,5,5];
end

if prod(size(n_modes)) ~= 3
  error( 'n_modes poorly formed.  Must be 3 element vector.' );
end

% Define open border segments - must be in appropriate spatial order
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
dms = openMA_default_mode_structure;
dms.mode_type = 'boundary';
dms.boundary_conditions = 'neu';
dms.open_boundary_numbers = ob_nums;
dms.special_dirichlet_boundary_number = db_num;

bound_modes = dms;

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

% Clear boundary conditions just to be sure.
%pdeclearbd(1:ne,100);

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
% Now solve for modes.  Begin with constant mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if n_modes(1)
  % Boundary intergral - This is the initial integral.  It will be
  % modified by the normalization constant.
  bint = ob_cd(end) / pde_area;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Reinitialize mesh
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pdetool_getset_mesh( pde_fig, pinit, einit, tinit );
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % PDE coefficients:
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pdeseteq(1,'1.0','0.0',[ '-' num2str(bint,'%10.10g') ],...
	   '0.0','0:10','0.0','0.0','[0 1]')
  my_setappdata(pde_fig,'currparam', ...
		   str2mat('1.0','0.0',[ '-' num2str(bint,'%10.10g') ], ...
			   '0.0') )
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Boundary coefficients
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for k = 1:length(ob_nums)
    pdesetbd(ob_nums(k),'neu',1,'0','1')
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
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Normalize mode
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [ng,u] = norm_gradient_scalar_tri( p, t, u );
  
  % Fix bint for new normalization
  bint = bint / ng;

  % Make string with boundary equation
  bequ = [ num2str( 1 / ng, '%10.10g' ) ];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save everything.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  bound_modes(end+1) = dms;
  [bound_modes(end).u,bound_modes(end).p, ...
   bound_modes(end).e,bound_modes(end).t] = ...
      deal(u,p,e,t);
  
  % Keep integral values for future reference
  bound_modes(end).original_scalar_integral = a;
  bound_modes(end).original_current_norm = ng;
  bound_modes(end).laplacian = bint;

  % Keep boundary function
  bound_modes(end).boundary_equation = bequ;

  % Keep mode number - k 
  bound_modes(end).mode_number = 0;

  % Define type
  bound_modes(end).boundary_mode_type = 'constant';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now solve for modes.  Cosine modes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PDE coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% As boundary integral is always zero, coefficients stay the same.
pdeseteq(1,'1.0','0.0','0.0',...
	 '0.0','0:10','0.0','0.0','[0 1]')
my_setappdata(pde_fig,'currparam', ...
		 str2mat('1.0','0.0','0.0', ...
			 '0.0') )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over modes and calculate stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k=1:n_modes(2)
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Reinitialize mesh
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pdetool_getset_mesh( pde_fig, pinit, einit, tinit );
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Boundary coefficients
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  md = ob_cd(end);
  for l = 1:length(ob_nums)
    d0 = ob_cd(l);
    cc = ob_sp(l,:);
    ff = [ 'cos( 2 * pi * ' int2str(k) ' * ( ' num2str(d0,'%10.10g') ...
	   ' + sqrt((x - ' num2str(cc(1),'%10.10g') ').^2+(y - ' ...
	   num2str(cc(2),'%10.10g') ').^2)) /' num2str(md,'%10.10g') ...
	   ')' ];
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
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Normalize mode
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [ng,u] = norm_gradient_scalar_tri( p, t, u );
  
  % Fix bint for new normalization
  bint = 0;

  % Make string with boundary equation
  bequ = [ num2str( 1 / ng, '%10.10g' ) ' * cos( 2*pi*' int2str(k) ...
	 '*s/S )' ];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save everything.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  bound_modes(end+1) = dms;
  [bound_modes(end).u,bound_modes(end).p, ...
   bound_modes(end).e,bound_modes(end).t] = ...
      deal(u,p,e,t);
  
  % Keep integral values for future reference
  bound_modes(end).original_scalar_integral = a;
  bound_modes(end).original_current_norm = ng;
  bound_modes(end).laplacian = bint;

  % Keep boundary function
  bound_modes(end).boundary_equation = bequ;

  % Keep mode number - k 
  bound_modes(end).mode_number = k;

  % Define type
  bound_modes(end).boundary_mode_type = 'cosine';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now solve for modes.  Sine modes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PDE coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% As boundary integral is always zero, coefficients stay the same.
pdeseteq(1,'1.0','0.0','0.0',...
	 '0.0','0:10','0.0','0.0','[0 1]')
my_setappdata(pde_fig,'currparam', ...
		 str2mat('1.0','0.0','0.0', ...
			 '0.0') )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over modes and calculate stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k=1:n_modes(3)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Reinitialize mesh
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pdetool_getset_mesh( pde_fig, pinit, einit, tinit );
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Boundary coefficients
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  md = ob_cd(end);
  for l = 1:length(ob_nums)
    d0 = ob_cd(l);
    cc = ob_sp(l,:);
    ff = [ 'sin( 2 * pi * ' int2str(k) ' * ( ' num2str(d0,'%10.10g') ...
	   ' + sqrt((x - ' num2str(cc(1),'%10.10g') ').^2+(y - ' ...
	   num2str(cc(2),'%10.10g') ').^2)) /' num2str(md,'%10.10g') ...
	   ')' ];
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
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Normalize mode
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [ng,u] = norm_gradient_scalar_tri( p, t, u );
  
  % Fix bint for new normalization
  bint = 0;

  % Make string with boundary equation
  bequ = [ num2str( 1 / ng, '%10.10g' ) ' * sin( 2*pi*' int2str(k) ...
	 '*s/S )' ];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save everything.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  bound_modes(end+1) = dms;
  [bound_modes(end).u,bound_modes(end).p, ...
   bound_modes(end).e,bound_modes(end).t] = ...
      deal(u,p,e,t);
  
  % Keep integral values for future reference
  bound_modes(end).original_scalar_integral = a;
  bound_modes(end).original_current_norm = ng;
  bound_modes(end).laplacian = bint;

  % Keep boundary function
  bound_modes(end).boundary_equation = bequ;

  % Keep mode number - k 
  bound_modes(end).mode_number = k;

  % Define type
  bound_modes(end).boundary_mode_type = 'sine';
end

bound_modes = bound_modes(2:end);


%%%---------------------Subfunctions--------------------%%%
function pdeclearbd(b,l)
pdesetbd(b,'neu',1,repmat(' ',[1,l]),repmat(' ',[1,l]))

% The above function was a hack attempt to fix a problem with pdetool
% that it retains somehow pieces of the boundary conditions that can
% later cause problems if openMA_pdetool_eigenmodes_solve is run with
% Dirichlet boundary conditions.  This did not fix the problem.
