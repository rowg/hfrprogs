function varargout = my_getappdata( varargin )
% MY_GETAPPDATA Same as GETAPPDATA, but uses GETUPROP if GETAPPDATA not
% around

if exist( 'getappdata', 'builtin' )
  [ varargout{1:nargout} ] = getappdata( varargin{:} );
else
  [ varargout{1:nargout} ] = getuprop( varargin{:} );
end

  
 
  