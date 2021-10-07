function [u,p,e,t]=pdetool_adapt_mesh_solve(pde_fig,nt,ni)
% ADAPT_MESH_SOLVE
%
% Usage: [u,p,e,t]=pdetool_adapt_mesh_solve(pde_fig,nt,ni)
%
% This is a simple wrapper function that makes doing adaptive mesh pde
% solving easier.  It assumes that you have already defined the domain,
% boundary conditions and PDE that you want to solve and that the mesh
% has been initialized.
%
% Inputs:
%
% pde_fig = handle of pdetool figure window
%
% nt = maximum number of triangles to use for adaptive mesh.  Defaults to
% 15000.
%
% ni = maximum number of iterations for the adaptive mesh algorithm.
% Defaults to 5.
%
% Outputs:
%
% u = solution to PDE
% p,e,t = points, edges and triangles of triangular mesh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: pdetool_adapt_mesh_solve.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('nt','var') || isempty(nt)
  nt = 15000;
end

if ~exist('ni','var') || isempty(ni)
  ni = 5;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set to do adaptive mesh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
my_setappdata(pde_fig,'solveparam',...
str2mat('1',num2str(nt),num2str(ni),'pdeadworst',...
'0.5','longest','0','1e-4','','fixed','inf'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate solution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pdetool('solve') % Actually use adaptive mesh

u=get(findobj(get(pde_fig,'Children'),'flat','Tag','PDEPlotMenu'),...
      'UserData');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get mesh information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[p,e,t] = pdetool_getset_mesh( pde_fig );
