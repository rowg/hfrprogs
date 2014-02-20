function [h,fn,ff] = getRDLHeader( filename )
% GETRDLHEADER  Gets the header of RDL files
%
% The "header" of RDL files is any line beginning with "%", regardless of
% whether or not it is at the beginning of the file.
%
% Usage: header = getRDLHeader( filename )
%        [names, values] = getRDLHeader( filename )
%        [header, names, values] = getRDLHeader( filename )
%
% In the first usage, the raw header (i.e., any line beginning with "%")
% is returned as a cell array of strings.  
%
% In the second usage, each line of the header is split into field names
% (i.e., anything before the first ":") and field values (anything after
% the first ":").  This is the current CODAR file format convention.
%
% In the third usage, all three are returned.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: getRDLHeader.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( filename, 'file' )
  error( [ filename ' does not appear to exist.' ] );
end

% Reads entire file and then trims it down to header.
h = textread(filename,'%[^\n]',-1);
n = strmatch( '%', h );
h = h(n);

% Next split lines if desired.
if nargout > 1
  fn = {}; ff = {};
  for k = 1:length(h)
    % This way is considerably more efficient than using strtok
    ii = min( [ find( h{k} == ':' ), length(h{k})+1 ] );
    fn{end+1,1} = strtrim(h{k}(2:ii-1)); % Remove initial %
    ff{end+1,1} = strtrim(h{k}(ii+1:end)); % Removie initial :
  end
end

% If exactly two args out do this:
if nargout == 2
  h = fn;
  fn = ff;
  clear ff
end


