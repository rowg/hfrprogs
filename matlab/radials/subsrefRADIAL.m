function T = subsrefRADIAL( T, sI, tI, O )
% SUBSREFRADIAL  Used to splice a RADIAL structure, pulling out certain
% pieces.
%
% Usage: RADIAL = subsrefRADIAL( RADIAL, SpatialI, TempI, subsrefOthers )
%
% Inputs
% ------
% RADIAL = radial structure to be spliced.
% SpatialI = Index of spatial grid points to be kept
% TempI = Index of time steps to be kept.  Defaults to ':'
% subsrefOthers = boolean indicating whether or not to attempt splicing of
%                 variables in OtherMatrixVars.  Defaults to True.
%
% Output
% ------
% RADIAL = radial structure that only has the grid points and time steps in
% SpatialI and TempI, respectively.
%
%
% NOTE: To keep all grid points or time steps, use I = ':' (i.e. the
% index equal to that string). 
%
% NOTE: The RADIAL structure must be a single RADIAL structure, not an
% array of RADIAL strucutres (i.e., multiple sites).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: subsrefRADIAL.m 471 2007-08-21 22:52:08Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'tI', 'var' ), tI = ':'; end
if ~exist( 'O', 'var' ), O = true; end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

T.TimeStamp = T.TimeStamp( :, tI );

T.LonLat = T.LonLat( sI, : );
T.RangeBearHead = T.RangeBearHead( sI, : );

% Main data matrices
for f = RADIALmatvars
  f = f{:};
  T.(f) = T.(f)(sI,tI);
end

% Do Others
if O & ~isempty( T.OtherMatrixVars )
  for f = fieldnames( T.OtherMatrixVars )'
    T.OtherMatrixVars.(f{:}) = T.OtherMatrixVars.(f{:})(sI,tI);
  end
end

% Try filenames
if iscellstr( T.FileName )
  try, T.FileName = T.FileName(:,tI); end
end
