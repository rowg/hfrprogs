function [pde_fig,ax] = openMA_pdetool_initial_setup(pde_border)
% openMA_pdetool_initial_setup
%
% Usage: [pde_fig,ax] = openMA_pdetool_initial_setup(pde_border)
%
% Opens the pdetool and sets domain based on pde_border, initializes mesh
% and setssome basic defaults for certain parameters.
%
% pde_border should be a two column matrix with the x and y coordinates
% of the border of the pde domain.  The x and y coordinates should be
% in appropriate square coordinates, i.e. meters, km, etc.  Lat,long will
% not work.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_pdetool_initial_setup.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Axis limits
clear al
al = [ min(pde_border); max(pde_border) ];
dd = diff(al);
al = al + [ -0.1 * dd; +0.1 * dd ];
al = al(:)';

% Basic pdetool setup and look
[pde_fig,ax]=pdeinit;
pdetool('appl_cb',1);
set(ax,'DataAspectRatio',[1 1 1]);
set(ax,'XLim',al(1:2));
set(ax,'YLim',al(3:4));
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');
pdetool('gridon','on');

% Geometry description:
pdepoly(pde_border(:,1)', pde_border(:,2)', 'P1');
set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1')

% Number of border segments.
ne = size(pde_border,1);

% I think this sets it to boundary mode.
pdetool('changemode',0)

% Initial boundary setup - set to Neumann with zeros for default
for k = 1:ne
  pdesetbd(k,'neu',1,'0','0')
end

my_setappdata(pde_fig,'Hgrad',1.3);
my_setappdata(pde_fig,'refinemethod','regular');
pdetool('initmesh')
%pdetool('refine')

% PDE coefficients:
pdeseteq(4,'1.0','0.0','0.0','1.0','0:10','0.0','0.0','[0.00001 100]')
my_setappdata(pde_fig,'currparam',['1.0 ';'0.0 ';'0.0 ';'1.0 '])

% Solve parameters:
my_setappdata(pde_fig,'solveparam',...
		 str2mat('0','1008','10','pdeadworst',...
			 '0.5','longest','0','1E-4','','fixed','Inf'))

