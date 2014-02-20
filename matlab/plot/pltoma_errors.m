function [lonlim,latlim] = pltoma_errors(Speederr,NMA,RADIAL,lonlim,latlim,clrRange,numClrs)
%PLTOMA_ERRORS  DON'T USE, WILL BE ADDED TO A FUTURE RELEASE.
error('THIS FILE IS OUT OF DATE!!!!!!');
% USAGE:
%   [lonlim,latlim] = pltdata(Type,NMA,RADIAL,lonlim,latlim,clrRange,numClrs)
%
% INPUTS:
%   Speederr - error measurments.  Assume this is a scalar and it will be
%              color contoured.
%   NMA    See below for field names and dimensions.  Must be supplied.
%          Data has been loaded already, this is NMA struct. 
%             This is the current NMA struct format and field names.
%             NMA = 
%                           weU: []
%                           weV: []
%                     TimeStamp: 7.3288e+05
%                         alpha: [43x1 double]
%                     cov_alpha: [43x43 double]
%                          Uerr: [690x1 double]
%                          Verr: [690x1 double]
%                  UVcovariance: [690x1 double]
%                             U: [690x1 double]
%                             V: [690x1 double]
%                 U_data_points: [1761x1 double]
%                 V_data_points: [1761x1 double]
%                           Lon: [690x1 double]
%                           Lat: [690x1 double]
%                    griddedLon: [30x23 double]
%                    griddedLat: [30x23 double]
%   RADIAL The struct containing information on all radial sites used to
%          create the total surface currents.  Used to place a marker on 
%          the plot at each radial site location.  If not supplied or 
%          empty, [ ], then no radial site locations plotted.
%   lonlim & latlim - the [min,max] limits for longitude and latitude.
%          Optional, but supply either none or both.
% clrRange A 2 element vector specifying the data range to color.  All data
%          outside this range will be color saturated.  If not supplied,
%          clrRange defaults to the [min, max] of current data speed.
% numClrs  Number of different colors to distinguish different speeds.
%          Defaults to 64.  Not implimented yet.  Hope to match colorbar
%          labels to number of colors.
%
% OUTPUTS:
%   lonlim/latlim - this program determines the "best limits" of the data.  Pass
%   back to calling program so these limits can be used by other plotting
%   programs.  
%


% Plot a variety of data types using the same plot call.  Hopefully this
% will replace plttuv, pltnma, pltoma and combine.  -MC
% Mike Cook - NPS Dept. of Oceanography,  June 2006.
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: pltoma_errors.m 396 2007-04-02 16:56:29Z mcook $
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% This is needed in check for nma decimation parameter.
global RTplot

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% CLOSE ALL OPEN FIGURE WINDOWS
close all
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% DEFINE THE VARIABLES.
Lon  = NMA.Lon(:);
Lat  = NMA.Lat(:);
% Uerr = NMA.Uerr(:);
% Verr = NMA.Verr(:);
% Speederr = sqrt(Uerr .^2 + Verr .^2);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% SET UP DEFAULT VALUES
if ~exist('numClrs','var')
    numClrs = 64;  % Matlab's default for colormaps.
end

%DEFINE LIMITS
if ~exist('latlim','var')  ||  isempty(latlim)
   latlim = [min(Lat(:))-0.01,max(Lat(:))+0.01];
end
if ~exist('lonlim','var')  ||  isempty(lonlim)
   lonlim = [min(Lon(:))-0.01,max(Lon(:))+0.01];
end

% Determine if a region descriptor is to be added to the title.
if isfield(RTplot,'title')
    add2Title = [RTplot.title,' '];
else
    add2Title = '';
end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%CALL BASEMAP - hold on is set in plinthos
ax1 = plinthos(lonlim,latlim,0);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% PLOT LOCATION OF EACH RADIAL SITE USED IN CREATING TUV
if exist('RADIAL','var')  &  ~isempty(RADIAL)
    for k = 1:length(RADIAL)
        if ~isempty(RADIAL(k).Origin)
            m_text(RADIAL(k).Origin(1),RADIAL(k).Origin(2),'*', ...
                'fontsize',24,'fontweight','bold','color','r');
        end
    end
end


% Make a speed contour no matter what else is input
[Y,X] = size(NMA.griddedLon);
SPEEDERR = reshape(Speederr,Y,X);

%     [C,h2] = m_contour(NMA.griddedLon,NMA.griddedLat,SPEEDERR,'color',[.5 .5 .5]); 
% Get a set of nice contour intervals
CLevels = makeContourLevels([min(Speederr(:)),max(Speederr(:))],12,[0.5,1,2,5,10]);
[C,h2] = m_contourf(NMA.griddedLon,NMA.griddedLat,SPEEDERR,CLevels); 
clabel(C,h2,'LabelSpacing',72*4,'Rotation',0,'fontsize',12,'fontweight','bold','color','k');
%  See if can label every other contour. 
% THIS CURRENTLY DOESN'T WORK.
% set(h2,'ShowText','on','TextStep',get(h2,'LevelStep')*2,'Rotation',0, ...
%       'fontsize',12,'fontweight','bold','color','k');

titleStr = { sprintf('%s OMA DERIVED',add2Title),...
             sprintf('OCEAN SURFACE CURRENT ERROR ESTIMATES'),...
             sprintf('MEASUREMENT TIME: %s GMT', ...
             datestr(NMA.TimeStamp,'dd-mmm-yyyy HH:MM')) };

% Check for data range to color.  If not supplied, use the min/max of the
% data.
if exist('clrRange','var')
    caxis([clrRange(1), clrRange(2)])
else
    caxis([min(Speederr),max(Speederr)])
end

title(titleStr,'FontSize',16,'FontWeight','bold');
ax2 = colorbar('Location','eastoutside', ...
     'fontsize',16,'fontweight','bold');
xlabel(ax2,'     cm/s','fontsize',14,'fontweight','bold');
ylabel(ax2,'NOTE: Data outside color range will be saturated', ...
      'fontsize',16,'fontweight','bold');
