%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function does some simple tests of the HFR_Progs basic
% functionality using some radial currents data from Monterey Bay.  The
% major functions tested are:
%
% loadRDLFile, cleanRadials, maskRadials, interpRadials, makeTotals,
% cleanTotals, maskTotals, temporalInterpTotals, spatialInterpTotals,
% gridTotals, particle_track_ode_grid_LonLat, fit_OMA_modes_to_radials,
% generate_trajectories_from_OMA_fit, nanmeanTotals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: HFRPdemo.m 444 2007-07-05 19:27:48Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

thisDir = fileparts( mfilename('fullpath') );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic info with locations of radial files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
baseDir = fullfile( thisDir, 'RadialFiles' );

% Must be row vector
d = datenum(2007,02,[14,14,15],[22,23,00],00,00);

% Must be column vector
prefix = { 'RDLm_PPIN_'; 'RDLm_MLML_'; 'RDLm_NPGS_'; 'RDLi_SCRZ_' };

suffix = '.ruv';
monthFlag = false;

% Generate all filenames at once using repmat appropriately
fnames = datenum_to_directory_filename(baseDir,repmat(d,size(prefix)), ...
                                       repmat(prefix,size(d)),suffix,monthFlag); 

% Special form of filenames that is useful for plot titles
titFnames=strrep(fnames,'_','\_');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load, time concat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Loading:\n'); fprintf('%s\n',fnames{:});
Rorig = loadRDLFile(fnames);

% Temporal concatenation
Rcat = temporalConcatRadials( Rorig, 0.001, 0.49, 0.49, 0.5 );

% Deal with possible missing files
if isempty(Rcat(1).SiteName)
  missingRadials.FileNames = Rcat(1).FileName;
  [missingRadials.TimeStamps,missingRadials.Sites,missingRadials.Types] ...
      = parseRDLFileName( missingRadials.FileNames );
  
  Rcat = Rcat(2:end); % Strip off empties
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean, mask and interpolate radials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROBLEM: We can no longer be certain of ordering of radials after
% temporalConcatRadials because (a) it sorts the names with unique and
% (b) if there are empties then this may disorder the list of sites (a
% more fundamental problem).
% SOLUTION: Use on-the-fly structure indexing to pick out correct
% cutoffs, masks, etc.  The advantage of this is that it is very explicit
% which parameters go with which sites.  The disadvantage is that you
% have to do each site separately.

% For cleaning
[cutOff.PPIN,cutOff.MLML,cutOff.NPGS,cutOff.SCRZ] = deal(100, 100, 125, 100);

% For masking
mm = {'PPIN.mask';'';'NPGS.mask';''};
mm = fullfile_multiple( thisDir, 'OtherDataFiles', mm );
[maskFiles.PPIN,maskFiles.MLML,maskFiles.NPGS,maskFiles.SCRZ] = deal(mm{:});

% For interpolation
angLims.PPIN = [0,5,270]; 
angLims.MLML = [90,5,270]; 
angLims.NPGS = [60,5,155]; 
angLims.SCRZ = [180,5,360];

[SiteCode.PPIN,SiteCode.MLML,SiteCode.NPGS,SiteCode.SCRZ] = deal(1,2,4,8);

for k = 1:numel(Rcat)
  sn = Rcat(k).SiteName;

  % Fix sitecode
  Rcat(k).SiteCode = SiteCode.(sn); 
  
  % Clean large radials
  [Rclean(k),I{k}]=cleanRadials(Rcat(k),cutOff.(sn));
  
  % Masking is a destructive process, any radials outside the mask will be
  % completely removed from R, the position and the values.
  [Rmask(k),II{k}]=maskRadials(Rclean(k),maskFiles.(sn));

  % Need to specify angle limits and angle steps for each site for
  % interpolation.
  fprintf('Interpolating %s\n',Rmask(k).FileName{:})
  [Rinterp(k),iRange{k},iBear{k}] = interpRadials(Rmask(k),'BearLims', ...
                                                  angLims.(sn), ...
                                                  'BearDelta',2.4999, ...
                                                  'MaxBearGap',3.5, ...
                                                  'MaxRangeGap',2.5);
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make, clean and mask totals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grid = load(fullfile('OtherDataFiles','cocmpMNTY.grid'));
fprintf('Making totals\n');
[TUV,RTUV]=makeTotals(Rinterp,'Grid',grid,'TimeStamp',d, 'spatthresh',3, ...
                      'tempthresh',0.5/24, 'CreationInfo', ...
                      'Mike Cook - NPS', 'DomainName','MNTY', 'WhichErrors', ...
                      {'GDOPMaxOrthog','GDOP','FitDif','GDOPSites'} );

[TUVclean,TI] = cleanTotals(TUV,100);
fprintf('%d totals > 100 cm/s removed\n',sum(TI(:)>0))

[TUVmask,TII]=maskTotals(TUVclean,fullfile('OtherDataFiles','cocmpMNTY.mask'),false);
fprintf('%d totals masked out\n',sum(~TII(:)))

