function varargout = pdetool_getset_mesh(pf,p,e,t)
% PDETOOL_GETSETMESH - gets or sets the current triangular mesh geometry
% of the pde domain.
%
% Usage: [p,e,t] = pdetool_getset_mesh(pf)
% Usage: pdetool_getset_mesh(pf,p,e,t)
%
% where pf is the handle of the pdetool figure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: pdetool_getset_mesh.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h=findobj(get(pf,'Children'),'flat','Tag','PDEMeshMenu');

if nargin == 1
  p=get(findobj(get(h,'Children'),'flat','Tag','PDEInitMesh'),...
	'UserData');
  e=get(findobj(get(h,'Children'),'flat','Tag','PDERefine'),...
	'UserData');
  t=get(findobj(get(h,'Children'),'flat','Tag','PDEMeshParam'),...
	'UserData');

  varargout = {p,e,t};
else
  set(findobj(get(h,'Children'),'flat','Tag','PDEInitMesh'),...
	'UserData',p);
  set(findobj(get(h,'Children'),'flat','Tag','PDERefine'),...
	'UserData',e);
  set(findobj(get(h,'Children'),'flat','Tag','PDEMeshParam'),...
	'UserData',t);

  pdetool( 'meshmode' )
  
end

