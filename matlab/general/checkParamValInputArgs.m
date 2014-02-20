function [p,pb] = checkParamValInputArgs( p, paramlist, mandparam, ...
                                          varargin )
% CHECKPARAMVALINPUTARGS  Checks a set of input arguments to a function
% for appropriate parameter value pairs.  
%
% Usage: [goodParams,badParams] = checkParamValInputArgs( Defaults, ...
%                                    ParamList, MandatoryParams, ... )
%
% Inputs
% ------
% Defaults = Structure with default values for parameters.
% ParamList = Cell array of strings with list of known parameters.  If
%             empty, then ALL parameters are assumed good.
% MandatoryParams = Cell array of strings with list of mandatory
%                   parameters. An error will result if any of these is
%                   missing.
% ... = List of param,val pairs.  Typically varargin{:} is passed to this
%       function as the last argument.
%
% Outputs
% -------
% goodParams = structure whose fields are the known input parameters.
% badParams = structure whose fields are the unknown input parameters.
%
% NOTE: This function understands nested parameter names such as
% 'field1.subfield2.subsubfield3'.  These will be appropriately dealt with
% to create a nested structure.  A nested param name like this will be
% considered "known" if it exactly matches anything in the parameter list
% OR anything in the parameter list matches one of the containing
% structures of the input param name.  For example, if the param name is
% 'a.b', and ParamList is {'a'}, then 'a.b' will be considered known, but
% a param name of 'ab' will be considered unknown.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: checkParamValInputArgs.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Odd number of parameters
if mod(length(varargin),2) == 1
  error('Poorly specified parameter list');
end

pb = struct([]);

%% Put parameters in a structure.
for k = 1:2:length(varargin)
  if ~ischar(varargin{k})
    error('Poorly specified parameter name');
  end
  
  if isempty(paramlist) || any(strmatch( varargin{k}, paramlist, 'exact' ))
    eval( [ 'p(1).' varargin{k} ' = varargin{k+1};' ] );
  else 
    % See if any parameters are enclosing structures
    n = true;
    for s = paramlist(:)'
      if strmatch( [ s{:} '.' ], varargin{k} )
        eval( [ 'p(1).' varargin{k} ' = varargin{k+1};' ] );
        n = false;
        break
      end
    end
    
    % Unknown
    if n
      eval( [ 'pb(1).' varargin{k} ' = varargin{k+1};' ] );
    end
  end
end

%% Check for mandatory parameters
for m = mandparam(:)'
  try, eval( [ 'p.' m{:} ';' ] ); 
  catch, error([ 'Missing mandatory parameter ' m{:} ]); 
  end
end
