function [ d, fn, c ] = loadDataFileWithChecks( fn )
% LOADDATAFILEWITHCHECKS  Loads a text data file, but does some basic checking
% to see if the file exists and the data is not empty.
%
% Usage: [ data, filename, code ] = loadDataFileWithChecks( filename )
%        [ data, filename, code ] = loadDataFileWithChecks( data )
%
% Inputs
% ------
% filename = a string filename of a text data file (i.e., a tab or comma
%            delimited file of the type matlab likes) to be loaded.  This
%            can also be a data matrix, in which case the same data will be
%            passed back (useful if you are not sure if argument is a
%            filename or data).  In this case, the returned filename will be
%            'MATRIX'.
%
% Outputs
% -------
% data = the result of load(filename) if a string filename was passed to
%        the function.  Otherwise the original argument to the function
%        is just passed back.
% filename = if the original filename was a valid string filename, then
%            this will just be the filename.  If the file does not exist,
%            then this will be [ 'NOT FOUND: ' filename ].  If the
%            original argument to the function was a data matrix, this
%            will be 'MATRIX'.  Otherwise, it will be 'BAD TYPE'.
%
% code = 0 for good string filename that can be loaded, 1 for data matrix,
%        10 for file that is emtpy, 100 for file that does not exist, 1000
%        for file that cannot be loaded, 1e10 otherwise.  Might be a sum of
%        these.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: loadDataFileWithChecks.m 471 2007-08-21 22:52:08Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch class(fn)
  case 'char'
    % Does the file exist?
    if ~exist(fn,'file')  ||  exist(fn,'dir')
      warning( [ '## ' mfilename ':  File ' fn ' could not be found.' ] );
      d = [];
      fn = [ 'NOT FOUND: ' fn ];
      c = 100;
    else
      try
        c = 0;
        d = load(fn);
      catch
        warning(lasterr);
        
        warning( [ '## ' mfilename ': File ' fn ' could not be loaded ' ] ...
                 );
        
        fn = [ 'UNLOADABLE: ' fn ];
        
        c = 1e3;
        d = [];
      end
    end
  case 'double'
    d = fn;
    fn = 'MATRIX';
    c = 1;
  otherwise
    warning( [ '##' mfilename ':  Unknown data type passed to function.' ] );
    d = fn;
    fn = 'BAD TYPE';
    c = 1e10;
end

if isempty(d)
  c = c + 10;
end
