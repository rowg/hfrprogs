function varargout = m_arrow( varargin )
% M_ARROW works identical to the ARROW function from the Mathworks
% user-contrib software archive, except that it translates input start
% and stop coordinates (which must be [Nx2] matrices of Lon,Lat
% coordinates) into map projection coordinates before plotting.
%
% For most details of how the function works, see arrow.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: m_arrow.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global MAP_PROJECTION

% Have to have initialized a map first
if isempty(MAP_PROJECTION),
  error('No Map Projection initialized - call M_PROJ first!');
end;

arglist = { 'Start', 'Stop', 'Length', 'BaseAngle', 'TipAngle', 'Width', ...
            'Page', 'CrossDir' };

v = {};
while ~isempty(varargin) && ~ischar(varargin{1})
  v = [ v, { arglist{1}, varargin{1} } ];
  arglist = arglist(2:end);
  varargin = varargin(2:end);  
end

if ~isempty(varargin)
  v = [ v, varargin(:)' ];
end

vn = v(1:2:end);
vv = v(2:2:end);

is = strmatch( 'Start', vn, 'exact' );
ie = strmatch( 'Stop', vn, 'exact' );

% Need to loop for multiple Start or Stop arguments
for ii = is(:)'
  [vv{ii}(:,1),vv{ii}(:,2)] = m_ll2xy( vv{ii}(:,1), vv{ii}(:,2), 'clip', ...
                                       'point' );
end
for ii = ie(:)'
  [vv{ii}(:,1),vv{ii}(:,2)] = m_ll2xy( vv{ii}(:,1), vv{ii}(:,2), 'clip', ...
                                       'off' );
end

v = [ vn(:)'; vv(:)' ];
v = v(:)';

varargout = cell( 1, nargout );
[varargout{:}] = arrow( v{:} );
