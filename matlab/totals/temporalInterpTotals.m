function Ti = temporalInterpTotals( T, ts, maxgap, E, O, varargin )
% TEMPORALINTERPTOTALS  Temporal interpolation of total vector currents
%
% This function uses interp1_gaps to do temporal interpolation of the
% grid points in a TUV structure with totals data.
%
% Usage: TUVi = temporalInterpTotals(TUVo,T,MaxGap,Errors,Others,...)
%
% Inputs
% ------
% TUVo = TUV structure with the total currents data.
% T = Times at which to do interpolation.  If empty or absent, T defaults
%     to TUVo.TimeStamp (i.e., fill in time gaps in original data).
% MaxGap = Maximum time gap in datenum units over which to perform
%          interpolation.  See interp1_gaps for more details.  Defaults
%          to inf (i.e., interpolate over all gaps) if empty or absent.
% Errors = boolean indicating whether or not to attempt temporal
%          interpolation of errors.  Defaults to false.  If false and T
%          is not empty or absent (i.e., original times are not identical
%          to new times), then no errors will be present in the new TUV
%          structure.
% Others = boolean indicating whether or not to attempt temporal
%          interpolation of variables in OtherMatrixVars and
%          OtherTemporalVars.  Defaults to false.  If false and T is not
%          empty or absent (i.e., original times are not identical to new
%          times), then OtherMatrixVars and OtherTemporalVars will be
%          empty in the new TUV structure.
% ... = Extra arguments for interp1_gaps.
%
% Outputs
% -------
% TUVi = TUV structure with interpolated data.  If the input timestamps T
%        was absent or empty, then TUVi.OtherMatrixVars will contain an
%        extra variable temporalInterpTotals_Flag that has a 1 for
%        original data, 2 for interpolated data and NaN for data that
%        could not be interpolated.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: temporalInterpTotals.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('O','var') || isempty(O)
  O = false;
end
if ~exist('E','var') || isempty(E)
  E = false;
end
if ~exist('maxgap','var') || isempty(maxgap)
  maxgap = inf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Ti based on input ts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('ts','var') || isempty(ts)
  Ti = T;
else
  ts = ts(:)';
  
  % Use subsrefTUV to keep metadata easily
  Ti = subsrefTUV(T,':',ones(numel(ts)),E,O);
  Ti.OtherSpatialVars = T.OtherSpatialVars;
  
  Ti.TimeStamp = ts;
end

% Add processing steps
Ti.ProcessingSteps{end+1} = mfilename;

% Add metadata 
Ti.OtherMetadata.(mfilename).maxgap = maxgap;
Ti.OtherMetadata.(mfilename).InterpErrors = E;
Ti.OtherMetadata.(mfilename).InterpOthers = O;
Ti.OtherMetadata.(mfilename).varargin = varargin;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do interpolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ti.U = interp1_gaps( maxgap, T.TimeStamp', T.U', Ti.TimeStamp, varargin{:} )';
Ti.V = interp1_gaps( maxgap, T.TimeStamp', T.V', Ti.TimeStamp, varargin{:} )';

% Interpolation of Errors
if E & ~isempty(T.ErrorEstimates)
  for k = 1:numel(T.ErrorEstimates)
    % Normal error vars
    for f = TUVerrorMatvars
      f = f{:};
      if ~isempty( T.ErrorEstimates(k).(f) )
        xx = interp1_gaps( maxgap, T.TimeStamp', T.ErrorEstimates(k).(f)', ...
                           Ti.TimeStamp, varargin{:})';
        Ti.ErrorEstimates(k).(f) = xx;
      end
    end
    
    % Extra error vars
    if ~isempty(T.ErrorEstimates(k).OtherMatrixVars)
      for f = fieldnames(T.ErrorEstimates(k).OtherMatrixVars)'
        f = f{:};
        xx = interp1_gaps( maxgap, T.TimeStamp', ...
                           T.ErrorEstimates(k).OtherMatrixVars.(f), ...
                           Ti.TimeStamp, varargin{:} )';
        Ti.ErrorEstimates(k).OtherMatrixVars.(f) = xx;
      end  
    end
    
  end
end

% Interpolation of others
if O & ~isempty(T.OtherTemporalVars)
  for f = fieldnames(T.OtherTemporalVars)'
    f = f{:};
    xx = interp1_gaps( maxgap, T.TimeStamp', T.OtherTemporalVars.(f)', ...
                       Ti.TimeStamp, varargin{:})';
    Ti.OtherTemporalVars.(f) = xx;
  end
end
if O & ~isempty(T.OtherMatrixVars)
  for f = fieldnames(T.OtherMatrixVars)'
    f = f{:};
    xx = interp1_gaps( maxgap, T.TimeStamp', T.OtherMatrixVars.(f)', ...
                       Ti.TimeStamp, varargin{:})';
    Ti.OtherMatrixVars.(f) = xx;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flag if required
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('ts','var') || isempty(ts)
  fn = [ mfilename '_Flag' ];
  Ti.OtherMatrixVars.( fn ) = repmat(NaN,size(Ti.U));
  Ti.OtherMatrixVars.( fn )( isfinite(T.U+T.V) ) = 1;
  Ti.OtherMatrixVars.( fn )( ~isfinite(T.U+T.V) & isfinite(Ti.U+Ti.V)) = 2;
end
