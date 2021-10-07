function [emodes,eig_max] = openMA_pdetool_eigenmodes_solve_to_eigmax(pde_fig,ax,bc,eig_max,nt,ni)
% openMA_pdetool_eigenmodes_solve_to_eigmax
%
% Usage: [emodes,eig_max] = openMA_pdetool_eigenmodes_solve_to_eigmax(pde_fig,ax,bc,eig_max,nt,ni)
%
% This function solves for the interior eigenmodes for a given domain,
% just as openMA_pdetool_eigenmodes_solve does.  The difference between
% the current function and openMA_pdetool_eigenmodes_solve is that this
% function will repeatedly solve for modes until the eigenmax is truly
% reached.  This avoids a limitation of pdetool that it will only return
% about 100 modes at a time.  This function does this be repeatedly
% running openMA_pdetool_eigenmodes_solve with smaller and smaller ranges
% for the eigenvalues until the maximum eigenvalue returned is as close
% to the eig_max as possible.
%
% See openMA_pdetool_eigenmodes_solve for more details on how to use this
% function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_pdetool_eigenmodes_solve_to_eigmax.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
  eig_max = [];
end

if nargin < 5 | isempty(nt)
  nt = 15000;
end

if nargin < 6 | isempty(ni)
  ni = 5;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do initial solving.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[emodes,eig_max] = openMA_pdetool_eigenmodes_solve(pde_fig,ax,bc,eig_max,nt,ni);

ems = [ emodes.lambda ];
mem = max(eig_max);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Repeat solving until we get to eig_max
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while ems(end) < mem
  d = min(diff(ems))/2 + eps;
  emax = [ ems(end) + d, mem ];
  
  % Set ni=0 because we already have grid, no need to keep modifying.
  emodes2 = openMA_pdetool_eigenmodes_solve(pde_fig,ax,bc, emax,nt,0);
  
  if isempty(emodes2)
    break
  end
  
  emodes = [ emodes, emodes2 ];
  ems = [ emodes.lambda ];
end
