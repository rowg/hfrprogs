function add_subdirectories_to_path( dn, ex, varargin )
% ADD_SUBDIRECTORIES_TO_PATH  Adds all subdirectories of a directory to the path.
%
% Usage: add_subdirectories_to_path( DIRNAME, EXCLUDES, ... )
%
% DIRNAME is the top directory.  All subdirectories (and subdirectories of
% subdirectories, etc.) will be added to the path.  This should be a full
% directory name, NO WILDCARDS.
%
% EXCLUDES is a cell array of strings listing directory names to be
% skipped.  Any subdirectory matched using the STRMATCH function by one
% of these will not be added to the path.  A typical value might be
% {'CVS','private','@'}.  This defaults to {} if not given.
%
% ... are extra arguments for the ADDPATH function.
%
% NOTE: This function works with recursion, so could run into infinite
% loops on some filesystems with strange links.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: add_subdirectories_to_path.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
  add_subdirectories_to_path( fullfile( dn, dd{:} ), ex, varargin{:} );
end

% Loop over directories and add to path
% Do this last so containing directories are higher on path than
% subdirectories.  This seems the more useful way to do it.
for dd = {a.name}
  addpath( fullfile( dn, dd{:} ), varargin{:} );
end

% Add top directory
addpath(dn)