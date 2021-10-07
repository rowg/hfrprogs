function [ x, y, ts ] = particle_track_ode_tri(p, t, ux, uy, tt, ...
					   tspan, cc, options, odesolver )
% PARTICLE_TRACK_ODE_TRI - generates particle tracks from a set of currents
% defined on a triangular grid using a matlab ODE solver
%
% Usage: [ x, y, ts ] = particle_track_ode_tri(p,t,ux,uy,tt,tspan,cc,options,odesolver )
%
% This function is largely inspired by Bruce Lipphardt's trajectories
% code.  The principal difference is that the currents are defined here
% on a triangular grid and the method of interpolating from the grid to
% an arbitrary space time point is different (he uses interpn, I use
% pdeintrp_arbitrary on the grid before and after the time in question
% and then linearly interpolate to the time in question).
%
% INPUTS:
%
% p = points of triangular grid in format produced by pdetool.
%
% t = triangulation, in format produced by pdetool.
%
% ux,uy = currents defined at centers of each of the triangles in t
% (currents are assumed constant over each triangle).  ux and uy should
% be matrices, with each row being a triangle and each column being a
% time in tt.
%
% tt = times at which the currents are defined.  Must have length equal
% to the number of columns of ux and uy.
%
% tspan = time period over which to generate tracks.  See ode45 for more
% details on possibilities.
%
% cc = a two column matrix of initial positions for the particles.  Units
% of cc should be the same as those in p.
%
% options = options for the ODE solver.  See odeset, ode45 and the other
% solvers for details on format and creating.  Defaults to no options.
%
% odesolver = ode solver function to use.  Defaults to ode45 if absent or
% empty.
%
% OUTPUTS:
%
% x,y = coordinates of particles.  Each column is a different starting
% position (row of cc) and each row is a time in ts.
%
% ts = times of positions in x and y.  A column vector.
%
% NOTE: This function appears to be hopelessly slow in matlab R13 (6.5)
% unless you play with the default tolerances of ode45.  See ODESET
% function and, in particular, the absolute and relative tolerances for
% more information.  You might also want to play with MaxStep, the
% maximum time step to take.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: particle_track_ode_tri.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2003 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('odesolver','var') || isempty(odesolver)
  odesolver = 'ode45';
end

if ~exist('options','var')
  options = [];
end

ntraj = size(cc,1);

y0 = [ cc(:,1); cc(:,2) ];

[ts,Y] = feval( odesolver, @ptrack_ode_worker_func, tspan, y0, options, ...
		p, t, ux, uy, tt );

[x,y] = deal( Y(:,1:ntraj), Y(:,ntraj+1:end) );

%%%%%%----------------------Subfunctions--------------------%%%%%%%
function f = ptrack_ode_worker_func( T, y, p, t, ux, uy, tt )
% This function will be used to actually do tracking.
% Assumes that T is a scalar.

% Break up X and Y coordinates.
ntraj = length(y)/2;
[xx,yy] = deal( y(1:ntraj), y(ntraj+1:end) );

% Find timesteps cooresponding to T
d = tt - T;

% If outside time range, return NaNs
if all(d<0) | all(d>0)
  f = repmat(NaN,size(y));
  return
end

% Otherwise, linearly interpolate.
dlt = max( d( d<0 ) );
dgt = min( d( d>=0 ) );
if dgt == 0
  [ux,uy] = deal( ux( :, d == 0 ), uy( :, d == 0 ) ); 
else  
  ilt = d == dlt;
  igt = d == dgt;
  dd = dgt - dlt;
  clt = dgt / dd;
  cgt = -dlt / dd;
  ux = clt * ux( :, ilt ) + cgt * ux( :, igt );
  uy = clt * uy( :, ilt ) + cgt * uy( :, igt );
end

% Then fit to specific points of interest.
% For some reason, removing the NaN's here significantly improves speed.
% Possibly a performance bug in pdeintrp_arbitrary.
ii = ~isnan(xx);
[UX,UY] = deal(xx);
if any(ii)
  [UX(ii),UY(ii)] = pdeintrp_arbitrary( [ xx(ii), yy(ii) ], p, t, ux, uy );
end
% [UX,UY] = pdeintrp_arbitrary( [ xx, yy ], p, t, ux, uy );
f = [ UX; UY ];

% T-tt(1)
% if T-tt(1) > 1.9
%   keyboard
% end

