function trajectories_animation(Lon,Lat,Times,lonlim,latlim,frameDir,tailLen,trajColor)
%TRAJECTORIES_ANIMATION  DON'T USE, WILL BE ADDED TO A FUTURE RELEASE.
error('THIS FILE IS OUT OF DATE!!!!!!');
% function trajectories_animation(Lon,Lat,Times,PlotDir,FrameDir,prefix)

%------------------------------------------------------------------------------------
%trajectories_animation will animate trajectories
%
%function trajectories_animation(Lon,Lat,Times,SaveDir,varargin)
%	for future revisions this function should support a host of varibale inputs that
%	control the finer points of the plotting and animation (color, time-delay, etc.
%	as well as making the "SaveDir" variable a varargin argument)
%
% $Id: trajectories_animation.m 396 2007-04-02 16:56:29Z mcook $
%
%------------------------------------------------------------------------------------

global RTplot

%PLOT FRAMES: <--THIS IS DEFINITELY NOT PERFECT YET AND NEEDS SOME WORK BUT I THINK
%ITS GOOD ENOUGH FOR NOW ... Primarly the problem appears to be with m_plot
%headSize = 30; % <----THIS SHOULD BE INCLUDED IN THE VARAGIN AS WELL AS THE RTPF
headSize = 22; % <----THIS SHOULD BE INCLUDED IN THE VARAGIN AS WELL AS THE RTPF

if ~exist('trajColor','var')
    trajColor = 'k';
end
if ~exist('tailLen','var')
    tailLen = 6;
end

% Determine if a region descriptor is to be added to the title.
if isfield(RTplot,'title')
    add2Title = [RTplot.title,' '];
else
    add2Title = '';
end

delete(gcf); 
% Set bathy contour to false
plinthos(lonlim,latlim,0);
% Try to make the frame size smaller
orient portrait
hold on;

% Initialize plot handles to avoid annoying error messages
h1 = [];  % Handle to active tail
h2 = [];  % Handle to Head
h3 = [];  % Handle to past tail (from start to end of active tail)
numFrames = size(Times(:),1);
for i = 1:numFrames
    fprintf('%s: Processing frame%02d\n',mfilename,i);
    % Get rid of the time(i-1) worms.
    delete(h1);
    delete(h2);
    delete(h3);
    % Length of data traversed so far is less then tail   
    if i == 1
        % Do nothing, just make the head, no tail
    elseif i > 1  &&  i <= tailLen
        % Make tail from start of data to now.
        h1 = m_line(Lon(1:i,:),Lat(1:i,:), ...
                   'lineStyle','-','linewidth',2,'color',trajColor);
    else
        % Make the past tail.  Add 1 to prevent the situation where Lon(1:1,:) &
        % Lat(1:1,:), and all starting positions are connected.  Just draw
        % first, and the last 
        h3 = m_line(Lon(1:i-tailLen+1,:),Lat(1:i-tailLen+1,:), ...
                    'lineStyle','-','linewidth',2,'color',[0.7,0.7,0.7]);
        % Make the tail from now to tailLen dt's ago.
        h1 = m_line(Lon(i-tailLen:i,:),Lat(i-tailLen:i,:), ...
                    'lineStyle','-','linewidth',2,'color',trajColor);
    end
    
    % Make the head
    h2 = m_line(Lon(i,:),Lat(i,:),'lineStyle','none','Color','r', ...
                'marker','.','markerSize',headSize);

    % Title in all its splendor.
    title( {sprintf('%s Particle Trajectories From',add2Title), ...
            sprintf('OMA Derived Currents at %s GMT', ...
            datestr(Times(i),'dd-mmm-yyyy HH:MM')) }, ...
            'FontSize',14,'FontWeight','bold');

    print('-dpng',fullfile(frameDir,sprintf('frame%02d',i)));
end

% Add code repeat the ending frame a set number of times.
% Determine last actual frame number and add to it.
cnt = i;
numRepeatLastFrame = 8;
for j = 1:numRepeatLastFrame
    cnt = cnt + 1;
    print('-dpng',fullfile(frameDir,sprintf('frame%02d',cnt)));
end


hold off;
    
