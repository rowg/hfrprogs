function T = subsasgnTUV( T, v, I, E, O )
% SUBSASGNTUV  Used to copy values from one object into a TUV structure
%
% Usage: T = subsasgnTUV( T, val, I, subsasgnErrors, subsasgnOthers )
%
% Inputs
% ------
% T = TUV structure to be operated on.
% val = values to be put in TUV structure.  This can be a matrix or
%       another TUV structure of the same format (but different size) as T.
% I = Index of values to be replaced.  Normally this is either an array
%     of the same size as T.U of boolean values indicating which values
%     to replace, or a vector of numeric indices into T.U.  Indexing of
%     the form T.U( sI, tI ) can be achieved by setting I = { sI, tI };
% subsasgnErrors = boolean indicating whether or not to attempt replacing of
%                  ErrorEstimates. Defaults to True.
% subsasgnOthers = boolean indicating whether or not to attempt replacing of
%                  variables in OtherMatrixVars.  Defaults to True.
%
% Output
% ------
% T = totals structure that have values given by indices in I replaced with
%     corresponding values in val.
%
% NOTE: To operate on all values, use I = ':'.
%
% HINT: This function should work as long as:
%
%   >> T.U(I) = val     % or similarly T.U(I{:}) = val if I is a cell
%
% works if val is a matrix, or:
%
%   >> T.U(SpatialI,TempI) = val.U
%
% works if val is a TUV structure.
%
% NOTE: This function will only replace values in full matrix variables in
% the TUV structure (such as U and V) and will not affect values in
% variables such as TimeStamp, LonLat and things in OtherTemporalVars /
% OtherSpatialVars.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: subsasgnTUV.m 481 2007-09-13 21:20:30Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'E', 'var' ), E = true; end
if ~exist( 'O', 'var' ), O = true; end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

if isstruct(v)
  T.U = myref( T.U, v.U, I );
  T.V = myref( T.V, v.V, I );
else
  T.U = myref( T.U, v, I );
  T.V = myref( T.V, v, I );
end

% Do errors
if E
  if isstruct(v)
    T.ErrorEstimates = subsasgnTUVerror(T.ErrorEstimates,v.ErrorEstimates,I);
  else
    T.ErrorEstimates = subsasgnTUVerror(T.ErrorEstimates,v,I);
  end    
end

% Do Others
if O && ~isempty( T.OtherMatrixVars )
  for f = fieldnames( T.OtherMatrixVars )'
    if isstruct( v )
      T.OtherMatrixVars.(f{:}) = myref( T.OtherMatrixVars.(f{:}), ...
                                        v.OtherMatrixVars.(f{:}), I );
    else
      T.OtherMatrixVars.(f{:}) = myref( T.OtherMatrixVars.(f{:}), v, I );
    end
  end
end



%%%%%%%%%--------SUBFUNCTIONS-----------%%%%%%%%%%%%
function V = myref( V, v, I )
if iscell(I)
  V( I{:} ) = v;
else
  V( I ) = v;
end
