%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This is a basic demo of the openMA toolbox.  It calculates modes and
% fits them to imaginary data for a square domain with one open
% boundary. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_demo.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Width and height of rectangle - make them different to avoid eigenmode
% degeneracy.
rw = 1.3;
rh = 1;

pde_border = [ 0  0; 
	       rw 0;
	       rw rh;
	       0  rh;
	       0  0.001 ];

% Initial setup of pdetool
[pde_fig,ax] = openMA_pdetool_initial_setup( pde_border );

% Refine and then jiggle mesh
pdetool( 'refine' )
pdetool( 'jiggle' )

% Get this mesh for repeated use.
[p,e,t] = pdetool_getset_mesh( pde_fig );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate neumann modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reset mesh 
pdetool_getset_mesh( pde_fig, p, e, t );

% Get modes
[nm,eig_max] = openMA_pdetool_eigenmodes_solve( pde_fig, ax, 'neu', [], ...
						[], 10 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate dirichlet modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reset mesh 
pdetool_getset_mesh( pde_fig, p, e, t );

% Get modes
dm = openMA_pdetool_eigenmodes_solve( pde_fig, ax, 'dir', [], [], 10 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate boundary modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reset mesh 
pdetool_getset_mesh( pde_fig, p, e, t );

n_modes = [1,5,5];
ob_nums = 5; % Have to find this out by looking at pdetool
db_num = 4; % Made a small boundary segment to keep boundary modes from
            % having very large constant.

% Get modes
bm = openMA_pdetool_boundary_modes_solve( pde_fig, ax, n_modes, ob_nums, ...
					   db_num, [], 10 );

% Get rid of pdetool
%close(pde_fig)

% Calculate a suitable homogenization term for future reference.
K = 0.01 * openMA_calculate_homogenization_matrix( nm, dm, bm );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate false currents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xx = linspace( 0, max(rw,rh), 31 );
x = xx( xx < rw & xx > 0 );
y = xx( xx < rh & xx > 0 );

[X,Y] = meshgrid( x, y );

U = zeros( size(X) );
V = U;

U = rh/2 - Y;

I1 = Y <= rh/2 & X > rw * ( 1 - Y / rh );
I2 = Y > rh/2 & X > rw * ( Y / rh );
I3 = I1 | I2;

U(I3) = 0;
V(I3) = rh * ( X(I3) / rw - 1/2 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Interpolate modes and fit to currents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[alpha,ux,uy] = openMA_modes_fit_NaNs( nm, dm, bm, K, ...
				       [ X(:), Y(:) ], ...
				       zeros(size(U(:))), U(:), [], ...
				       repmat(pi/2,size(U(:))), ...
				       V(:), [] );

% Get currents from modes.
UU = ux * alpha;
VV = uy * alpha;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make a nice plot of it all.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rh1 = rectangle( 'position',[0,-0.5*rh,rw*1.5,2*rh],'facecolor','k','edgecolor','k' );
hold on
rh2 = rectangle( 'position',[0,0,rw,rh],'facecolor','w','edgecolor','g', ...
		 'linestyle', '--', 'linewidth', 2 );

qh1 = quiver(X,Y,0.2*U,0.2*V,0,'k');
qh2 = quiver(X(:),Y(:),0.2*UU,0.2*VV,0,'r');
set(qh2,'color',[0.7 0.7 0.7])

axis equal
axis([-0.1*rw,rw*1.1,-0.1*rh,rh*1.1])

hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do some basic particle tracking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x1 = X(1:5:end,1:5:end);
y1 = Y(1:5:end,1:5:end);
cc = [ x1(:), y1(:) ];

[xx,yy] = openMA_particle_track_1st( nm, dm, bm, [ alpha, alpha ], [0,10], ...
				      cc, linspace(0,10,50) );

% Plot tracks on figure
hold on
ph = plot( xx', yy' );
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save for future reference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save demo.mat nm dm bm alpha X Y U V ux uy UU VV xx yy cc

