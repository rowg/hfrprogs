function [T,I] = cleanTotals(T,maxspd,varargin)
% CLEANTOTALS  Remove total current measurements exceeding speed or error thresholds
% CLEANTOTALS - cleans out total current measurements that have the speed
% above some value or have error magnitudes above some value.
%
% Usage: [TUVclean,I] = cleanTotals(TUVorig,maxspd,MAXERRORVARS...)
%
% Bad total current measurements will be replaced with NaN.  No changes
% will be made to any other matrix variables in OtherMatrixVars or in
% ErrorEstimates.  In particular, this will leave the large error values
% in place even though associated currents are now NaN.
%
% Inputs
% ------
% TUVorig = a TUV structure to be cleaned
% maxspd = a maximum total speed cutoff. Defaults to inf if empty.
% MAXERRORVARS = one or more additional arguments to the function.  Each
%                one must be a cell array with three element:
%                { ErrorTypeStr, ErrorVariableStr, MaxError }.  A typical
%                example would be { 'GDOPMaxOrthog','TotalErrors',2 }.
%
% Outputs
% -------
% TUVclean = Cleaned TUV structure
% I = Index of data points that were removed.  This will have a zero for
%     good data, a 1 for data whose speed is above maxspd, a 2 for data
%     violated first error condition, a 4 for data violating second error
%     condition, etc.  For data violating multiple conditions, the result
%     will be a sum of all the violated conditions.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: cleanTotals.m 475 2007-09-06 01:39:23Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Defaults
if isempty(maxspd), maxspd = inf; end

% For indexing
ii = 2.^(1:length(varargin));

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now deal with max speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
I = double( cart2magn( T.U, T.V ) > maxspd );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Error maxes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(varargin)
  v = varargin{k};
  i = ii(k);
  
  if length(v) ~= 3
    error( 'One of max error variables poorly specified.' );
  end
  
  j = strmatch( v{1}, { T.ErrorEstimates.Type }, 'exact' );
  if isempty(j)
    error( [ 'Unknown error type: ' v{1} ] );
  end
  
  try
    V = T.ErrorEstimates(j(1)).(v{2});
  catch
    error( [ 'Uknown error variable: ' v{2} ] );
  end

  I = I + i * ( abs(V) > v{3} );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T.U(I>0) = NaN;
T.V(I>0) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now save metadata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T.OtherMetadata(1).(mfilename).maxspd = maxspd;
T.OtherMetadata.(mfilename).MaxErrorVars = varargin;
