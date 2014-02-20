function generate_OMA_modes(fn,border,spatthresh,ob_nums,db_nums,nt,ni,kb)
% GENERATE_OMA_MODES   Generates OMA modes inside a Lon,Lat domain
% boundary to a particular spatial resolution.
%
% Usage: generate_OMA_modes( filename, LonLat, spatthresh, ...
%                         open_boundary_nums, dirichlet_boundary_nums, ...
%                         num_triangles, num_iterations, kbd )
% 
% Most of the inputs are best explained in functions like
% openMA_pdetool_boundary_modes_solve,
% openMA_pdetool_eigenmodes_solve_to_eigmax and openMA/readme.  Here I will
% just give the basics of how they are used.  Note that some of the inputs
% here are somewhat different from those in the aforementioned functions
% because this function is more general than those, but the basic concepts
% are the same.
%
% NOTE: This function uses m_map to convert from Lon,Lat to a normalized
% coordinate system that is appropriate for mode generation.  It is VERY
% IMPORTANT that the m_map projection be initialized correctly BEFORE
% running this function using m_proj and that that projection be a
% suitable projection of the domain area onto a flat surface!!!!
%
% NOTE: When generating ux_tri,uy_tri (the current velocities associated
% with the modes), these are first calculated in the xy coordinate system
% and then converted to the Lon,Lat coordinate system.  It is assumed that
% the xy coordinate system may be rotated with respect to the Lon,Lat
% coordinate system and the currents are rotated appropriately to take this
% into account.  Further rotation/stretching of currents are not attempted
% because it is assumed that the coordinate system and spatial scales are
% such that the earth is locally not that different from a flat surface.
%
% Inputs
% ------
% filename = name of file to save modes in.  These are saved immediately
%            to reduce memory usage during this function.
% LonLat = Two column matrix of coordinates of the boundary of the OMA
%          domain.
% spatthresh = minimum spatial scale of the modes in km. Typically something
%              like 5 or 10 (km).
% open_boundary_nums = cell array of ordered vectors of numbers
%                      corresponding to the numerical labels used by pdetool
%                      for the edges of the domain along the open boundary.
%                      These numbers might be different from order in file
%                      and must be ordered in a cartesian sense.  Each of
%                      these vectors corresponds to an individual open
%                      boundary.  Will default to {} if not given.
% dirichlet_boundary_nums = cell array of indices of a single small segment
%                           along the closed boundary that will be given
%                           Dirichlet boundary conditions when calculating
%                           open boundary modes - cludge to fix instability
%                           in pdetool solver method.  There must be one of
%                           these for each open boundary, but they can be
%                           empty to not use this feature.  This is
%                           explained in more detail in openMA/readme.
%                           Will default to {} if not given.
% num_triangles, num_iterations = maximum numbers of triangles and
%                                 iterations for the grid refinement.  If
%                                 empty or not given, will assume
%                                 defaults in the various mode generation
%                                 functions from openMA.
% kbd = a boolean indicating whether or not to drop to keyboard in
%       several key places of the function.  Useful for determining open
%       and dirichlet boundary numbers in PDETOOL.  Defaults to false.
%
%
% There are no outputs to this function.  All important results are saved
% in the file.  NOTE: This file could be VERY large.  Make sure to have
% relatively few things open when generating modes and to have sufficient
% disk space to save it all.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: generate_OMA_modes.m 636 2008-03-31 06:56:14Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameter defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('kb','var') || isempty(kb)
  kb = false;
end
if ~exist('nt','var') || isempty(nt)
  nt = [];
end
if ~exist('ni','var') || isempty(ni)
  ni = [];
end
if ~exist('ob_nums','var'), ob_nums = {}; end
if ~exist('db_nums','var'), db_nums = {}; end

% Start saving
[aa,bb] = fileparts( fn );
[cc,bb] = fileparts( tempname );
tfn = fullfile( aa, [ 'OMA_temp_file_' bb '.mat' ] );

