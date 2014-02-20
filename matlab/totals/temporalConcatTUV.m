function T = temporalConcatTUV( T, varargin )
% TEMPORALCONCATTUV  Concatenate timesteps in various TUV structures
%
% Usage: TUV = temporalConcatTUV( TUV1, TUV2, ..., TUVN, catErrors, catOthers )
%
% Inputs
% ------
% TUVn = totals structures to be concatenated.
% catErrors = boolean indicating whether or not to attempt splicing of
%             ErrorEstimates. Defaults to True.
% catOthers = boolean indicating whether or not to attempt splicing of
%             variables in OtherMatrixVars and OtherSpatialVars.  Defaults
%             to True.
%
% Output
% ------
% TUV = totals structure that is concatenation of input TUV structures.
%
%
% NOTE: This function assumes that all input TUV structures have the same
% Lon and Lat grid points.  A warning will be generated if this is not the
% case and the Lon,Lat of the first TUV structure will be used if
% possible.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: temporalConcatTUV.m 636 2008-03-31 06:56:14Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

E = true;
O = true;
if length(varargin) > 1
  if ~isstruct(varargin{end-1})
    E = varargin{end-1};
    O = varargin{end};
    varargin = varargin(1:end-2);
  elseif ~isstruct(varargin{end})
    E = varargin{end};
    varargin = varargin(1:end-1);
  end
end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

% Remove Errors and Others if not of interest
if ~E
  T.ErrorEstimates = []; % Zero out if not subsrefing.
end
if ~O
  T.OtherMatrixVars = [];
  T.OtherTemporalVars = [];
end

for k = 1:length(varargin)
  v = varargin{k};

  try % Have to do try catch just in case they have different sizes
    I = all( T.LonLat(:) == v.LonLat(:) );
  catch
    I = false;
  end
  if ~I
    warning( 'Not all TUV structures have identical grids. Ignoring.' );
  end
  
  T.U = [ T.U, v.U ];
  T.V = [ T.V, v.V ];

  T.TimeStamp = [ T.TimeStamp, v.TimeStamp ];

  % Do errors
  if E & ~isempty( T.ErrorEstimates )
    for k = 1:length(T.ErrorEstimates)
      for f = { 'Uerr', 'Verr', 'UVCovariance', 'TotalErrors' }
        T.ErrorEstimates(k).(f{:}) = [ T.ErrorEstimates(k).(f{:}), ...
                            v.ErrorEstimates(k).(f{:}) ]; 
      end
    end
  end

  % Do Others
  if O
    if ~isempty( T.OtherMatrixVars )
      for f = fieldnames( T.OtherMatrixVars )'
        T.OtherMatrixVars.(f{:}) = [ T.OtherMatrixVars.(f{:}), ... 
                            v.OtherMatrixVars.(f{:}) ];
      end
    end
    
    if ~isempty( T.OtherTemporalVars )
      for f = fieldnames( T.OtherTemporalVars )'
        T.OtherTemporalVars.(f{:}) = [ T.OtherTemporalVars.(f{:}), ... 
                            v.OtherTemporalVars.(f{:}) ];
      end
    end
    
  end
end