function [bh, th, orig] = m_distance_bar( dist, orig, orientation, edge_frac )
%M_DISTANCE_BAR draw a distance bar (in km) on an m_map generated plot.
% Usage: [bar_handle, text_handle, location] = m_distance_bar( distance, ...
%                              location, orientation, edge_frac )
%
% dist is the distance in km.
%
% if location is not given, ginput will be used to get one.  location is a
% lon,lat pair with the location of the center of the bar.
%
% orientation is either 'horiz', 'vert', or 'revvert' (defaults to 'horiz')
%
% edge_frac is the length of the bars at the edge of the distance bar as
% a fraction of the total distance.
%
% Distance bar will look correct so long as the distance is not so big
% that the curvature of the earth is important.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_distance_bar.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 2 || isempty(orig)
  orig = ginput(1);
  [orig(1),orig(2)] = m_xy2ll( orig(1), orig(2) );
end

if nargin < 3 || isempty(orientation)
  orientation = 'horiz';
end

if nargin < 4 || isempty(edge_frac)
  edge_frac = 0.1;
end

unit = 'km';

targs = {'verticalalignment','bottom','horizontalalignment','center'};
switch orientation
 case 'horiz'
  dd = [0.01,0];
 case 'vert'
  targs = [ targs, {'rotation',90} ];
  dd = [0,0.01];
 case 'revvert'
  targs = [ targs, {'rotation',270} ];
  dd = [0,0.01];
 otherwise
  error( 'Bad orientation' );
end

ee = dd([2,1]);

% Find out how much a certain distance is in one direction.
d = m_lldist( orig([1,1])+[0,dd(1)], orig([2,2])+[0,dd(2)] );
e = m_lldist( orig([1,1])+[0,ee(1)], orig([2,2])+[0,ee(2)] );

cb = [ orig - dist/2/d * dd; orig + dist/2/d * dd ];
eb1 = [ cb(1,:) - edge_frac * dist/2/e * ee; ...
	cb(1,:) + edge_frac * dist/2/e * ee ];
eb2 = [ cb(2,:) - edge_frac * dist/2/e * ee; ...
	cb(2,:) + edge_frac * dist/2/e * ee ];

ih = ishold;

hold on

% Plot up center bar.
bh(1) = m_line( cb(:,1), cb(:,2), 'color', 'k' );

% Plot up edge bars.
bh(2) = m_line( eb1(:,1), eb1(:,2), 'color', 'k' );
bh(3) = m_line( eb2(:,1), eb2(:,2), 'color', 'k' );

% Add text.
th = m_text( orig(1), orig(2), [ num2str(dist) ' ' unit ] );
set(th,targs{:})

if ~ih
  hold off
end