special_dirichlet_boundary_nums = db_nums;
open_boundary_nums = ob_nums;
save( tfn, 'special_dirichlet_boundary_nums', 'open_boundary_nums' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Warn about m_map projection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( 'NOTE: The following m_map projection will be used for calculations:' );
m_proj('set')
%m_proj('get')
disp( 'NOTE: If this is not correct, all calculations could be bad.' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert border to normalized units.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pick origin roughly in center of domain
origin = mean(border);
[origin_proj(1),origin_proj(2)] = m_ll2xy( origin(1), origin(2) );

% Border of domain in projection coordinate system
[ border_proj(:,1), border_proj(:,2) ] = m_ll2xy( border(:,1), border(:,2) );

% Area of domain in projection coordinate system
domain_area_proj = polyarea( border_proj(:,1), border_proj(:,2) );

% Border of domain in normalized coordinate system.
border_n = m_ll2normcoords( origin, border, domain_area_proj );

save( tfn, 'origin', 'origin_proj', 'border', 'border_proj', 'border_n', ...
      'domain_area_proj', '-APPEND' );

% Factor for converting projection coordinate system to km - this is
% rough, but should be correct to meters if the projection is good over
% the size of the domain.
dd = origin + 0.1 * ( max(border) - origin );
[dd_proj(1),dd_proj(2)] = m_ll2xy( dd(1), dd(2) );
dd_proj = dd_proj - origin_proj;
proj_to_km_factor = m_idist( origin(1), origin(2), dd(1), dd(2) ) / ...
    sqrt(sum(dd_proj.^2)) / 1e3;

% Get area in km - useful for max eigenvalue calculations
domain_area_km = domain_area_proj * proj_to_km_factor^2;

save( tfn, 'proj_to_km_factor','domain_area_km', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some calculations of the maximum eigenvalue for the
% internal eigenmodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Minimum spatial scale
md = spatthresh / sqrt(domain_area_km); 

% Maximum eigenvalue for interior modes
eig_max = calculate_max_eigenvalue_square( md );
eig_min = 0.0001;
eig_range = [ eig_min, eig_max ];

save( tfn, 'spatthresh', 'eig_min','eig_max','eig_range', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine triangulation to use for all modes.
%
% First boundary mode tends to get really detailed triangulation -  good
% choice for other modes.  But this may depend on the particulars of the
% domain in question and this should be used with great caution!
%
% Also, will use the first open boundary in ob_nums for this
% calculation, so the open boundaries most appropriate for this
% calculation should go first (probably the longest open boundary).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pde_fig,ax] = openMA_pdetool_initial_setup(border_n);

% Put keyboard here if you need to determine open boundary nums, etc.
if kb, keyboard, end

pdetool('initmesh')
%pdetool('refine') % too many triangles too fast
pdetool('jiggle')
bm = openMA_pdetool_boundary_modes_solve( pde_fig,ax,[1,0,0], ob_nums{1}, ...
                                          db_nums{1}, nt, ni );
[p,e,t] = deal( bm(1).p, bm(1).e, bm(1).t );

% Put keyboard here if you want to see grid.
if kb, keyboard, end

clear bm
delete(pde_fig)

% Points in LonLat
pLonLat = m_normcoords2ll( origin, p', domain_area_proj )';

save( tfn, 'p','e','t','pLonLat', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do boundary modes
%
% This section is somewhat complicated because I wanted to allow the
% possibility that there are more than one open boundary.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bound_modes = []; max_bound_modes = 0; n_bound_modes = [0,0,0];
for k = 1:length(ob_nums)
  % Get out indices of open boundary we want to use initially.
  obn = ob_nums{k};
  sdbn = db_nums{k};
  
  % Open up pdetool and set mesh
  [pde_fig,ax] = openMA_pdetool_initial_setup(border_n);
  pdetool_getset_mesh(pde_fig,p,e,t); % Set mesh as eigenmode adaptive
				      % method not effective.
				      
  % Cummulative distance along open boundary.
  ob_cd = pde_border_cummulative_distance( pde_fig, obn );
  ob_dd = ob_cd(end);

  % Calculate max cos and sin wave number.
  max_bound_modes(k,1) = calculate_max_num_boundary_modes( ob_dd, md );
  n_bound_modes(k,:) = [ 1, max_bound_modes(k), max_bound_modes(k) ];

  % Calculate boundary modes
  bb = openMA_pdetool_boundary_modes_solve( ...
      pde_fig,ax,n_bound_modes(k,:), obn, sdbn, nt, 0 );
  delete(pde_fig)
  
  % Add them to collection
  if exist( 'bound_modes', 'var' )
    bound_modes = [ bound_modes, bb ];
  else
    bound_modes = bb;
  end
  
end

save( tfn, 'bound_modes', 'max_bound_modes', 'n_bound_modes', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do neumann modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pde_fig,ax] = openMA_pdetool_initial_setup(border_n);
pdetool_getset_mesh(pde_fig,p,e,t); % Set mesh as eigenmode adaptive
                                    % method not effective.
neumann_modes = openMA_pdetool_eigenmodes_solve_to_eigmax( ...
    pde_fig, ax, 'neu', eig_range, nt, 0 );
delete(pde_fig)

save( tfn, 'neumann_modes', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do dirichlet modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pde_fig,ax] = openMA_pdetool_initial_setup(border_n);
pdetool_getset_mesh(pde_fig,p,e,t);
dirichlet_modes = openMA_pdetool_eigenmodes_solve_to_eigmax( ...
    pde_fig, ax, 'dir', eig_range, nt, 0 );
delete(pde_fig)

save( tfn, 'dirichlet_modes', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate matrix for homogeneous term for future reference.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
homogeneous_matrix = openMA_calculate_homogenization_matrix( ...
    neumann_modes, dirichlet_modes, bound_modes );

save( tfn, 'homogeneous_matrix', '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate currents of each mode on triangular grid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ux_tri_xy,uy_tri_xy] = openMA_modes_group_same_grid(neumann_modes, ...
                                                  dirichlet_modes, bound_modes ...
                                                  );

% Here is the rub - Lon,Lat might be rotated with respect to the xy
% coordinate system.  Need to rotate ux_tri,uy_tri appropriately.  This
% is a bit experimental code - hopefully the projection will be such that
% the rotation is small.  This also assumes orthonormal rotation, which
% may be violated by some projections (which probably aren't great
% choices for this purpose anyway).
p2 = pLonLat;
p2(1,:) = p2(1,:) + 0.001; % Small longitudinal displacement
p2 = m_ll2normcoords( origin, p2', domain_area_proj )';
dp = p2 - p; % Small vectors that represent xy position of longitudinal
             % displacement 

% Angle to rotate u,v - minus sign is to rotate from xy 2 ll instead of
% ll 2 xy.
xy2ll_angles = - atan2( dp(2,:), dp(1,:) ) * 180 / pi;

% Put angles at center of triangles
xy2ll_angles = pdeintrp( p, t, xy2ll_angles' )';

% I think this is the correct sense of rotation
[ux_tri,uy_tri] = rotUV( ux_tri_xy, uy_tri_xy, ...
                         repmat(xy2ll_angles,[1,size(ux_tri_xy,2)]) ); 

save( tfn, 'xy2ll_angles', 'ux_tri_xy', 'uy_tri_xy', 'ux_tri', 'uy_tri', ...
      '-APPEND' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Try to save m_map projection info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A bit fragile because these variable names are defined by m_map, not
% us.
global MAP_PROJECTION MAP_VAR_LIST MAP_COORDS
m_map_proj_info.MAP_PROJECTION = MAP_PROJECTION;
m_map_proj_info.MAP_VAR_LIST = MAP_VAR_LIST;
m_map_proj_info.MAP_COORDS = MAP_COORDS;

save( tfn, 'm_map_proj_info', '-APPEND' );

% Move temporary file to real filename
movefile( tfn, fn )

% ALL DONE
