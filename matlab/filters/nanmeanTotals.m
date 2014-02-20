function TT = nanmeanTotals( T, DIM, err, oth )
% NANMEANTOTALS  Computes nanmean of elements of a TUV structure
%
% Usage: T2 = nanmeanTotals( T1, DIM, mean_errors, mean_others )
%
% Inputs
% ------
% T1 = Input TUV structure
% DIM = Dimension along which to perform meaning.  Defaults to 2
%       (temporal meaning) if empty or absent.
% mean_errors = Boolean indicating whether or not to attempt meaning of
%               ErrorEstimates.  Defaults to false.
% mean_others = Boolean indicating whether or not to attempt meaning of
%               OtherMatrixVars and OtherTemporalVars or OtherSpatialVars
%               ( depending on value of DIM). Defaults to false.
%
% Outputs
% -------
% T2 = TUV structure that has had nanmean applied.
%
% NOTE: If this function does not nanmean errors and others, it will
% replace them with appropriately sized matrices of NaN.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: nanmeanTotals.m 476 2007-09-06 01:39:50Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('err','var')
  err = false;
end
if ~exist('oth','var')
  oth = false;
end
if ~exist('DIM','var') || isempty(DIM)
  DIM = 2;
end

% First pull out a single timestep or grid point of input TUV to put meaning
% info in.
switch DIM
  case 1
    % First try subsref of everything
    TT = subsrefTUV( T, 1, ':', err, oth );
    TT.OtherTemporalVars = T.OtherTemporalVars; % This should be untouched
    
    % Mean of basic stuff - doesn't make much sense, but why not.
    TT.LonLat = nanmean( T.LonLat, 1 );
    
    % Mean of OtherSpatialVars
    if oth & ~isempty( T.OtherSpatialVars )
      for f = fieldnames( T.OtherSpatialVars )'
        f = f{:};
        TT.OtherSpatialVars.(f) = nanmean(T.OtherSpatialVars.(f),1);
      end
    end
  
  case 2
    % First try subsref of everything
    TT = subsrefTUV( T, ':', 1, err, oth );
    TT.OtherSpatialVars = T.OtherSpatialVars; % This should be untouched
    
    % Mean of basic stuff
    TT.TimeStamp = nanmean( T.TimeStamp, 2 );
  
    % Mean of OtherTemporalVars
    if oth & ~isempty( T.OtherTemporalVars )
      for f = fieldnames( T.OtherTemporalVars )'
        f = f{:};
        TT.OtherTemporalVars.(f) = nanmean(T.OtherTemporalVars.(f),2);
      end
    end
  
  otherwise
    error( 'Bad DIM argument.' );
end

% Mean of U and V
[m,c] = nanmean( T.U + i*T.V, DIM );
TT.U = real(m);
TT.V = imag(m);
TT.V( isnan(TT.U) ) = NaN;

% Keep track of how many totals contributed
TT.OtherMatrixVars.( [ mfilename '_num_totals' ] ) = c;

% Mean of errors
if err
  for k = 1:numel(T.ErrorEstimates)
    for f = { 'Uerr', 'Verr', 'UVCovariance', 'TotalErrors' }
      f = f{:};
      TT.ErrorEstimates(k).(f) = nanmean( T.ErrorEstimates(k).(f), DIM );
    end
    if ~isempty( T.ErrorEstimates(k).OtherMatrixVars )
      for f = fieldnames( T.ErrorEstimates(k).OtherMatrixVars )'
        f = f{:};
        TT.ErrorEstimates(k).OtherMatrixVars.(f) = ...
            nanmean(T.ErrorEstimates(k).OtherMatrixVars.(f),DIM);
      end
    end
  end
end

% Mean of OtherMatrixVars
if oth & ~isempty( T.OtherMatrixVars )
  for f = fieldnames( T.OtherMatrixVars )'
    f = f{:};
    TT.OtherMatrixVars.(f) = nanmean(T.OtherMatrixVars.(f),DIM);
  end
end

% Add processing steps
TT.ProcessingSteps{end+1} = mfilename;

% Metadata
TT.OtherMetadata(1).(mfilename).DIM = DIM;
TT.OtherMetadata(1).(mfilename).mean_errors = err;
TT.OtherMetadata(1).(mfilename).mean_others = oth;
