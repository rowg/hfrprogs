function T = temporalFilterTotals( T, B, A, func, ferr, foth, varargin )
% TEMPORALFILTERTOTALS  Filter total currents in the time direction
% 
% This is a basic wrapper function around the filter functions of matlab
% that allows for quick temporal filtering of totals.
% 
% Usage: TUV = temporalFilterTotals(TUV,B,A,filtfunc,errors,others,...)
%
% Inputs
% ------
% TUV = TUV structure to filter
% B,A = Standard arguments to filter functions.  See filter for details.
% filtfunc = name of filter function to use for filtering.  Defaults to
%            'filttappered' if empty or absent.  'filtfilt' is also a
%            good option if you have access to the statistics toolbox.
% errors = boolean indicating whether or not to filter variables in
%          ErrorEstimates.  Defaults to false.
% others = boolean indicating whether or not to filter variables in
%          OtherMatrixVars and OtherTemporalVars.  Defaults to false.
% ... = extra arguments for filter function.
%
%
% NOTE: TUV.TimeStamp will always be filtered along with U and V.  This
% is useful for identifying bias in the filter.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: temporalFilterTotals.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'ferr', 'var' ), ferr = false; end
if ~exist( 'foth', 'var' ), foth = false; end
if ~exist( 'func', 'var' ), func = 'filttappered'; end

% Do basic filtering
T.TimeStamp = feval( func, B, A, T.TimeStamp', varargin{:} )';
T.U = feval( func, B, A, T.U', varargin{:} )';
T.V = feval( func, B, A, T.V', varargin{:} )';

% Error filtering - ignores OtherMatrixVars in errors!!!
if ferr 
  for k = 1:numel(T.ErrorEstimates)
    for f = { 'Uerr', 'Verr', 'UVCovariance', 'TotalErrors' }
      f = f{:};
      if ~isempty( T.ErrorEstimates(k).(f) )
        T.ErrorEstimates(k).(f) = feval( func, B, A, T.ErrorEstimates(k).(f)', ...
                                         varargin{:} )';
      end
    end
  end
end

% OtherTemporal
if ~isempty( T.OtherTemporalVars )
  for f = fieldnames( T.OtherTemporalVars )'
    f = f{:};
    if ~isempty( T.OtherTemporalVars.(f) )
      T.OtherTemporalVars.(f) = feval( func, B, A, T.OtherTemporalVars.(f)', ...
                                       varargin{:} )';
    end
  end
end
              
% OtherMatrix
if ~isempty( T.OtherMatrixVars )
  for f = fieldnames( T.OtherMatrixVars )'
    f = f{:};
    if ~isempty( T.OtherMatrixVars.(f) )
      T.OtherMatrixVars.(f) = feval( func, B, A, T.OtherMatrixVars.(f)', ...
                                       varargin{:} )';
    end
  end
end
              
% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

% Metadata
T.OtherMetadata(1).(mfilename).filter_function = func;
T.OtherMetadata(1).(mfilename).filter_errors = ferr;
T.OtherMetadata(1).(mfilename).filter_others = foth;
