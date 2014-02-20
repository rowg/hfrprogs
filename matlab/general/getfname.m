function File = getfname(Path)
% GETFNAME  Get the names of all specified files in a directory
%
% Usage:  Fname = getfname(Path)
%
% Inputs: Path = Can Include a directory path and filename filter
%                (Default = './*.m')
%
% Output: Fname  = Character array of filenames
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Brian Schlining, 
%                    David M. Kaplan, and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Originally by B. Schlining - 10 Jul 1997
% Modified to handle cell arrays, Mike Cook and David Kaplan - feb 2007


if nargin < 1
   Path = '*.m';
end

FDat  = dir(Path);
[r c] = size(FDat);

if r == 0
   File = {};
else
   File = {FDat.name};
end