function lims = axisLims( s, f )
% AXISLIMS Gets min and max axis limits from a data structure
%
% This function finds the spatial extent of a data structure for
% plotting.  It can deal with RADIAL, TUV, TRAJ or any structure that has
% a field named 'LonLat'.  It also handles array of such structures.
%
% Usage: LIMS = axisLims( STRUCT, FACTOR )
%
% Inputs:
% ------
% STRUCT = array of structures with data.  This can also be a two column
%          array of coordinates.
% FACTOR = A buffer to add around the limits.  Can have 1 or 2 elements.
%          For example, FACTOR=[0.1,0.2] creates a horizontal buffer at the
%          top and bottom that are each 10% of the horizontal range and
%          vertical buffers that are each 20% of the vertical range.
%          Defaults to 0.
%
% Outputs:
% -------
% LIMS = [ XMin, XMax, YMin, YMax ]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: axisLims.m 426 2007-05-19 23:02:17Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~exist( 'f', 'var' ) | isempty(f)
  f = 0;
end

% Deal with multiple structures
if isstruct(s) && numel(s) > 1
  for k = 1:numel(s)
    ll = feval( mfilename, s(k), f );
    
    if exist('lims','var')
      lims([1,3]) = min( [ lims([1,3]); ll([1,3]) ] );
      lims([2,4]) = max( [ lims([2,4]); ll([2,4]) ] );
    else
      lims = ll;
    end
    
  end
  return
end

% Deal with numeric case.
if isnumeric(s)
  ss = s;
  clear s
  s.LonLat = ss;
end

% Deal with a single structure

% Determine structure type and act appropriately
if isfield(s,'RADIAL_struct_version') || ...
      isfield(s,'TUV_struct_version')
  lims = [ min( s.LonLat ); max( s.LonLat ) ];
elseif isfield(s,'TRAJ_struct_version')
  lims = [ min( s.Lon(:) ), min( s.Lat(:) ); ...
           max( s.Lon(:) ), max( s.Lat(:) ) ];
else
  try
    lims = [ min( s.LonLat ); max( s.LonLat ) ];
  catch
    error('Unknown structure type.');
  end
end

% Add in factor
d = diff(lims);
lims(1,:) = lims(1,:) - f(:)' .* d;
lims(2,:) = lims(2,:) + f(:)' .* d;
lims = lims(:)';
