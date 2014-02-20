function fns = datenum_to_filename( dn, pre, post )
% DATENUM_TO_FILENAME  Create a list of file names
%
% Usage: filenames = datenum_to_filename( datenums, filename_prefix,
%                                         filename_postfix );
%
% Example: datenum_to_filename( [732678,732679], 'tuv_', '.mat' ); 
%
% will return:
%
% { 'tuv_2006_01_01_0000.mat', ...
%   'tuv_2006_01_02_0000.mat' }
% 
% Note that all arguments can be vectors of values (cell arrays or double
% arrays, wherever appropriate).  All vector arguments must have the same
% length for the function to work.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: datenum_to_filename.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('post','var'), post=''; end

% Convert all strings to cellstr
pre = cellstr(pre);
post = cellstr(post);

% Get the YYYY_MM_DD_HHMM strings
dn = datevec( dn(:) );
s = strcat( num2str(dn(:,1),'%04d'), '_', num2str(dn(:,2),'%02d'), '_', ...
            num2str(dn(:,3),'%02d'), '_', num2str(dn(:,4),'%02d'), ...
            num2str(dn(:,5),'%02d') );

% Filenames
fns = strcat( pre(:), s, post(:) );
