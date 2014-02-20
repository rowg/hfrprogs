function [dh,sh] = colordot( x, y, c, clim, pfunc, varargin )
%COLORDOT plots dots using colormap
%
% Usage: [dot_handles,surf_handle] = colordot(x,y,cval,clim,plot_func,...)
%
% where cval are the values to use for coloring the dots.  clim specify the
% limits of the color axis.  If not given or empty, clim defaults to the min
% and max of cval.  plot_func is the function to use for plotting the dots.
% This defaults to 'line' if empty or absent, but could alternatively be
% 'm_line'.
%
% ... are further arguments to the plot_func function.  If further
% arguments are used, then clim and plot_func must at least be given as
% empty arguments.
%
% dot_handles is a vector of handles to the dots in the plot.  Dot coloring
% will be done with the current colormap.  surf_handle is the handle to an
% invisible surface that is used to force the colorbar to have the
% appropriate scale and colors for the dots plotted.  This is an ugly trick
% to make colorbar agree with the dots plotted by this function.  Because
% this trick is used, changing the colormap will not change the
% color of the dots, as it only changes the color of surfaces.  Changing the
% color axis (caxis), will also have no effect on the dot colors.  This
% trick also means that one cannot combine colordot with a function that
% plots surfaces according to the current colormap.  The scatter function
% is a slow, but viable, alternative to this function that does not have
% these problems.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: colordot.m 650 2008-04-29 18:32:23Z dpath2o $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get hold state and clear figure if not hold.
ih = ishold;

if ~ih
  clf
end

x = x(isfinite(c));
y = y(isfinite(c));
c = c(isfinite(c));

if ~exist('clim','var') || isempty(clim)
  clim = [ min(c), max(c) ];
end  

if ~exist('pfunc','var') || isempty(pfunc)
  pfunc = 'line';
end

clim = full(clim);
x = full(x);
y = full(y);
c = full(c);

clim = sort(clim);

caxis(clim)

% Fix c to correct range.
c(c<clim(1)) = clim(1);
c(c>clim(2)) = clim(2);
c(isnan(c)) = clim(1);

cx = linspace(clim(1),clim(2),size(colormap,1))';
c = interp1( cx, colormap, c, '*linear', 'extrap' );

dh=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SIMPLE FIX TO PROBLEM THAT NEEDS TO BE INVESTIGATED FURTHER
%Problem: c < 0, this has happened on several data sets when 
%   plotting radial data coverages. When c < 0 this is not a valid
%   RGB-color value -- i.e. all values of c must be c >= 0 and c <= 1
%   Here's the simple fix that will work, but it's more of bandaid than
%   a fix
%
% added by dpath2o 080428
c = abs(c);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:size(x,1)
  dh(end+1) = feval( pfunc, x(k,:), y(k,:), 'linestyle', 'none', 'marker', ...
                     '.', 'color', c(k,:), varargin{:} );
end

if nargout < 1
  clear dh
end

% Put a fake surface to insure color axis
[az,el] = view;

hold on

a=axis;
x = a([1 3]);
y = a([2 4])';
x = [x; x];
y = [y, y];
clim = [clim; clim];

sh = surf(x,y,clim,'visible','off');

if ~ih
  hold off
end

view([az,el])
