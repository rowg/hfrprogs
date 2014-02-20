function [ii,nn,vv] = getNameValuePair( name, names, values, varargin )
% GETNAMEVALUEPAIR  From a cell array of names and values, picks out
% that element that matches a given string.  
%
% Note that this function is useful for picking out fields from CODAR's
% RDL radial file header format.
%
% Usage: [Index,Name,Value] = getNameValuePair( name, names, values, ... )
%
% Inputs
% ------
% name = string to match on using strmatch
% names = cell array of string names to match using the strmatch
%         function.
% values = cell array of values to pick from.  If absent or empty, will be
%          ignored.
% ... = additional arguments to strmatch (perhaps 'exact')
%
% Outputs
% -------
% Index = the indices that match the given string
% Name = the names that match the given string
% Value = values that match
%
% Note: There may be multiple matches.  Also, the return of this will
% always be a cell array even if there is just one match.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: getNameValuePair.m 425 2007-05-18 18:05:04Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ii = strmatch( name, names, varargin{:} );

if isempty( ii )
  warning( [ mfilename ':NO_MATCHES' ], 'No matches found for ''%s''', name );
end

if numel( ii ) > 1
  warning( [ mfilename ':MULT_MATCHES' ], 'Multiple matches found.' );
end

nn = names(ii);

if ~exist( 'values', 'var' ) || ( isempty(values) && ~isempty(names) )
  return
end

vv = values(ii);
