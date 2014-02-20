function fields = strparser(input_line,delimiter)
% STRPARSER  Break a string into pieces, or tokens.
%
% Usage:
%       TOKENS = STRPARSER(STRING)
% Create a char array TOKENS that contains the strings in STRING delimited
% by a space.
%
%       TOKENS = STRPARSER(STRING,DELIMITER)
% TOKENS are the strings in STRING delimited by DELIMITER.
%
% EXAMPLE:
%       fields = strparser('now,or, later. Which is,it?',',')
%
% will produce:
% fields =
%
% now             
% or              
% later. Which is
% it?       

% Mike Cook, NPS Oceanography Dept., 21AUG98.  
% Modified from code on p.11-12 of USING MATLAB Version 5 manual.  
% Added strjust 'left' so that all blanks are on right of array.    

if nargin < 2
   delimiter = ' ';
end

remainder = input_line;
fields = '';

while (any(remainder))
   [chopped,remainder] = strtok(remainder,delimiter);
   fields = strvcat(fields,chopped);
end

fields = strjust(fields,'left');
