function TE = subsrefTUVerror( TE, sI, tI )
% SUBSREFTUVERROR  Used to splice total error structures, 
% pulling out certain pieces.
%
% Usage: TUVerror = subsrefTUVerror( TUVerror, SpatialI, TempI )
%
% Inputs
% ------
% TUVerror = total error structure to be spliced (created by TUVerrorstruct).
% SpatialI = Index of spatial grid points to be kept
% TempI = Index of time steps to be kept.  Defaults to ':'
%
% Output
% ------

% TUVerror = total error structure that only has the grid points and time
% steps in SpatialI and TempI, respectively.
%
%
% NOTE: To keep all grid points or time steps, use I = ':' (i.e. the
% index equal to that string).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: subsrefTUVerror.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'tI', 'var' ), tI = ':'; end

% Do errors
if ~isempty( TE )
  for k = 1:length(TE)
    % Normal variables
    for f = { 'Uerr', 'Verr', 'UVCovariance', 'TotalErrors' }
      if ~isempty( TE(k).(f{:}) )
        TE(k).(f{:}) = TE(k).(f{:})(sI,tI); 
      end
    end
    
    % Extra variables
    if ~isempty( TE(k).OtherMatrixVars )
      for f = fieldnames( TE(k).OtherMatrixVars )'
        if ~isempty( TE(k).OtherMatrixVars.(f{:}) )
          TE(k).OtherMatrixVars.(f{:}) = ...
              TE(k).OtherMatrixVars.(f{:})(sI,tI);
        end
      end
    end
    
  end
end
