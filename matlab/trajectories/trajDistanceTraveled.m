function l = trajDistanceTraveled( t )
% TRAJDISTANCETRAVELED Calculates the spatial length of trajectories
%
% Usage: Length = trajDistanceTraveled( TRAJ )
%
% Inputs:
% ------
% TRAJ = A structure with fields Lon and Lat that contains tracks, with each
%        row being a track and each column being a timestep (typically a
%        TRAJ structure).
%
% Outputs:
% -------
% Length = vectors with total lengths of trajectories in meters!
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: trajDistanceTraveled.m 437 2007-06-08 13:49:47Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = m_idist( t.Lon(:,1:end-1), t.Lat(:,1:end-1), t.Lon(:,2:end), t.Lat(:,2:end) ...
             );
d( isnan(d) ) = 0;
l = sum( d, 2 );