% Put things on a grid
[TUVgrid,gridDim] = gridTotals( TUVmask );

% How about spatial and temporal interpolation
TUVspat = spatialInterpTotals( TUVgrid );
TUVtemp = temporalInterpTotals( TUVgrid );

% Mean of spatial and temporal interpolation
s = size(TUVspat.U);
U = reshape( nanmean( [TUVspat.U(:), TUVtemp.U(:)], 2 ), s );
V = reshape( nanmean( [TUVspat.V(:), TUVtemp.V(:)], 2 ), s );

TUVbest = TUVspat;
TUVbest.U = U;
TUVbest.V = V;
TUVbest.ProcessingSteps{end+1} = 'meanSpatTempInterp';

% How about the average currents over period
TUVmean = nanmeanTotals( TUVbest );

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do some particle tracking on the grid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( 'Doing some particle tracking on a rectangular Lon,Lat grid.' );

U = reshape( TUVbest.U, [ gridDim, s(2) ] );
V = reshape( TUVbest.V, [ gridDim, s(2) ] );
Lon = reshape( TUVbest.LonLat(:,1), gridDim );
Lat = reshape( TUVbest.LonLat(:,2), gridDim );

ln = Lon(1:5:end,1:5:end);
lt = Lat(1:5:end,1:5:end);

LL = [ ln(:), lt(:) ];

% Get some good option values for tracking - otherwise output is junk.
abs_tol = 1.0e-3; % Not sure about this
rel_tol = 1.0e-3; % Not sure about this
maxstep = 1/24/4; % 1/4 hour  
options = odeset('RelTol',rel_tol,'AbsTol',abs_tol,'MaxStep',maxstep);

% This calculates trajectories and puts in a TRAJ structure with some
% extra metadata (but not much).
TRAJ = ptrack2TRAJstruct('particle_track_ode_grid_LonLat',Lon,Lat,U,V, ...
                         TUVbest.TimeStamp, TUVbest.TimeStamp([1,end]), ...
                         LL, options );
TRAJ.TrajectoryDomain = TUVbest.DomainName;
TRAJ.OtherMetadata.ptrack2TRAJstruct.options = options;

% Useful for plotting
LonLims = [ min(Lon(1,:)), max(Lon(1,:)) ];
LatLims = [ min(Lat(:,1)), max(Lat(:,1)) ];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open-Boundary Modal Analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In a real situation, mode generation would only be done once before any
% fitting of data and saved to a standard location for repeated
% reference.  In this case, mode generation is quick enough that it can
% be done here.

mode_min_scale = 10; % 10 km
modes_fn = fullfile( thisDir, 'OtherDataFiles', 'modes.mat' );

% This border was previously created by taking a California coastline,
% cutting a piece out, then interpolating that piece so that no edge
% segment is short than about 0.3 km and then adding to the resulting
% smoothed coastline the open boundary part of the boundary.
border = load( fullfile( thisDir, 'OtherDataFiles', 'OMA_boundary.txt' ) );

% These would typically be initially determined by running
% generate_OMA_modes with the keyboard input argument set to true and
% examining the numbers assigned to the edges of the domain by PDETOOL in
% Boundary Mode with "Show Edge Labels".
ob_nums = { 310:312 };
db_nums = { 145 };

% Only generate modes if they are not already present and toolbox exists
if ~exist(modes_fn,'file') && exist( 'pdetool', 'file' )
  % Need to set a m_map projection before running generate_OMA_modes.  This
  % projection must include inside it the entire area of the OMA boundary.
  m_proj('mercator','lon',LonLims + [-0.2,0.2] * diff(LonLims), ...
         'lat',LatLims + [-0.2,0.2] * diff(LatLims));

  % Generate modes
  generate_OMA_modes( modes_fn, border, mode_min_scale, ob_nums, db_nums, ...
                      [], [], false );
  
  % Interpolate modes at useful grid points.
  interp_OMA_modes_to_grid( TUVgrid.LonLat, modes_fn, [] );
end

% End if no modes file was generated or is already present.
if ~exist( modes_fn, 'file' )
  disp( 'Modes file not present.  Skipping OMA demos.' );
  return
end

% Fit radial data to modes - use masked instead of interpolated radial
% data because there is not reason with OMA to interpolate radials as OMA
% does the interpolation for you.  Interpolation will also overestimate
% the true number of radial measurements, thereby artificially reducing
% error estimates.
TUVoma = fit_OMA_modes_to_radials( Rmask, 'modes_filename', modes_fn, 'K', ...
                                   1e-4, 'TimeStamp', TUV.TimeStamp, ...
                                   'tempthresh', 1/24/2, 'error_type', ...
                                   'constant' );
TUVoma.DomainName = TUV.DomainName;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do some particle tracking on triangular OMA domain.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TRAJoma = generate_trajectories_from_OMA_fit( TUVoma, modes_fn, ...
                                              TUVbest.TimeStamp([1,end]), ...
                                              LL, options );
