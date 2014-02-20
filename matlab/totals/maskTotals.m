function [T,index] = maskTotals(T,maskFileName,InOrOut,varargin)
% MASKTOTALS  Removes totals current grid points 
%
% Usage: [TUV2,I] = maskTotals(TUV1,maskFileName,InOrOut, ... )
%
% Inputs
% ------
% TUV1 = a totals structure to be trimmed
% maskFileName = a string filename of a text data file that contains the
%                mask polygon.  It can also be a two column matrix of
%                polygon coordinates. If the mask file can't be found, an
%                error will be generated, but if it or the matrix are empty,
%                a warning will be generated.
% InOrOut = a boolean indicated whether to keep grid points inside (1 or
%           true) or outside the mask polygon. Defaults to true.
% ... = Extra arguments that are passed to subsrefTUV - see that function
%       for more details.  Typically specify whether to trim errors and
%       other variables as well.
%
% Outputs
% -------
% TUV2 = TUV structure with grid points removed.
% I = logical index the same size as the original number of grid points
%     with true for every grid point that was kept (i.e. not trimmed) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: maskTotals.m 447 2007-07-12 18:34:59Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults
if ~exist( 'InOrOut', 'var' ), InOrOut = true; end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;

% Return if no data
if isempty( T.U )
  warning( [ '##' mfilename ': No data in TUV structure' ] );
  index = [];
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine type of mask given
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[mask,maskFileName,code] = loadDataFileWithChecks( maskFileName );
if code >= 1000
  mask = [];
  warning( 'Ignoring bad mask type. Probably something is wrong.' );
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Indices of data we don't want
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(mask)
  % Empty mask file
  warning( [ '##' mfilename ': Mask is empty or of bad type ' ...
             '... no masking will be performed.' ] );
  index = false( size(T.LonLat(:,1)) );
else
  index = inpolygon(T.LonLat(:,1), T.LonLat(:,2), mask(:,1), mask(:,2));  
end

if ~InOrOut
  index = ~index;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now chop down TUV according to indices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = subsrefTUV( T, index, ':', varargin{:} );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now save metadata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T.OtherMetadata(1).maskTotals.maskFileName = maskFileName;
T.OtherMetadata(1).maskTotals.InOrOut = InOrOut;
T.OtherMetadata.maskTotals.varargin = varargin;
