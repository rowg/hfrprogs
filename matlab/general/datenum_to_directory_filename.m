function [dns,fns] = datenum_to_directory_filename( p, dn, pre, post, month_dir )
%DATENUM_TO_DIRECTORY_FILENAME  Create a list of directory and file names
%
%DATENUM_TO_DIRECTORY_FILENAME - this function spits out a set of
% appropriately formatted directories and filenames given a matlab
% timestamp and some other info.
%
% USAGE_1: fullfilenames = datenum_to_directory_filename( base_dir, datenums,
%                                       filename_prefix, filename_postfix
%                                       include_month_dir );
%
% Example: datenum_to_directory_filename( 'Data/Totals/tuv',
%                                       [732678,732679], 'tuv_', '.mat'
%                                       ); 
%
% will return:
%
% { 'Data/Totals/tuv/2006_01/tuv_2006_01_01_0000.mat', ...
%   'Data/Totals/tuv/2006_01/tuv_2006_01_02_0000.mat' }
% 
% This format spits out full filenames including paths.
%
% USAGE_2: [dirnames,filenames] = datenum_to_directory_filename(...)
%
% This format will spit out the directories and the filenames (i.e., the
% part after the last /) separately.
%
% include_month_dir is an optional boolean (defaults to true).  If false,
% the month directory will not be included.
%
% Note that all arguments (except for include_month_dir) can be vectors of values
% (cell arrays or double arrays, wherever appropriate).  All vector
% arguments must have the same length for the function to work.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: datenum_to_directory_filename.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5
  month_dir = true;
end

% Convert all strings to cellstr
p = cellstr(p);
pre = cellstr(pre);
post = cellstr(post);

% Check to make sure vector arguments have same size.
nn = [ prod(size(p)), prod(size(dn)), prod(size(pre)), prod(size(post)) ];
if ~all( nn==max(nn) | nn==1 )
  error( 'Vector arguments must all have the same size.' );
end

% Create directory names
if month_dir
  dns = datenum_to_directory( p, dn );
else
  dns = repmat( p(:), [ max(nn) / prod(size(p)), 1 ] );
end

% Create filenames
fns = datenum_to_filename( dn, pre, post );

% Put together if one or less output arguments
if nargout < 2
  dns = fullfile_multiple( dns, fns );
end