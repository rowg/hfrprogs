function [ob_cd,ob_sp,ob_ep,dl1] = pde_border_cummulative_distance( dl1, ob_nums ...
						  )
% BORDER_CUMMULATIVE_DISTANCE - calculates distance along (a possibly open
% section of) a border
%
% Usage: [cum_dist,start_pt,end_pt] = pde_border_cummulative_distance( ...
%                  dl1, ob_nums )
%
% or
%
% Usage: [cum_dist,start_pt,end_pt,dl1] = pde_border_cummulative_distance( ...
%                  pde_fig, ob_nums )
%
%
% Inputs:
%
% pde_fig = handle of pdetool figure from openMA_pdetool_initial_setup
% 
% dl1 = decomposed geometry you get from the pdetool (via dl1 =
% my_getappdata(pde_fig,'dl1') ) and ob_nums are the numbers of the boundary
% segments that are open.  See DECSG for more information.
%
% ob_nums = a vector of IDs of the elements of the boundary that have open
% boundary conditions.  These must correspond to the IDs that pdetool
% assigns to the different boundary elements.  Furthermore, the must be
% ordered so that they form a connected set of segments that is oriented the
% same way that the boundary itself is ordered.  If this is not the case,
% the algorithm will not function properly and should generate an error.
%
%
% Outputs:
%
% cum_dist = cummulative distance along the border
%
% start_pt = starting point of each segment
%
% start_pt = ending point of each segment
%
% dl1 = geometry from pdetool
%
% This function is generally not used by the user, but could be useful if
% you need distance along the border as part of the process of
% determining the normal component of flow along the border.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: pde_border_cummulative_distance.m 84 2007-11-18 10:34:54Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if prod(size(dl1)) == 1
  pde_fig = dl1;
  dl1=my_getappdata(pde_fig,'dl1');
end

% Number of border segments.
ne = size(dl1,2);

% Start and end points of open boundary segments
% These should be connected
ob_sp = dl1([2,4],ob_nums)';
ob_ep = dl1([3,5],ob_nums)';

% Make sure boundary segments are connected
if any(any(ob_sp(2:end,:) ~= ob_ep(1:end-1,:)))
  error( 'Open boundary segments are either not connected or out of order.' );
end

% Distance along border
ob_dd = sqrt( sum((ob_sp-ob_ep).^2,2) );

% Cummulative distance - needed for calculating boundary conditions.
ob_cd = [0; cumsum(ob_dd)];

