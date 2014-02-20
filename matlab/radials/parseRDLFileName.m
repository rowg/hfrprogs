function [ts,sites,types,kk] = parseRDLFileName( fn )
% PARSERDLFILENAME  Parse out the useful info from RDL filenames
%
% Usage: [TimeStamps,Sites,Types,I] = parseRDLFileName( Filenames )
%
% Inputs
% ------
% Filenames = a cell array or character array of filenames
%
% Outputs
% -------
% TimeStamps = a datenum timestamp for each filename
% Sites = sites of each filename.  Result will be a cell array if input
%         was a cell array, a character array if the input was a
%         character array.
% Types = type of each file (e.g., 'RDLi' or 'RDLm').  Cell or character
%         array according to input format.
% I = Indices for original input list of filenames that could NOT be parsed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: parseRDLFileName.m 471 2007-08-21 22:52:08Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ch = ischar(fn);
if ch, fn = cellstr(fn); end

ts = repmat(NaN,size(fn));
sites = repmat( {''}, size(fn) );
types = repmat( {''}, size(fn) );

kk = [];
for k = 1:numel(fn)
  f = fn{k};
  
  try
    [a,f,c] = fileparts( f );
    f = cellstr( strparser(f,'_') );
    
    ymd = str2num( char( f(3:5) ) )';
    f{end} = [ f{end}(1:2) ' ' f{end}(3:4) ];
    hm = str2num( f{end} );
    
    types{k} = f{1};
    sites{k} = f{2};
    
    ts(k) = datenum( [ ymd hm 0 ] );
  catch
    kk = [ kk, k ];
    warning( [ 'Could not parse filename ''' fn{k} ''' - skipping' ] );
  end
end

if ch
  types = char(types);
  sites = char(sites);
end
