function p = HFRPdriver_default_conf( p )
% HFRPDRIVER_DEFAULT_CONF - Returns a basic default configuration structure
% for drivers
%
% Usage: conf = HFRPdriver_default_conf( conf )
%
% The input "conf" structure is used to override defaults.  The output
% conf will contain defaults whenever the input conf did not have a value
% defined for that variable.
%
% Note that this configuration structure will not contain those variables
% whose default depends on the existence of other variables.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: HFRPdriver_Totals_OMA.m 446 2007-07-09 21:40:22Z jcfiguero $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with inputs - 1) defaults, 2) name,value pairs,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.MonthFlag;
catch, p.MonthFlag = true; end

try, p.Radials.BaseDir;
catch, p.Radials.BaseDir = '.'; end
try, p.Radials.FileSuffix;
catch, p.Radials.FileSuffix = '.ruv'; end
try, p.Radials.BearGap;
catch, p.Radials.BearGap = 3.5; end
try, p.Radials.RangeGap;
catch, p.Radials.RangeGap = 2.5; end
try, p.Radials.MaxRadSpeed;
catch, p.Radials.MaxRadSpeed = 100; end
try, p.Radials.MaskFiles;
catch, p.Radials.MaskFiles = ''; end

try, p.Totals.BaseDir;
catch, p.Totals.BaseDir = '.'; end
try, p.Totals.FileSuffix;
catch, p.Totals.FileSuffix = '.mat'; end
try, p.Totals.MinNumSites;
catch, p.Totals.MinNumSites = 2; end
try, p.Totals.MinNumRads;
catch, p.Totals.MinNumRads = 3; end
try, p.Totals.spatthresh;
catch, p.Totals.spatthresh = 3; end
try, p.Totals.tempthresh;
catch, p.Totals.tempthresh = 1/24/2-eps; end
try, p.Totals.MaxTotSpeed;
catch, p.Totals.MaxTotSpeed = 100; end
try, p.Totals.cleanTotalsVarargin;
catch, p.Totals.cleanTotalsVarargin = {}; end
try, p.Totals.MaskFile;
catch, p.Totals.MaskFile = ''; end

try, p.OMA.BaseDir;
catch, p.OMA.BaseDir = '.'; end
try, p.OMA.FileSuffix;
catch, p.OMA.FileSuffix = '.mat'; end
try, p.OMA.ModesFileName;
catch, p.OMA.ModesFileName = 'modes.mat'; end
try, p.OMA.K;
catch, p.OMA.K = 1e-3; end
try, p.OMA.ErrorType;
catch, p.OMA.ErrorType = 'constant'; end

try, p.HourPlot.BaseDir;
catch, p.HourPlot.BaseDir = '.'; end
try, p.HourPlot.Type;
catch, p.HourPlot.Type = 'Totals'; end
try, p.HourPlot.ColorMap;
catch, p.HourPlot.ColorMap = 'jet'; end
try, p.HourPlot.VelocityScaleLength;
catch, p.HourPlot.VelocityScaleLength = 50; end
try, p.HourPlot.DistanceBarLength;
catch, p.HourPlot.DistanceBarLength = 10; end
try, p.HourPlot.Print;
catch, p.HourPlot.Print = false; end
try, p.HourPlot.plotData_xargs;
catch, p.HourPlot.plotData_xargs = {}; end

try, p.RadialPlot.BaseDir;
catch, p.RadialPlot.BaseDir = '.'; end
try, p.RadialPlot.Type;
catch, p.RadialPlot.Type = 'Totals'; end
try, p.RadialPlot.RadialType;
catch, p.RadialPlot.RadialType = 'Rorig'; end
try, p.RadialPlot.DistanceBarLength;
catch, p.RadialPlot.DistanceBarLength = 10; end
try, p.RadialPlot.Print;
catch, p.RadialPlot.Print = false; end
try, p.RadialPlot.plotData_xargs;
catch, p.RadialPlot.plotData_xargs = {}; end

try, p.Plot.coastFile;
catch, p.Plot.coastFile = 'hour_plot_coastline.mat'; end
try, p.Plot.Projection;
catch, p.Plot.Projection = 'lambert'; end
try, p.Plot.plotBasemap_xargs;
catch, p.Plot.plotBasemap_xargs = {}; end
try
  p.Plot.m_grid_xargs;
catch
  p.Plot.m_grid_xargs = {'linewidth',2,'tickdir','out','linestyle','--', ...
                      'fontsize',20}; 
end
try, p.Plot.Speckle;
catch, p.Plot.Speckle = true; end
