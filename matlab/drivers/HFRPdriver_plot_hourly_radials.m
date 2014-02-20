function [ ofn, hdls, p ] = HFRPdriver_plot_hourly_radials( D, p, varargin )
% HFRPDRIVER_PLOT_HOURLY_RADIALS - This is an example driver function that
% automates generating plots of radial data grid points
%
% Usage: [ofn,handles,conf] = HFRPdriver_plot_hourly_radials(TimeStamp,conf,PARAM1,VAL1, ... )
%
% Inputs
% ------
% TimeStamp = Timestamp to work on in datenum format.
% conf = a structure with configuration parameters, can be empty
% PARAMn,VALn = name,value pairs that can override configuration parameters.
%
% Outputs
% -------
% ofn = name of file where the printed results are or would be if one had
%       chosen to print.
% handles = some of the handles from the plot
% conf = final configuration matrix
%
% Configuration Parameters
% ------------------------
% This function uses some of the parameters described in
% HFRPdriver_Totals_OMA.  In particular, it uses conf.Totals or conf.OMA
% to find the totals files for plotting.
%
% OTHER Parameters:
%
% conf.Plot.coastFile = Name of coastline file to be passed to plotBasemap.
%                       Defaults to 'hour_plot_coastline.mat'.
% conf.Plot.Projection = m_map projection to use.  Defaults to
%                        'lambert'.
% conf.Plot.plotBasemap_xargs = Cell array of extra arguments to pass to
%                               plotBasemap.  Defaults to {}.
% conf.Plot.m_grid_xargs = Cell array of extra arguments to pass to
%                          m_grid.  Defaults to some standard options.
% conf.Plot.Speckle = Boolean indicating whether to speckle
%                     coastline. Defaults to true.
%
% conf.RadialPlot.BaseDir = Defaults to '.'
% conf.RadialPlot.DomainName = name of totals domain.  Defaults to
%                            Totals.DomainName.
% conf.RadialPlot.Type = where to find radials - in totals or OMA .mat
%                        files.  Typically 'Totals' or 'OMA'.  Defaults to
%                        'Totals'.
% conf.RadialPlot.RadialType = which radial structure variable to use for
%                              plotting.  Could be 'Rorig' or 'RTUV'.
%                              Defaults to 'Rorig'.
% conf.RadialPlot.FilePrefix = Defaults to [ 'radial_plot_' DomainName '_' ]
% conf.RadialPlot.axisLims = [ minlon, maxlon, minlat, maxlat ].  Defaults
%                          to axisLims( Data, 0.1 ) if not given.
% conf.RadialPlot.DistanceBarLength = Length of distance bar.  Defaults to
%                                   10 km.
% conf.RadialPlot.ColorOrder = color order to use from plotting radial
%                              grids.  Defaults to get(gca,'colororder')
%                              before clearing plot.
% conf.RadialPlot.DistanceBarLocation = Location to put distance scale.
%                                     Defaults to 10% from upper right.
% conf.RadialPlot.plotData_xargs = Cell array of extra arguments for plotData.
%                                Defaults to {}.
% conf.RadialPlot.TitleString = string to put on title of plot.  Defaults
%                             to datestr(TimeStamp)
% conf.RadialPlot.Print = A boolean indicating whether or not to print to a
%                       file.  Defaults to false.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: HFRPdriver_plot_hourly_radials.m 457 2007-07-20 18:06:42Z jcfiguero $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default parameters and parameter checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = HFRPdriver_default_conf( p );

% Merge
mand_params = { };
p = checkParamValInputArgs( p, {}, mand_params, varargin{:} );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix default inputs that can only be done afterwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.Totals.FilePrefix;
catch
  p.Totals.FilePrefix = [ 'tuv_' p.Totals.DomainName '_' ];
end

try, p.RadialPlot.DomainName;
catch
  p.RadialPlot.DomainName = p.Totals.DomainName;
end

try, p.RadialPlot.FilePrefix;
catch
  p.RadialPlot.FilePrefix = [ 'radial_plot_' p.RadialPlot.DomainName '_' ];
end

try, p.RadialPlot.ColorOrder;
catch
  p.RadialPlot.ColorOrder = get(gca,'colororder');
end

try, p.RadialPlot.TitleString;
catch
  p.RadialPlot.TitleString = datestr(D);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load totals data (of OMA or Totals type depending on config)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = p.RadialPlot.Type;

[tdn,tfn] = datenum_to_directory_filename( p.(s).BaseDir, D, ...
                                           p.(s).FilePrefix, ...
                                           p.(s).FileSuffix, p.MonthFlag )
tdn = tdn{1};

if ~exist( tdn, 'dir' )
  mkdir(tdn);
end

R = load(fullfile(tdn,tfn{1}),p.RadialPlot.RadialType);
R = R.(p.RadialPlot.RadialType);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define axis limits if necessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.RadialPlot.axisLims;
catch, p.RadialPlot.axisLims = axisLims( R, 0.1 ); end

try, p.RadialPlot.DistanceBarLocation;
catch
  p.RadialPlot.DistanceBarLocation = p.RadialPlot.axisLims([1,3]) + ...
      0.9 * diff(reshape(p.RadialPlot.axisLims,[2,2]));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
plotBasemap( p.RadialPlot.axisLims(1:2), p.RadialPlot.axisLims(3:4), ...
             p.Plot.coastFile, p.Plot.Projection, p.Plot.plotBasemap_xargs{:} ...
             );
m_ungrid;
m_grid( p.Plot.m_grid_xargs{:} );

hold on

if p.Plot.Speckle
  m_usercoast( p.Plot.coastFile, 'speckle', 'color', 'k' )
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdls.Rgrids = [];

ss = size( p.RadialPlot.ColorOrder, 1 );

for k = 1:numel(R)
  kk = mod( k-1, ss ) + 1;
  
  RR = R(k);
  RR = subsrefRADIAL( RR, isfinite( RR.RadComp ), ':' ); % Must have 1 timestep
  hdls.Rgrids(k) = plotData( RR, 'grid', 'm_plot', 'color', ...
                             p.RadialPlot.ColorOrder(kk,:), ...
                             p.RadialPlot.plotData_xargs{:} );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot location of sites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sl = vertcat( R.SiteOrigin );
hdls.RadialSites = m_plot( sl(:,1), sl(:,2), '*r', 'markersize', 8 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add distance and velocity bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hdls.DistanceBar,hdls.DistanceBarText,p.RadialPlot.DistanceBarLocation] = ...
    m_distance_bar( p.RadialPlot.DistanceBarLength, ...
                    p.RadialPlot.DistanceBarLocation,'horiz',0.2 )
set(hdls.DistanceBar,'linewidth',2 );
set(hdls.DistanceBarText,'fontsize',16)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add title string
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdls.title = title( p.RadialPlot.TitleString, 'fontsize', 20 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print if desired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[odn,ofn] = datenum_to_directory_filename( p.RadialPlot.BaseDir, D, ...
                                           p.RadialPlot.FilePrefix, ...
                                           '.eps', p.MonthFlag );
odn = odn{1}; ofn = ofn{1};
ofn = fullfile(odn,ofn);
if p.RadialPlot.Print
  if ~exist( odn, 'dir' )
    mkdir(odn);
  end

  print('-depsc2', ofn)
end

hold off
