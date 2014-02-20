function [R,index] = maskRadials(R,maskFileName,InOrOut,varargin)
% MASKRADIALS  Removes radial current measurements that are outside a polygon.
%
% Usage: [RAD2,I] = maskRadials(RAD1,maskFileName, InOrOut, ... )
%
% Inputs
% ------
% RAD1 = a RADIAL structure or an array of RADIAL structures to be
%        trimmed.  If RAD1 is an array of radial structures, then the
%        returned RAD2 will be as well and I will be a cell array of
%        indexes.
% maskFileName = a string filename of a text data file that contains the
%                mask polygon.  It can also be a two column matrix of
%                polygon coordinates.  It can also be a cell array with one
%                string or matrix for every element of the RAD1 structure
%                array.  In this last case, it must have the same length as
%                RAD1.  If a mask file or matrix is empty, a warning will be
%                generated and it will be ignored.
% InOrOut = a boolean indicated whether to keep grid points inside (1 or
%           true) or outside the mask polygon. Defaults to true.
% ... = Extra arguments that are passed to subsrefRADIAL - see that function
%       for more details.  Typically specify whether to trim other variables
%       as well.
%
% Outputs
% -------
% RAD2 = RADIAL structure with cleaned data
% I = logical index the same size as the original number of grid points
%     with true for every grid point that was kept (i.e. not trimmed).
%     If RAD1 was an array of RADIAL strucutures, then I will be a cell
%     array with one element for each of the original RADIAL structures. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: maskRadials.m 447 2007-07-12 18:34:59Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults
if ~exist( 'InOrOut', 'var' ), InOrOut = true; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with case of multiple radial structures.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if numel(R) > 1
  index = cell(size(R));
  
  for k = 1:numel(R)
    if iscell(maskFileName)
      [R(k),index{k}] = maskRadials( R(k), maskFileName{k}, InOrOut, ...
                                     varargin{:} );
    else
      [R(k),index{k}] = maskRadials( R(k), maskFileName, InOrOut, ...
                                     varargin{:} );
    end
  end
  
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Single radial structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add processing steps
R.ProcessingSteps{end+1} = mfilename;

% Return if no data
if isempty( R.RadComp )
  warning( [ '##' mfilename ': No data in RADIAL structure' ] );
  index = [];
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine type of mask given
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[mask,maskFileName,code] = loadDataFileWithChecks( maskFileName );
if code >= 1000
  mask = [];
  maskFileName = 'BAD_MASK_TYPE';
  warning( 'Ignoring bad mask type. Probably something is wrong.' );
end

if code == 1 
  maskFileName = 'MATRIX';
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Indices of data we don't want
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(mask)
  % Empty mask file
  warning( [ '##' mfilename ': Mask ''' maskFileName ...
             ''' is empty or of bad type ' ...
             '... no masking will be performed.' ] );
  index = true( size(R.LonLat(:,1)) );
else
  index = inpolygon(R.LonLat(:,1), R.LonLat(:,2), mask(:,1), mask(:,2));  
end

if ~InOrOut
  index = ~index;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now chop down RADIAL according to indices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R = subsrefRADIAL( R, index, ':', varargin{:} );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now save metadata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R.OtherMetadata(1).(mfilename).maskFileName = maskFileName;
R.OtherMetadata.(mfilename).InOrOut = InOrOut;
R.OtherMetadata.(mfilename).varargin = varargin;
