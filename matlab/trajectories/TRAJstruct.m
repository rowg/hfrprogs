function T = TRAJstruct( DIM )
% TRAJSTRUCT  Creates an empty default TRAJ structure for saving
% trajectories information
%
% Usage: TRAJ = TRAJstruct ( DIM )
%
% This function should be used *every* time one wants to generate any type
% of Lagrangian trajectories as this will assure they have the same
% format.
%
% Inputs
% ------
%
% DIM: Size of trajectory matrices. A two element vector
% with [ NGridPts, NTimeStamps ].  Defaults to [ 0 0 ].
%
% N: The number of TUVerror structures to create in ErrorEstimates.  See
% TUVerrorstruct for details.
%
% Outputs
% -------
%
% TRAJ: is the empty structure to use for recording trajectories data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: TRAJstruct.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'DIM' , 'var' )
  DIM = [0 0];
end

% General
T.Type = 'Lagrangian_Trajectories';
T.TrajectoryDomain = '';
T.CreationInfo = '';

% Time
T.TimeStamp = repmat(NaN,[1,DIM(2)]);
T.TimeZone = 'GMT';

T.CreateTimeStamp = now;
T.CreateTimeZone = 'GMT';

T.TrajectoryDuration = repmat(NaN,[DIM(1),1]);

% Space
T.InitialLonLat = repmat( NaN, [DIM(1),2] );
T.FinalLonLat = repmat( NaN, [DIM(1),2] );
T.Depth = repmat( NaN, [DIM(1),1] );
[T.Lon,T.Lat] = deal( repmat( NaN, DIM ) );

% Some units
T.LonLatUnits = { 'Decimal Degrees', 'Decimal Degrees' };
T.DepthUnits = 'm';

% Other
T.OtherMatrixVars = []; % Should eventually be a structure.
T.OtherSpatialVars = []; % Should eventually be a structure.
T.OtherTemporalVars = []; % Should eventually be a structure.
T.OtherMetadata = []; % Should eventually be a structure.

T.ProcessingSteps = {};
T.TRAJ_struct_version = 'SVN $Rev: 396 $ $Date: 2007-04-02 16:56:29 +0000 (Mon, 02 Apr 2007) $';
