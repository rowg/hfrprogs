function fnames = filenames_standard_filesystem(bd,site,type,ts,mf,tf)
% FILENAMES_STANDARD_FILESYSTEM - generates a set of filenames in the
% standard SITES/TYPE/YYYY_MM/ directory hierarchy.
%
% Usage: fnames = filenames_standard_filesystem( baseDir, site, type,
%                                   TimeStamps, monthflag, typeflag )
%
% Inputs
% ------
% baseDir = base of directory hierarchy
% site = a cell array of site names
% type = a cell array of RDL types
% TimeStamps = an array of time stamps in datenum format
% monthflag = boolean indicating whether or not to include the YYYY_MM
%             directory
% typeflag = boolean indicating whether or not to include the type in the
%            directory (defaults to true)
% 
% NOTE: baseDir, site, type and TimeStamps can all have different sizes and
% shapes.  Things will be resized using repmat so that they are the same
% size before generating filenames and loading in files.  Typically, one
% would want site and type to be row vectors of the same size and TimeStamps
% to be a column vector.  This will load in all combinations of the
% site+types with all timestamps.
%
% Outputs
% -------
% fnames = cell array of filenames.  Will always be a cell array, even if
%          there is just one.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: filenames_standard_filesystem.m 599 2008-02-11 18:57:28Z cook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default typeflag
try, tf;
catch
    tf = true;
end

% Make sure all are cell arrays
bd = cellstr(bd);
site = cellstr(site);
type = cellstr(type);

% Find appropriate size of things
s = max( [ size(bd); size(site); size(type); size(ts) ] );

% Resize things
bd = repmat( bd, s ./ size(bd) );
site = repmat( site, s ./ size(site) );
type = repmat( type, s ./ size(type) );
ts = repmat( ts, s ./ size(ts) );

% Merge different pieces
if tf
    basedir = fullfile_multiple( bd, site, type );
else
    basedir = fullfile_multiple( bd, site );
end
prefix = strcat( type, '_', site, '_' );

KKK = false;
suffix = type;
for k = 1:numel(suffix)
  switch upper(type{k}(1:3))
    case 'RDL'
      suffix{k} = '.ruv';
    case 'ELT'
      suffix{k} = '.euv';
    otherwise
      KKK = true;
      suffix{k} = '.ruv';
  end      
end
if KKK
  warning( 'Some unknown types found.  Assuming file suffix of ''.ruv''' );
end

% Form full filenames
fnames = datenum_to_directory_filename( basedir, ts, prefix, suffix, mf );
fnames = reshape( fnames, s );
