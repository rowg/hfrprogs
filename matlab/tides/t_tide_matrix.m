function [ts,xout] = t_tide_matrix( X, min_data, varargin )
% T_TIDE_MATRIX  Perform t_tide tidal analysis on the COLUMNS of a
% matrix and return results in an array of structures.
%
% Usage: [tidestruc,Xout] = t_tide_matrix( X, min_data, prop,val,... )
%
% Inputs
% ------
% X = input matrix.  Tidal analysis will be performed over columns of
%     this matrix.
% min_data = the minimum fraction of good (i.e., non-NaN) data for
%            performing tidal analysis.  Any column with a lower fraction
%            of good data will be skipped over and the resulting
%            tidestruc will be empty.  Defaults to 3 good data points
%            if empty or absent.  
% prop,val,... = standard parameter name,value pairs for t_tide.  See t_tide
%                for details.  NOTE: Any of these can be a cell array, in
%                which case they must have as many element as columns of
%                X and one such element will be used for the tidal
%                analysis of each column.
%
% Outputs
% -------
% tidestruc = array of tide structures with results.
% Xout = tidal predictions.
%
% NOTE: For more details on the ouput of this function, please see the
% t_tide function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: t_tide_matrix.m 470 2007-07-31 18:36:17Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'min_data', 'var' ) || isempty(min_data)
  min_data = 3 / size(X,1);
end

% Find cell arrays in variable arguments
for k = 1:numel(varargin)
  I(k) = iscell(varargin{k});
end
I = find(I);

gd = find( sum( ~isnan(X), 1 ) / size(X,1) > min_data );
xout = repmat( NaN, size(X) );

for k = gd(:)'
  v = varargin;
  for ii = I
    v{ii} = v{ii}{k};
  end
  [ts(k),xout(:,k)] = t_tide( X(:,k), v{:} );
end

% Make sure to include missing elements.
if ~exist('ts','var') || length(ts) < size(X,2)
  ts(size(X,2)).tidecon = [];
end

