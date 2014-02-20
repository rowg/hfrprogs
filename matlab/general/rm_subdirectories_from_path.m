function rm_subdirectories_from_path( dn, ex, varargin )
% RM_SUBDIRECTORIES_FROM_PATH  Removes all subdirectories of a directory on the path.
%
% Usage: rm_subdirectories_from_path( DIRNAME, EXCLUDES, ... )
%
% DIRNAME is the top directory.  This directory and all subdirectories (and
% subdirectories of subdirectories, etc.) will be removed from path.  This
% should be a full directory name, NO WILDCARDS.
%
% EXCLUDES is a cell array of strings listing directory names to be
% skipped.  Any subdirectory matched using the STRMATCH function by one
% of these will not be removed to the path.  A typical value might be
% {'CVS','private','@'}.  This defaults to {} if not given.
%
% ... are extra arguments for the RMPATH function.
%
% NOTE: This function works with recursion, so could run into infinite
% loops on some filesystems with strange links.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: rm_subdirectories_from_path.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
  ex = {};
end

if ischar(ex), ex = cellstr(ex); end

a = dir( dn );
a = a( [ a.isdir ] );

% Remove excluded directories, including . and ..
for ee = [ { '.', '..' }, ex(:)' ]
  I = strmatch( ee{:}, {a.name} );
  a(I) = [];
end

% Loop over directories and call this function again
for dd = {a.name}
  rm_subdirectories_from_path( fullfile( dn, dd{:} ), ex, varargin{:} );
end

% Loop over directories and add to path
% Do this last so containing directories are higher on path than
% subdirectories.  This seems the more useful way to do it.
for dd = {a.name}
  rmpath( fullfile( dn, dd{:} ), varargin{:} );
end

rmpath( dn );
