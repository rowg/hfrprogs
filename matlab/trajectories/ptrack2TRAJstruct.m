function T = ptrack2TRAJstruct( pfunc, varargin );
% PTRACK2TRAJSTRUCT  Puts output of a particle_track_ode-like function
% into a TRAJ structure.
%
% Usage: TRAJ = ptrack2TRAJstruct( ptrack_function_name, ... )
%
% Inputs
% ------
% ptrack_function_name = name of function to do tracking.  For example,
%                        'particle_track_ode_tri_LonLat'.  It is assumed
%                        that the function returns 3 arguments: Lon, Lat,
%                        TimeStamps (does not really have to be Lon and
%                        Lat for this function to work).
% ... = the rest of the arguments for that tracking function
%
% Outputs
% -------
% TRAJ = a trajectory structure with the resultant data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: ptrack2TRAJstruct.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We got the funk
[ln,lt,ts] = feval( pfunc, varargin{:} );
[ln,lt] = deal(ln',lt');

% Awww
T = TRAJstruct( size(ln) );

T.Lon = ln;
T.Lat = lt;

T.TimeStamp = ts(:)';

% initial positions
T.InitialLonLat = [T.Lon(:,1), T.Lat(:,1)];

% Calculate final positions
I = repmat( 1:size(T.Lon,2), [size(T.Lon,1),1] );
I( ~isfinite(T.Lon) ) = 0;
I = max( I, [], 2 );

II = sub2ind( size(T.Lon), (1:size(T.Lon,1))', I );

T.FinalLonLat(:,1) = T.Lon(II);
T.FinalLonLat(:,2) = T.Lat(II);

% Duration of tracks
T.TrajectoryDuration = T.TimeStamp(I)' - T.TimeStamp(1);

% Some metadata
T.ProcessingSteps{end+1} = mfilename;
T.OtherMetadata.(mfilename).ptrack_function_name = pfunc;

