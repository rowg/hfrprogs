function my_setappdata( varargin )
% MY_SETAPPDATA Same as SETAPPDATA, but uses SETUPROP if SETAPPDATA not
% around

if exist( 'setappdata', 'builtin' )
  setappdata( varargin{:} )
else
  setuprop( varargin{:} )
end

  
 
  