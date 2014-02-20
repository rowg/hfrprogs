function [dist,bear,head,ll] = m_ginput_idist( oo, n, functName, varargin )
% M_GINPUT_IDIST Get distance, bearing and heading for mouse selected points
%
% This function is used to get the distance, bearing and heading from an
% origin point to a set of points selected interactively on a plot.  This
% function is most appropriate for m_map plots, but can also be used for
% cartesian plots.
%
% In the HF Radar context, this function is useful for determining the
% range and angle cell of radial grid points.
%
% Usage: [dist,bear,head,X] = m_ginput_idist( origin, n, functName )
%
% Inputs:
% ------
% origin = 2-element vector with coordinates of center point
% n = number of points, functions like n in ginput or m_ginput.  Defaults
%     to inf.
% functName = string name of function to use for selecting points.  Can
%             be 'ginput' or 'm_ginput'.  Defaults to 'm_ginput'.
%
% Outputs:
% -------
% dist = distances from origin to points.  Will be in meters if
%        'm_ginput' is selection function.  Otherwise, will be in plot
%        units.
% bear = angles in math convention (CCW from east) from origin to points
% head = angles in math convention (CCW from east) from points to origin
% X = points actually selected
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_ginput_idist.m 421 2007-05-17 01:04:36Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'functName', 'var' ), functName = 'm_ginput'; end
if ~exist( 'n', 'var' ), n = inf; end

ll = feval( functName, n );

switch functName
  case 'm_ginput'
    [dist,bear,head] = m_idist( oo(1), oo(2), ll(:,1), ll(:,2), varargin{:} );
    bear = true2math( bear );
    head = true2math( head );
  otherwise
    xx = ll - repmat( oo(:)', [size(ll,1),1] );
    [bear,dist] = cart2pol( xx(:,1), xx(:,2) );
    bear = degrees(bear);
    head = mod(bear + 180,360);
end
