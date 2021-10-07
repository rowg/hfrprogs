function [h,ts] = plotData( T, pfunc, varargin )
% PLOTDATA  general function for making plots of total vector currents
%
% This function has several different usages for the different types of
% plots that it can make.
%
% Usage1: handles = plotData( T, 'grid', plot_func, ... )
% Usage2: handles = plotData( T, 'perc', plot_func, clim, ... )
% Usage3: [handles,TimeIndex] = plotData(T,plot_func,TimeIndex,scale,...)
%
% In all usages, T is a structure with fields U, V, LonLat and TimeStamp.
% This is typically a TUV structure generated by makeTotals or the like, but
% this is not required.  In particular, a RADIAL structure will also work
% just fine. The dimensions of the fields must be as those in a typical TUV
% structure - one row for each spatial grid point, one column for each
% timestep.
%
% In the first usage, the data grid is plotted as a set of dots.
% plot_func should be a string function name, typically 'plot' or
% 'm_plot'.  Defaults to 'm_plot' if empty or absent.  ... are further
% arguments to plot_func.
%
% In the second usage, the percent coverage for each data grid point will
% be plotted (i.e. the percent of the time that each grid point has good
% data) as a set of colored dots using the colordot function.  plot_func is
% the plotting function to use, typically 'line' or 'm_line'.  See colordot
% for more details.  Defaults to 'm_line' if empty or absent.  clim is as in
% the colordot function and will assume the same default value as in that
% function if empty or absent. ... are further arguments to plot_func.
%
% In the third usage, current vectors are plotted.  In this case, plot_func
% can be 'quiver', 'm_quiver', 'm_vec', 'arrow' or 'm_arrow'.  It can also
% be an arbitrary function name, which must accept arguments like
% plot_func(Lon,Lat,U,V,...).  TimeIndex can either be a number indicating
% which column of U and V to plot, or a datenum date, in which case the
% TimeStamp closest to TimeIndex will be plotted. scale is a number
% indicating how much to scale the vectors.  Defaults to 1 if absent or
% empty.  In all cases, scaling is done directly to the U and V components,
% and automatic or built-in scaling is turned off for all known plot_func
% (e.g., 'quiver', 'm_quiver', etc.).
%
% If 'quiver' is selected for plotting, then T.U,T.V are assumed to be in
% cm/'time unit' and will be converted to 'Decimal Degrees'/'time unit'
% based on the Lon,Lat coordinates in T.LonLat before plotting.
%
% If 'm_vec' is selected for plotting, then vectors will be colored by
% their magnitude.  
%
% If 'arrow' or 'm_arrow' are selected for plotting, then T.LonLat,T.U,T.V
% will be changed into start,stop as required by those functions.  In both
% cases, it is assumed that T.LonLat actually contain longitude and latitude
% and T.U,T.V are in cm/'time unit'. These will both be converted into
% 'Decimal Degrees'/'time unit' before being adjusted by the scale factor
% and added to the T.LonLat to calculate the Stop coordinates.
%
% If an unknown plot_func is selected for plotting, then no alteration
% of LonLat,U,V is performed other than multiplying U,V by the scale
% factor.
%
% This function returns the handles of the items plotted.  In the third
% usage, the index of the U,V column that was plotted will also be
% returned.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: plotData.m 682 2008-09-24 08:47:29Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch pfunc
  case 'grid'
    if isempty(varargin) || isempty(varargin{1})
      pfunc = 'm_plot';
    else
      pfunc = varargin{1};
    end
    
    h = feval(pfunc,T.LonLat(:,1),T.LonLat(:,2),'.',varargin{2:end});
    return
    
  case 'perc'
    if isempty(varargin) || isempty(varargin{1})
      pfunc = 'm_line';
    else
      pfunc = varargin{1};
    end
    varargin = varargin(2:end);
    
    if isempty(varargin)
      clim = [];
    else
      clim = varargin{1};
    end
    varargin = varargin(2:end);    
    
    p = 100 * sum( isfinite(T.U+T.V), 2 ) / size(T.U,2);
    [h,ts] = colordot( T.LonLat(:,1),T.LonLat(:,2),p,clim,pfunc, ...
                       varargin{:});
    return
    
end

% Otherwise want to plot vectors
ts = varargin{1};

scale = 1;
if numel(varargin) > 1 && ~isempty(varargin{2})
  scale = varargin{2};
end

varargin = varargin(3:end);

% Deal with ts
if ts > size(T.U,2)
  disp( 'It appears that a datenum date was given for TimeIndex.' );
  if ts < datenum(1900,1,1)
    warning('Strange date given for TimeIndex!');
  end
  
  [dt,ts] = min( abs(ts-T.TimeStamp) );
end

% Pull out good data at timestep.
U = T.U(:,ts);
V = T.V(:,ts);

gg = isfinite(U+V);
LL = T.LonLat(gg,:);
U = U(gg);
V = V(gg);

% Busy work before multiplying by scale factor
switch pfunc
  case {'m_vec','m_vec_same'}
    % Get magnitude for coloring
    mm = cart2magn( U, V );
  case {'quiver','arrow','m_arrow'}
    % Convert to 'Decimal Degrees'/unit time
    [ln,lt] = LonLatPerCM( LL(:,1), LL(:,2) );
    [U,V] = deal( ln .* U, lt .* V );
end

% Multiple by scale factor
%[U,V] = deal( U * scale, V * scale );

% Do plotting of vectors
if ~isempty(LL)
  switch pfunc
    case {'quiver','m_quiver'}
      h = feval( pfunc, LL(:,1), LL(:,2), U, V, 0, varargin{:} );
    case 'm_vec'
      h = m_vec( 1, LL(:,1), LL(:,2), U, V, mm, varargin{:} );
    case 'm_vec_same'
      vector=U+sqrt(-1)*V;
      vector=vector./mm;
      U=real(vector);
      V=imag(vector);
      h = m_vec( 10, LL(:,1), LL(:,2), U, V, mm, varargin{:} );
    case {'arrow','m_arrow'}
    h = feval( pfunc, LL, LL + [U,V], varargin{:} );
    otherwise
      h = feval( pfunc, LL(:,1), LL(:,2), U, V, varargin{:} );
  end
else
  h = [];
end