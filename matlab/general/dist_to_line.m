function d = dist_to_line( l, p )
% DIST_TO_LINE  Calculates distance a group of points is to a line.
%
% Usage: dist = dist_to_line( line, points )
%
% where line is a 2x2 matrix - each row is an [x,y] point.  points should
% be a Mx2 matrix.
%
% The distance returned can be negative, indicating that the point in
% question is below the line.  Use abs if you are just interested in
% distance.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: dist_to_line.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


s=size(p,1);
o = l(1,:);
l = l(2,:);

o = repmat([o'; 0],[1,s]);
l = repmat([l'; 0],[1,s]);
p = [p'; zeros(1,s)];

%keyboard
d = cross(l-o,p-o);
d = d(3,:)';

