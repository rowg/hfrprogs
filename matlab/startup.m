function startup(p)
% STARTUP adds HFR_Progs/matlab and all subdirectories to matlab path
%
% This is a simple function that principally adds the HFR_Progs/matlab
% directory and all subdirectories to the matlab path.  It also sets the
% random number generators so that they are truly random.
%
% This function will be automatically executed when matlab is started in
% this directory.
%
% This function can accept one optional argument - a string with the name
% of the head directory that is to be added to the path.  If not given,
% the output of pwd will be used.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: startup.m 439 2007-06-12 16:37:54Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 1
  p = fileparts(mfilename('fullpath')); % Start at current directory
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Randomize the random numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rand('state',sum(100*clock)) % Set random number generator
randn('state',sum(100*clock)) % Set random number generator

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add directories and subdirectories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath( p );

% Try to add path to add_subdirectories_to_path
addpath( fullfile( p, 'general' ) );

% Add rest of directory structure
add_subdirectories_to_path( p, { 'CVS', 'private', '@' } );
