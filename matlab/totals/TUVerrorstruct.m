function T = TUVerrorstruct( DIM, N )
% TUVERRORSTRUCT  Creates an empty default TUVerror structure that can be
% filled with any type of error estimate for totals data.
%
% Usage: TUVerror = TUVerrorstruct( DIM, N )
%
% This function should be used *every* time one wants to generate any type
% of total currents error estimate (GDOP, GDOP 2 vector, OMA, etc.) as this
% will guarantee that they have the same structure.
%
% Inputs
% ------
%
% DIM: Size of Uerr, Verr, etc. matrices to initialize.  A two element vector
% with [ NGridPts, NTimeStamps ].  Defaults to [ 0 0 ].
%
% N: The number of such error structures to create (in an array of
% structures).  Defaults to 1.
%
% Outputs
% -------
%
% TUVerror: is the empty structure to use for recording totals errors.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: TUVerrorstruct.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'DIM' , 'var' )
  DIM = [0 0];
end

% Basics
T.TUVerror_struct_version = 'SVN $Rev: 396 $ $Date: 2007-04-02 16:56:29 +0000 (Mon, 02 Apr 2007) $';
T.Type = 'none';

% UV errors
[T.Uerr,T.Verr,T.UVCovariance,T.TotalErrors] = deal( repmat( NaN, DIM ) );

% The TotalErrors will be things like sqrt(sum(Uerr + Verr))

% Some units
[T.UerrUnits,T.VerrUnits,T.UVCovarianceUnits] = deal( 'cm2/s2' );
T.TotalErrorsUnits = 'cm/s'; 
% Decided to report total errors in cm/s for compatibility with past.

% Other
T.OtherMatrixVars = []; % Should eventually be a structure.
T.OtherMetadata = []; % Should eventually be a structure.

% Duplicate if desired
if exist('N','var')
  if N == 0, T = []; return, end
  T = repmat( T, [N,1] );
end
