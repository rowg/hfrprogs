function fns = fullfile_multiple( varargin )
% FULLFILE_MULTIPLE  This is like the fullfile function, except that it
% can do multiple files at once.
%
% Usage: filenames = fullfile_multiple( ... )
%
% where ... are any number of cellstr's or character arrays.  All
% cellstr's must either be of length 1 or N, and all character arrays
% must either have 1 or N rows.
%
% NOTE: The result of this function will always be a cellstr, even if
% that cellstr has length 1.
%
% NOTE: This function could get rather slow for long lists of filenames
% because the problem is highly non-vectorizable.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: fullfile_multiple.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for k = 1:nargin
  % Make sure it is a cellstr
  varargin{k} = cellstr(varargin{k});
  varargin{k} = varargin{k}(:);

  % Get lengths of each input
  nn(k) = length(varargin{k});
end

% Check sizes of inputs
if ~all( nn==max(nn) | nn==1 )
  error( 'Vector arguments must all have the same size.' );
end

fns = {};
for k = 1:max(nn)
  % Get 1 for singleton arguments.
  n = min( [ nn; repmat(k,[1,length(nn)]) ] );
  
  % Pick out pieces to be joined.
  v = {};
  for l = 1:nargin
    v{l} = varargin{l}{n(l)};
  end
  
  fns{k} = fullfile(v{:});
end
