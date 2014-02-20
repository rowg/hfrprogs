function HFRPdriver_Totals_OMA( D, p, varargin )
% HFRPDRIVER_TOTALS_OMA - This is an example driver function that
% automates generating totals and doing OMA analysis from radials data
%
% Usage: HFRPdriver_Totals_OMA( TimeStamp, conf, PARAM1, VAL1, ... )
%
% Inputs
% ------
% TimeStamp = Timestamp to work on in datenum format.
% conf = a structure with configuration parameters, can be empty
% PARAMn,VALn = name,value pairs that can override configuration parameters.
%
% Outputs
% -------
% There are no outputs.  All results are stored in mat-files that are in
% directories specified in the configuration parameters below.
%
% Configuration Parameters
% ------------------------
% conf.MonthFlag = whether or not to include month directory in file
%                  paths. Defaults to true.
%
% conf.Radials.BaseDir = base directory.  Defaults to '.'
% conf.Radials.Sites = cellstr of site names.  Must match site names in
%                     RDL files.
% conf.Radials.Types = cellstr of file types, typically 'RDLi' or 'RDLm'.
% conf.Radials.FilePrefix = prefix of filenames for each site+type.
%                          Defaults to [ Types '_' Sites '_' ]
% conf.Radials.FileSuffix = Suffix for each site+type or a single suffix
%                          for all.  Defaults to '.ruv'
% conf.Radials.RangeLims = a Nx3 matrix where N is the number of sites with
%                          range limits for radial interpolation. See
%                          interpRadials for details.
% conf.Radials.BearLims = a Nx3 matrix where N is the number of sites with
%                         bearing limits for radial interpolation. See
%                         interpRadials for details.
% conf.Radials.RangeGap = max range gap in km for radial interpolation.
%                        See interpRadials for details.  Defaults to 2.5.
% conf.Radials.BearGap = max angle gap in array units for radial
%                        interpolation.  See interpRadials for details.
%                        Defaults to 3.5.
% conf.Radials.RangeBearSlop = slops for interpolation, Nx2 matrix where N
%                              is the number of sites.  See interpRadials
%                              for details.  Defaults to 1e-10.
% conf.Radials.MaxRadSpeed = max radial speed for cleanRadials.  Defaults
%                           to 100.
% conf.Radials.MaskFiles = cellstr of mask files for each site+type.
%                         Radials inside each mask will be kept.
%                         Defaults to ''.
%
% conf.Totals.BaseDir = Defaults to '.'
% conf.Totals.DomainName = name of totals domain
% conf.Totals.FilePrefix = Defaults to [ 'tuv_' DomainName '_' ]
% conf.Totals.FileSuffix = Defaults to '.mat'.
% conf.Totals.GridFile = string filename with totals grid to use or a 2
%                        column matrix of LonLat coordinates.
% conf.Totals.MinNumSites = minimum number of sites for generating a
%                           total.  Defaults to 2.
% conf.Totals.MinNumRads = minimum number of radials for generating a
%                          total.  Defaults to 3.
% conf.Totals.spatthresh = spatial window around each totals grid point.
%                          See makeTotals for details.  Defaults to 3.
% conf.Totals.tempthresh = temporal window around each timestep.  See
%                          makeTotals for details.  Defaults to 1/24/2-eps.
% conf.Totals.MaxTotSpeed = maximum totals speed for cleanTotals.
%                           Defaults to 100.
% conf.Totals.cleanTotalsVarargin = Other arguments for cleanTotals.  See
%                                   cleanTotals for details.  Defaults to
%                                   {}.
% conf.Totals.MaskFile = mask file name for totals or a 2 column matrix
%                        of coordinates.  Totals outside mask will be
%                        kept.  Defaults to ''.
%
% conf.OMA.BaseDir = Defaults to '.'
% conf.OMA.DomainName = Defaults to Totals.DomainName.
% conf.OMA.FilePrefix = Defaults to [ 'oma_' DomainName '_' ]
% conf.OMA.FileSuffix = Defaults to '.mat'
% conf.OMA.ModesFileName = Full path of file with modes information.
%                          Defaults to 'modes.mat'.  Set to '' to not do
%                          OMA fits.
% conf.OMA.InterpFileName = Mode interpolation file.  Defaults to
%                           ModesFileName.
% conf.OMA.tempthresh = Defaults to conf.Totals.tempthresh.
% conf.OMA.K = Homogenization smoothing term.  Defaults to 1e-3.
% conf.OMA.ErrorType = See fit_OMA_modes_to_radials for details.
%                      Defaults to 'constant'.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: HFRPdriver_Totals_OMA.m 520 2007-12-11 10:31:24Z dmk $	
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
mand_params = { 'Radials.Sites', 'Radials.Types', 'Radials.RangeLims', ...
                'Radials.BearLims', 'Totals.DomainName', 'Totals.GridFile', };
p = checkParamValInputArgs( p, {}, mand_params, varargin{:} );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix default inputs that can only be done afterwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try, p.Radials.FilePrefix;
catch
  p.Radials.FilePrefix = strcat( p.Radials.Types, '_', p.Radials.Sites, '_' ...
                                );
end

