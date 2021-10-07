function [ x, y, ts ] = openMA_particle_track_1st( nm, dm, bm, alpha, t, cc, ts )
% OPENMA_PARTICLE_TRACK_1ST - generates particle tracks from an openMA
% set of modes and mode coefficients using a 1st order algorithm
%
% Usage: [ x, y ] = openMA_particle_track_1st( vfm,dfm,bm,alpha,t,cc,ts )
%
% vfm, dfm, bm are the familiar openMA modes.  alpha are the mode
% coefficients generated from the data using openMA_modes_fit_NaNs or
% similar.  t are the times corresponding to the columns of alpha.  cc
% are the coordinates of the starting points of the particles (i.e. a two
% column matrix).
%
% ts are the times of the time steps for the particle tracks.  This argument
% allows you to specify a smaller timestep for the tracks.  If this argument
% is left off, ts = t.  If it is given, the columns of alpha will be
% linearly interpolated to the times given in ts and then particle tracks
% will be created for those times.
%
% x and y are matrices with the tracks.  Each row is a starting point and
% each column is a timestep.
%
% NOTE that the algorithm used in this function is very simple and has a
% number of important biases.  A higher order algorithm would be
% preferrable for tracking over extended time periods.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_particle_track_1st.m 79 2007-03-05 21:51:20Z dmk $	
%
% Copyright (C) 2003 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('ts','var')
  ts = t;
else
  t = t(:);
  ts = ts(:);
  
  alpha = interp1( t, alpha', ts );
end

dt = diff(ts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate up front the gradients for each mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uv = [];
nn = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over neumann modes and do pdegrad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(nm)
  nn = nn + 1;
  [uv(nn).p, uv(nn).t] = deal( nm(k).p, nm(k).t );
  [uux,uuy] = pdegrad( nm(k).p, nm(k).t, nm(k).u );
  [uv(nn).u,uv(nn).v] = deal( uux(:), uuy(:) );
end
clear nm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over dirichlet modes and do pdegrad
%
% Sign in definition of vorticity modes agrees with k x grad(psi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(dm)
  nn = nn + 1;
  [uv(nn).p, uv(nn).t] = deal( dm(k).p, dm(k).t );
  [uux,uuy] = pdegrad( dm(k).p, dm(k).t, dm(k).u );
  
  % Fix for cross product
  [uv(nn).u,uv(nn).v] = deal( -uuy(:), uux(:) );
end
clear dm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over boundary modes and do pdegrad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(bm)
  nn = nn + 1;
  [uv(nn).p, uv(nn).t] = deal( bm(k).p, bm(k).t );
  [uux,uuy] = pdegrad( bm(k).p, bm(k).t, bm(k).u );
  [uv(nn).u,uv(nn).v] = deal( uux(:), uuy(:) );
end
clear bm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now generate tracks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[x,y] = deal( repmat( NaN, [size(cc,1), length(ts)] ) );
xx = cc(:,1);
yy = cc(:,2);
x(:,1) = xx;
y(:,1) = yy;

for k = 1:length(dt)
  aa = alpha(k,:);
  
  [dx,dy] = deal( zeros([length(xx),1]) );
  
  ddt = dt(k);
  
  % Find contribution of each mode to movement
  for l = 1:length(uv)
    % tsearch takes up > 95% of the time in this function.  Placing all
    % modes on the same triangular grid would greatly speed up particle
    % tracking if this can be taken advantage of in another function.
    ss = tsearch_arbitrary( uv(l).p, uv(l).t, xx, yy );
    
    ii = isfinite(ss);
    dx(ii) = dx(ii) + aa(l) * uv(l).u(ss(ii));
    dy(ii) = dy(ii) + aa(l) * uv(l).v(ss(ii));
    
    dx(~ii) = NaN;
    dy(~ii) = NaN;
  end
  
  xx = xx + ddt * dx;
  yy = yy + ddt * dy;
  
  if all(isnan(xx))
    break
  end
  
  x(:,k+1) = xx;
  y(:,k+1) = yy;
end
