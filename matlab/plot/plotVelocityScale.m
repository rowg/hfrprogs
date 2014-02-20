function [vh, th, orig] = plotVelocityScale( vel, scale, units, orig, ...
					    orientation, plotFunc, varargin )
% PLOTVELOCITYSCALE  draw an scale arrow on a plot.
% Usage: [arrow_handle, text_handle, location] = plotVelocityScale( ...
%                  velocity, scale, TEXT, location, orientation,
%                  plotFunc, varargin )
%
% vel is the velocity to plot.
%
% scale is how much to scale it (scale used for m_quiver).
%
% TEXT is a string to be placed next to arrow (defaults to 
% [ num2str(vel) ' cm/s' ])
%
% If location is not given or is empty, ginput will be used to get one.
% location is a lon,lat pair with the location of the end of the arrow.
%
% orientation is either 'horiz', 'vert', 'revhoriz' or 'revvert'
% (defaults to 'horiz').
%
% plotFunc is the plot function to use for making arrow.  See plotData for
% details.  Defaults to 'm_vec'.
% 
% varargin are extra arguments to be passed to the plotData function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: plotVelocityScale.m 484 2007-09-22 17:44:42Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('units','var')
  units = 'cm/s';
  units = [ num2str(vel) ' ' units ];
end

if ~exist('orig','var') || isempty(orig)
  orig = ginput(1);
  [orig(1),orig(2)] = m_xy2ll( orig(1), orig(2) );  
end

if ~exist('orientation','var') || isempty( orientation )
  orientation = 'horiz';
end

if ~exist('plotFunc') || isempty(plotFunc)
  plotFunc = 'm_vec';
end

switch orientation
 case 'horiz'
  units = [ units ' ' ];
  targs = { 'verticalalignment','middle','horizontalalignment','right' };
  vel = [ vel, 0 ];
 case 'vert'
  targs = { 'verticalalignment','top','horizontalalignment','center' };
  vel = [ 0, vel ];  
 case 'revhoriz'
  units = [ ' ' units ];
  targs = { 'verticalalignment','middle','horizontalalignment','left' };
  vel = [ -vel, 0 ];
 case 'revvert'
  targs = { 'verticalalignment','bottom','horizontalalignment','center' };
  vel = [ 0, -vel ];  
 otherwise
  error( 'Bad orientation.' );
end

switch plotFunc
  case {'m_vec','m_quiver','m_arrow'}
    tFunc = 'm_text';
  case {'quiver','arrow'}
    tFunc = 'text';
  otherwise
    error([ 'Unknown plot function: ' plotFunc ]);
end

% Create fake plot data
a.TimeStamp = 0;
a.LonLat = orig(:)';
[a.U,a.V] = deal(vel(1),vel(2));

ih = ishold;

hold on

vh = plotData( a, plotFunc, 1, scale, varargin{:} );

th = feval( tFunc, orig(1), orig(2), units );
set(th,targs{:})

if ~ih
  hold off
end
