function [ ln, lt, ts ] = particle_track_ode_tri_LonLat(pLL, t, ux, uy, ...
                                                  varargin )
% PARTICLE_TRACK_ODE_TRI_LONLAT  Generates particle tracks directly in a
% LonLat coordinate system
%
% Usage: [Lon,Lat,TimeStamps] = particle_track_ode_tri(pLL,t,ux,uy,tt,tspan,LL,options,odesolver )
%
% This function is essentially the same as the particle_track_ode_tri
% function in the openMA toolbox, except that it converts currents from cm/s
% to dLon/dDay and dLat/dDay and does particle tracking directly in the
% Lon,Lat coordinate system.  This has the advantage that it should work
% fairly seamlessly over large areas on a spherical earth so long as the
% individual pieces of the track are small enough that the earth can be
% assumed locally flat and the dLon and dLat make sense over those scales.
% The size of individual pieces of the track can be set sufficiently small
% for most parts of the earth (i.e., all but close to the poles) by choosing
% appropriate values of the options argument.
%
% Also, it is assumed in this function that the individual triangles in
% the triangular grid are small enough so that straight LonLat lines
% between corners of the triangle are not significantly different from
% great arcs on the surface of the earth.
%
% This function uses the m_idist function to estimate the number of cm
% per degree of longitude and latitude, so the M_MAP toolbox must be on
% the path.
%
% IMPORTANT NOTE: This function has a fundamental problem tracking things
% across the longitudinal boundary (i.e. where it passes from -180 to
% +180, for example).  Therefore, make sure that longitude is continuous
% over the longitudinal range of your data by adding an appropriate
% factor of 360 degrees where necessary.
%
% Inputs
% ------
% pLL = points of triangular grid in format produced by pdetool.  Must be
%       in Lon,Lat units.
%
% t = triangulation, in format produced by pdetool.
%
% ux,uy = currents defined at centers of each of the triangles in t
% (currents are assumed constant over each triangle).  ux and uy should
% be matrices, with each row being a triangle and each column being a
% time in tt.  The units of ux and uy MUST be CM/S!
%
% tt = times at which the currents are defined.  Must have length equal
% to the number of columns of ux and uy.  Should be in datenum units.
%
% tspan = time period over which to generate tracks.  See ode45 for more
% details on possible formats for tspan. Again, should be in datenum units.
%
% LL = a two column matrix of initial positions for the particles.
% Again, coordinates must be in Lon,Lat.
%
% options = options for the ODE solver.  See odeset, ode45 and the other
% solvers for details on format and creating. Defaults
%
% odesolver = ode solver function to use.  Defaults to ode45.
%
% Outputs
% -------
% Lon,Lat = coordinates of particles.  Each column is a different starting
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
% 	$Id: particle_track_ode_tri_LonLat.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2003 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First need to calculate number of km per Lon o Lat
% at locations of data.  Currently uses m_map toolbox
% to do that, but there are probably simple ways to
% do this without the toolbox.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get centers of triangles
ln = pdeintrp( pLL, t, pLL(1,:)' )';
lt = pdeintrp( pLL, t, pLL(2,:)' )';

% Get XXX/CM
[LonPerCM,LatPerCM] = LonLatPerCM( ln, lt );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert values in ux and uy to dLon/dDay and dLat/dDay,
% respectively.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ux = ux .* 60 .* 60 .* 24 .* repmat(LonPerCM,[1,size(ux,2)]);
uy = uy .* 60 .* 60 .* 24 .* repmat(LatPerCM,[1,size(ux,2)]);

clear ln lt LonPerCM LatPerCM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now pass on to particle_track_ode_tri
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ln,lt,ts] = particle_track_ode_tri( pLL, t, ux, uy, varargin{:} );
