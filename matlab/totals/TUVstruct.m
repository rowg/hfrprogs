function T = TUVstruct( DIM, varargin )
% TUVSTRUCT  Creates an empty default TUV structure that can be
% filled with any type of total currents data
%
% Usage: TUV = TUVstruct( DIM, N )
%
% This function should be used *every* time one wants to generate any
% type of total currents (normal, OMA, etc.) as this will guarantee that
% they have the same structure.
%
% Inputs
% ------
%
% DIM: Size of U, V, etc. matrices to initialize.  A two element vector
% with [ NGridPts, NTimeStamps ].  Defaults to [ 0 0 ].
%
% N: The number of TUVerror structures to create in ErrorEstimates.  See
% TUVerrorstruct for details.
%
% Outputs
% -------
%
% TUV: is the empty structure to use for recording totals data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: TUVstruct.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'DIM' , 'var' )
  DIM = [0 0];
end

% Basics
T.Type = 'TUV';
T.DomainName = '';
T.CreationInfo = '';

% Time
T.TimeStamp = repmat(NaN,[1,DIM(2)]);
T.TimeZone = 'GMT';

T.CreateTimeStamp = now;
T.CreateTimeZone = 'GMT';

% Space
T.LonLat = repmat( NaN, [DIM(1),2] );
T.Depth = repmat( NaN, [DIM(1),1] );

% UV
[T.U,T.V] = deal( repmat( NaN, DIM ) );

% Some units
T.LonLatUnits = { 'Decimal Degrees', 'Decimal Degrees' };
[T.UUnits,T.VUnits] = deal( 'cm/s' );
T.DepthUnits = 'm';

% Errors
T.ErrorEstimates = TUVerrorstruct( DIM, varargin{:} );

% Other
T.OtherMatrixVars = []; % Should eventually be a structure.
T.OtherSpatialVars = []; % Should eventually be a structure.
T.OtherTemporalVars = []; % Should eventually be a structure.
T.OtherMetadata = []; % Should eventually be a structure.

T.ProcessingSteps = {};
T.TUV_struct_version = 'SVN $Rev: 396 $ $Date: 2007-04-02 16:56:29 +0000 (Mon, 02 Apr 2007) $';
