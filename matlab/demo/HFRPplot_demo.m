%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script takes the output of the HFRPdemo and does some sample plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('TUVbest','var')
  error( 'Need to run HFRPdemo first' );
end

thisDir = fileparts( mfilename('fullpath') );

scale = 0.015;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Artificially long particle tracks.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
U = repmat( reshape( TUVbest.U(:,1), gridDim ), [1,1,2] );
V = repmat( reshape( TUVbest.V(:,1), gridDim ), [1,1,2] );
Lon = reshape( TUVbest.LonLat(:,1), gridDim );
Lat = reshape( TUVbest.LonLat(:,2), gridDim );

% Note false times
TRAJ2 = ptrack2TRAJstruct('particle_track_ode_grid_LonLat',Lon,Lat,U,V, ...
                         [0,5], [0,5], LL, options );

TRAJ2.TrajectoryDomain = TUVbest.DomainName;
TRAJ2.OtherMetadata.ptrack2TRAJstruct.options = options;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up basemap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
plotBasemap( LonLims + [-0.2,0.2] * diff(LonLims), ...
             LatLims + [-0.2,0.2] * diff(LatLims), ...
             fullfile(thisDir,'OtherDataFiles','MNTYcoast'), ...
             'lambert', 'patch', [0.5 0.5 0.5] );
hold on

th = title( 'Select location of distance bar', 'fontsize', 16 );

[dh,dth,dl] = m_distance_bar( 10 );
set(dh,'linewidth',2)
set(dth,'fontsize',14)

ppp = get(dth,'position');
ppp(3) = 1000;
set(dth,'position',ppp)

% Add locations of radial sites
so = vertcat(Rcat.SiteOrigin);
rsh = m_plot( so(:,1), so(:,2), '^k', 'markersize', 10, 'linewidth', 3 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do plot of some regular vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ph1 = plotData( TUVmask, 'm_vec', 1, scale );

th = title( { [ 'Total Currents for ' datestr(TUVmask.TimeStamp(1)) ], ...
              'Click to overlay Interpolated Currents' }, 'fontsize', 16 );

ii=waitforbuttonpress;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overlay interpolated vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ph2 = plotData( TUVbest, 'm_vec', 1, scale, 'facecolor', 'k' );

th = title( { 'Total Currents (color), Interpolated Currents (black) ', ...
              'Click to overlay OMA currents' }, 'fontsize', 16 );

ii=waitforbuttonpress;

delete(ph2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overlay OMA vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('TUVoma','var')
  ph2 = plotData( TUVoma, 'm_vec', 1, scale, 'facecolor', 'k' );
  
  th = title( { 'Total Currents (color), OMA Currents (black) ', ...
                'Click to see Particle Tracks' }, 'fontsize', 16 );
  
  ii=waitforbuttonpress;
  
  delete(ph2)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot particle tracks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set(ph1,'facecolor','k')

ph2 = m_plot( TRAJ2.Lon', TRAJ2.Lat', 'linewidth', 4, 'color', 'k' );

th = title( { 'Total Currents (color), Particle tracks (black) ', ...
              'Click to see Particle Tracks' }, 'fontsize', 16 );

ii=waitforbuttonpress;

