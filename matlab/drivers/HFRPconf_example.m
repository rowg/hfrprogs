function conf = HFRPconf_example
% HFRPCONF_EXAMPLE - An example configuration file for the HFRP drivers
%
% You would typically create one of these per Domain

thisDir = fileparts( mfilename('fullpath') );
demoDir = fullfile(thisDir,'..','demo');

% Radials
conf.Radials.BaseDir = '/home/dmk/docs/data/COCMP/data_dir/HFR/radials';
conf.Radials.Sites = { 'MLNG', 'NPGS', 'PPIN', 'SCRZ' };
conf.Radials.Types = { 'RDLm', 'RDLi', 'RDLm', 'RDLi' };

conf.Radials.BearLims = [ 90,5,270; 60,5,155; 0,5,270; 180,5,360];
conf.Radials.RangeLims = zeros(4,0);
conf.Radials.RangeBearSlop = repmat( [0,2.4999], [4,1] );

mm = {'';'NPGS.mask';'PPIN.mask';''};
conf.Radials.MaskFiles = fullfile_multiple( demoDir, 'OtherDataFiles', ...
                                            mm );

% Totals
conf.Totals.BaseDir = '/home/dmk/docs/data/COCMP/data_dir/HFR/domains/MNTY/tuv';
conf.Totals.DomainName = 'MNTY';
conf.Totals.GridFile = fullfile(demoDir,'OtherDataFiles','cocmpMNTY.grid');
conf.Totals.cleanTotalsVarargin = { { 'GDOPMaxOrthog','TotalErrors',2 } };
conf.Totals.MaskFile = fullfile(demoDir,'OtherDataFiles', ...
                                'cocmpMNTY.mask');

% OMA
conf.OMA.BaseDir = '/home/dmk/docs/data/COCMP/data_dir/HFR/domains/MNTY/oma';
conf.OMA.ModesFileName = fullfile( demoDir, 'OtherDataFiles', 'modes.mat' );

% HourPlot Stuff
conf.HourPlot.BaseDir = '/home/dmk/docs/data/COCMP/data_dir/HFR/Plots/MNTY/Totals/';
conf.HourPlot.Type = 'Totals';
conf.HourPlot.VectorScale = 0.015;
conf.HourPlot.VelocityScaleLocation = [ -122.0172   37.0421 ];

% RadialPlot Stuff
conf.RadialPlot.BaseDir = '/home/dmk/docs/data/COCMP/data_dir/HFR/Plots/MNTY/Radials/';
conf.RadialPlot.Type = 'Totals';
conf.RadialPlot.RadialType = 'RTUV';
conf.RadialPlot.plotData_xargs = {'markersize',6};
conf.RadialPlot.ColorOrder = [1,0,0;0,1,0;0,0,1;0,0,0];

% Plot stuff
conf.Plot.plotBasemap_xargs = { 'patch', [0.5 0.9 0.5 ], 'edgecolor', 'k' };
conf.Plot.Speckle = true;

