function [ ofn, hdls, p ] = HFRPdriver_plot_hourly_totals( D, p, varargin )
% HFRPDRIVER_PLOT_HOURLY_TOTALS - This is an example driver function that
% automates generating plots of totals or OMA data
%
% Usage: [ofn,handles,conf] = HFRPdriver_Totals_OMA(TimeStamp,conf,PARAM1,VAL1, ... )
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
% conf.HourPlot.BaseDir = Defaults to '.'
% conf.HourPlot.DomainName = name of totals domain.  Defaults to
%                            Totals.DomainName.
% conf.HourPlot.Type = type of data to plot.  Typically 'Totals' or
%                      'OMA'.  Defaults to 'Totals'.
% conf.HourPlot.FilePrefix = Defaults to [ 'hour_plot_' Type '_' DomainName '_' ]
% conf.HourPlot.axisLims = [ minlon, maxlon, minlat, maxlat ].  Defaults
%                          to axisLims( Data, 0.1 ) if not given.
% conf.HourPlot.VectorScale = Scale to use in plotData for making
%                             vectors.  THIS ARGUMENT MUST BE SUPPLIED.
% conf.HourPlot.VelocityScaleLength = Length of velocity scale.  Defaults
%                                     to 50 cm/s.
% conf.HourPlot.VelocityScaleLocation = Location to put a velocity
%                         scale.  Defaults to 10% from upper right
%                         corner.
% conf.HourPlot.DistanceBarLength = Length of distance bar.  Defaults to
%                                   10 km.
% conf.HourPlot.DistanceBarLocation = Location to put distance scale.
%                                     Defaults to just below velocity scale.
% conf.HourPlot.ColorTicks = Color scale to use for plotting vectors.
%                            Defaults to 0:10:max_velocity.
% conf.HourPlot.ColorMap = Color map to use for plotting vectors.
%                          Defaults to 'jet'.
% conf.HourPlot.plotData_xargs = Cell array of extra arguments for plotData.
%                                Defaults to {}.
% conf.HourPlot.TitleString = string to put on title of plot.  Defaults
%                             to datestr(TimeStamp)
% conf.HourPlot.Print = A boolean indicating whether or not to print to a
%                       file.  Defaults to false.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: HFRPdriver_plot_hourly_totals.m 465 2007-07-23 23:58:13Z dmk $	
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
mand_params = { 'HourPlot.VectorScale' };
p = checkParamValInputArgs( p, {}, mand_params, varargin{:} );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix default inputs that can only be done afterwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.Totals.FilePrefix;
catch
  p.Totals.FilePrefix = [ 'tuv_' p.Totals.DomainName '_' ];
end

try, p.OMA.DomainName;
catch
  p.OMA.DomainName = p.Totals.DomainName;
end

try, p.OMA.FilePrefix;
catch
  p.OMA.FilePrefix = [ 'oma_' p.OMA.DomainName '_' ];
end

try, p.OMA.FilePrefix;
catch
  p.OMA.FilePrefix = [ 'oma_' p.OMA.DomainName '_' ];
end

try, p.HourPlot.DomainName;
catch
  p.HourPlot.DomainName = p.Totals.DomainName;
end

try, p.HourPlot.FilePrefix;
catch
  p.HourPlot.FilePrefix = [ 'hour_plot_' p.HourPlot.Type '_' ...
                      p.HourPlot.DomainName '_' ];
end

try, p.HourPlot.TitleString;
catch
  p.HourPlot.TitleString = datestr(D);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load totals data (of OMA or Totals type depending on config)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = p.HourPlot.Type;

[tdn,tfn] = datenum_to_directory_filename( p.(s).BaseDir, D, ...
                                           p.(s).FilePrefix, ...
                                           p.(s).FileSuffix, p.MonthFlag );
tdn = tdn{1};

if ~exist( tdn, 'dir' )
  mkdir(tdn);
end

data = load(fullfile(tdn,tfn{1}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define axis limits if necessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.HourPlot.axisLims;
catch, p.HourPlot.axisLims = axisLims( data.TUV, 0.1 ); end

try, p.HourPlot.VelocityScaleLocation;
catch
  p.HourPlot.VelocityScaleLocation = p.HourPlot.axisLims([1,3]) + ...
      0.9 * diff(reshape(p.HourPlot.axisLims,[2,2]));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
plotBasemap( p.HourPlot.axisLims(1:2), p.HourPlot.axisLims(3:4), ...
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
hdls = [];
[hdls.plotData,I] = plotData( data.TUV, 'm_vec', D, p.HourPlot.VectorScale, ...
                              p.HourPlot.plotData_xargs{:} );

try
  p.HourPlot.ColorTicks;
catch
  ss = max( cart2magn( data.TUV.U(:,I), data.TUV.V(:,I) ) );
  p.HourPlot.ColorTicks = 0:10:ss+10;
end

caxis( [ min(p.HourPlot.ColorTicks), max(p.HourPlot.ColorTicks) ] );
colormap( feval( p.HourPlot.ColorMap, numel(p.HourPlot.ColorTicks)-1 ) );
cax = colorbar;
hdls.colorbar = cax;
hdls.ylabel = ylabel( cax, ['NOTE: Data outside color range will be ' ...
                    'saturated.'], 'fontsize', 18 );
hdls.xlabel = xlabel( cax, 'cm/s', 'fontsize', 18 );

set(cax,'ytick',p.HourPlot.ColorTicks,'fontsize',14)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot location of sites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sl = vertcat( data.RTUV.SiteOrigin );
hdls.RadialSites = m_plot( sl(:,1), sl(:,2), '*r', 'markersize', 8 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add distance and velocity bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hdls.VelocityScaleArrow,hdls.VelocityScaleText,p.HourPlot.VelocityScaleLocation] ...
    = plotVelocityScale( p.HourPlot.VelocityScaleLength, p.HourPlot.VectorScale, ...
                         [num2str(p.HourPlot.VelocityScaleLength) ' cm/s'], ...
                         p.HourPlot.VelocityScaleLocation,'horiz', ...
                         'm_vec','linewidth',2 );
set(hdls.VelocityScaleText,'fontsize',16)
set(hdls.VelocityScaleArrow,'facecolor','k')

try, p.HourPlot.DistanceBarLocation;
catch
  p.HourPlot.DistanceBarLocation = p.HourPlot.VelocityScaleLocation - ...
      [0,0.05] .* diff(reshape(p.HourPlot.axisLims,[2,2]));
end

[hdls.DistanceBar,hdls.DistanceBarText,p.HourPlot.DistanceBarLocation] = ...
    m_distance_bar( p.HourPlot.DistanceBarLength, ...
                    p.HourPlot.DistanceBarLocation,'horiz',0.2 );
set(hdls.DistanceBar,'linewidth',2 );
set(hdls.DistanceBarText,'fontsize',16)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add title string
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdls.title = title( p.HourPlot.TitleString, 'fontsize', 20 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print if desired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[odn,ofn] = datenum_to_directory_filename( p.HourPlot.BaseDir, D, ...
                                           p.HourPlot.FilePrefix, ...
                                           '.eps', p.MonthFlag );
odn = odn{1}; ofn = ofn{1};
ofn = fullfile(odn,ofn);
if p.HourPlot.Print
  if ~exist( odn, 'dir' )
    mkdir(odn);
  end

  print('-depsc2', ofn);
end

hold off