try, p.Radials.RangeBearSlop;
catch
  p.Radials.RangeBearSlop = repmat( 1e-10, [ numel(p.Radials.Sites), 2 ] );
end

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

try, p.OMA.tempthresh;
catch
  p.OMA.tempthresh = p.Totals.tempthresh;
end

try, p.OMA.InterpFileName;
catch
  p.OMA.InterpFileName = p.OMA.ModesFileName;
end

% Size up FileSuffix if needed.
p.Radials.FileSuffix = repmat( cellstr( p.Radials.FileSuffix ), ...
                               size(p.Radials.FilePrefix)./ ...
                               size(p.Radials.FileSuffix) );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get filenames together
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F = filenames_standard_filesystem( p.Radials.BaseDir, p.Radials.Sites(:), ...
                                   p.Radials.Types(:), D, p.MonthFlag);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Radials work - load in all at once, masking, cleaning interpolation
%
% When loading, for each time, load all radials from all sites in an
% element of a single cell array - this will be useful for later saving
% radials from each time with the appropriate totals files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Processing radials.');
Rorig = loadRDLFile(F);

% Deal with possible missing files
sn = { Rorig.SiteName };
ii = strmatch( '', sn, 'exact' );
missingRadials.FileNames = [ Rorig(ii).FileName ];
[missingRadials.TimeStamps,missingRadials.Sites,missingRadials.Types] ...
    = parseRDLFileName( missingRadials.FileNames );
Rorig(ii) = [];

if isempty(Rorig)
  error( 'No data at this timestep.' );
end

% Get rid of stuff for missing files
try, p.Radials.MaskFiles(ii) = []; end
p.Radials.RangeLims(ii,:) = [];
p.Radials.BearLims(ii,:) = [];
p.Radials.RangeBearSlop(ii,:) = [];

% Do radial cleaning
Rclean = cleanRadials( Rorig, p.Radials.MaxRadSpeed );

% Do masking
Rmask = maskRadials( Rclean, p.Radials.MaskFiles, true );

% Interpolation
clear Rinterp
for n = 1:numel(Rmask)
  Rinterp(n) = interpRadials( Rmask(n), 'RangeLims', p.Radials.RangeLims(n,:), ...
                              'BearLims', p.Radials.BearLims(n,:), ...
                              'RangeDelta', p.Radials.RangeBearSlop(n,1), ...
                              'BearDelta', p.Radials.RangeBearSlop(n,2), ...
                              'MaxRangeGap', p.Radials.RangeGap, ...
                              'MaxBearGap', p.Radials.BearGap, ...
                              'CombineMethod', 'average' );
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate totals from radials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[grid,fn,c] = loadDataFileWithChecks( p.Totals.GridFile );
if c >= 100
  error( 'Could not find totals grid.' );
end

disp('Generating totals');

% Make totals
[TUVorig,RTUV]=makeTotals(Rinterp,'Grid',grid,'TimeStamp',D, ...
                      'spatthresh',p.Totals.spatthresh, ...
                      'tempthresh',p.Totals.tempthresh, ...
                      'DomainName',p.Totals.DomainName );

% Clean totals
[TUVclean,I] = cleanTotals( TUVorig, p.Totals.MaxTotSpeed, ...
                            p.Totals.cleanTotalsVarargin{:} );
fprintf('%d totals removed by cleanTotals\n',sum(I(:)>0))

% Mask totals
[TUV,I]=maskTotals(TUVclean,p.Totals.MaskFile,false);
fprintf('%d totals masked out\n',sum(~I(:)))

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[tdn,tfn] = datenum_to_directory_filename( p.Totals.BaseDir, D, ...
                                           p.Totals.FilePrefix, ...
                                           p.Totals.FileSuffix, p.MonthFlag );
tdn = tdn{1};

if ~exist( tdn, 'dir' )
  mkdir(tdn);
end

save(fullfile(tdn,tfn{1}),'Rorig','missingRadials','p','RTUV','TUVorig','TUV' )

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do OMA fits to radials!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check for modes file.  Don't fail
if ~exist( p.OMA.ModesFileName, 'file' ) || ...
      ~exist( p.OMA.InterpFileName, 'file' )
  disp( 'OMA modes or interp file missing. Skipping' );
  return
end

% Standard name
RTUV = Rmask; % Use masked, not interpolated, radials for OMA.

disp('Doing OMA fits');
TUV = fit_OMA_modes_to_radials( RTUV, 'modes_filename', p.OMA.ModesFileName, ...
                                'interp_filename', p.OMA.InterpFileName, ...
                                'K', p.OMA.K, 'TimeStamp', D, 'tempthresh', ...
                                p.OMA.tempthresh, 'error_type', p.OMA.ErrorType ...
                                );
TUV.DomainName = p.OMA.DomainName;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[odn,ofn] = datenum_to_directory_filename( p.OMA.BaseDir, D, p.OMA.FilePrefix, ...
                                           p.OMA.FileSuffix, p.MonthFlag );
odn = odn{1};

if ~exist( odn, 'dir' )
  mkdir(odn);
end

save(fullfile(odn,ofn{1}),'Rorig','missingRadials','p','RTUV','TUV')
