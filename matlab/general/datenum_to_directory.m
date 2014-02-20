function dns = datenum_to_directory( p, dn )
%DATENUM_TO_DIRECTORY  Create a list of directory names
%
% DATENUM_TO_DIRECTORY - this function spits out a set of
% appropriately formatted directories given a matlab
% timestamp and some other info.
%
% USAGE: dirnames = datenum_to_directory( base_dir, datenums );
%
% Example: datenum_to_directory( 'Data/Totals/tuv', [732678,732679] )
%
% will return:
%
% { 'Data/Totals/tuv/2006_01', ...
%   'Data/Totals/tuv/2006_01' }
% 
% Note that all arguments can be vectors of values (cell arrays or double
% arrays, wherever appropriate).  All vector arguments must have the same
% length for the function to work.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: datenum_to_directory.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dn = datevec( dn(:) );
s = strcat( num2str(dn(:,1),'%04d'), '_', num2str(dn(:,2),'%02d') );

dns = fullfile_multiple( p, s );
