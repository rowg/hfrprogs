function T = subsrefTUV( T, sI, tI, E, O )
% SUBSREFTUV  Used to splice totals structures, pulling out certain pieces.
%
% Usage: TUV = subsrefTUV( TUV, SpatialI, TempI, subsrefErrors, subsrefOthers )
%
% Inputs
% ------
% TUV = totals structure to be spliced.
% SpatialI = Index of spatial grid points to be kept
% TempI = Index of time steps to be kept.  Defaults to ':'
% subsrefErrors = boolean indicating whether or not to attempt splicing of
%                 ErrorEstimates. Defaults to True.
% subsrefOthers = boolean indicating whether or not to attempt splicing of
%                 variables in OtherMatrixVars, OtherSpatialVars and
%                 OtherTemporalVars.  Defaults to True.
%
% Output
% ------
% TUV = totals structure that only has the grid points and time steps in
% SpatialI and TempI, respectively.
%
%
% NOTE: To keep all grid points or time steps, use I = ':' (i.e. the
% index equal to that string).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: subsrefTUV.m 471 2007-08-21 22:52:08Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'tI', 'var' ), tI = ':'; end
if ~exist( 'E', 'var' ), E = true; end
if ~exist( 'O', 'var' ), O = true; end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

T.U = T.U( sI, tI );
T.V = T.V( sI, tI );

T.TimeStamp = T.TimeStamp( :, tI );

T.LonLat = T.LonLat( sI, : );
T.Depth = T.Depth( sI, : );

% Do errors
if E
  T.ErrorEstimates = subsrefTUVerror( T.ErrorEstimates, sI, tI );
else
  T.ErrorEstimates = []; % Zero out if not subsrefing.
end

% Do Others
if O
  if ~isempty( T.OtherMatrixVars )
    for f = fieldnames( T.OtherMatrixVars )'
      T.OtherMatrixVars.(f{:}) = T.OtherMatrixVars.(f{:})(sI,tI);
    end
  end
  
  if ~isempty( T.OtherSpatialVars )
    for f = fieldnames( T.OtherSpatialVars )'
      T.OtherSpatialVars.(f{:}) = T.OtherSpatialVars.(f{:})(sI,:);
    end
  end
  
  if ~isempty( T.OtherTemporalVars )
    for f = fieldnames( T.OtherTemporalVars )'
      T.OtherTemporalVars.(f{:}) = T.OtherTemporalVars.(f{:})(:,tI);
    end
  end  
else
  % Zero out if not subsreferencing.
  T.OtherMatrixVars = [];
  T.OtherSpatialVars = [];
  T.OtherTemporalVars = [];
end

