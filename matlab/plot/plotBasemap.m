function plotBasemap(lon,lat,fname,proj,varargin)
%PLOTBASEMAP  plot a basemap with a coastline using the m_map toolbox.
%
% Usage:
%        plotBasemap(lon, lat, fname, proj, ...)
%
% Inputs:
%     lon   - [min Lon,  max Lon] of area to plot.
%     lat   - [min Lat,  max Lat] of area to plot.
%     fname - name of coastline mat file created using makeCoast.m, ''
%             or not supplied.  If '' or not supplied, will call 
%             makeCoast and create coastline and save using default file 
%             name.  See makeCoast for default file naming convention.
%             If a filename is given, but the file does not exist,
%             makeCoast will be used to create that file.
%     proj  - projection to use.  See m_map help for list of projections. 
%             DEFAULT = 'lambert' if proj is an empty string or not 
%             supplied.
%     ...   - are arguments supplied to m_usercoast, the underlying 
%             function in basemap that draws the coastline.  See help on
%             m_map and m_usercoast.  But for example, these might be:
%             'speckle','color','k', or 'patch',[.5,.5,.5].  
%
% This function requires the m_map toolbox.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: plotBasemap.m 426 2007-05-19 23:02:17Z dmk $	
%
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('proj','var') || isempty(proj)
    proj = 'lambert';
end

% Create coastline file
if ~exist('fname','var') || isempty(fname)
    fprintf('Creating coastine data by calling makeCoast ... this may take a few minutes\n')
    fname = makeCoast(lon,lat,proj);
    fprintf('%s saving coastline as %s\n',mfilename,fname);
elseif ~exist(fname,'file') && ~exist([fname '.mat'],'file') % check both
    fprintf('Creating coastine data by calling makeCoast ... this may take a few minutes\n')
    fname = makeCoast(lon,lat,proj,fname);
    fprintf('%s saving coastline as %s\n',mfilename,fname);
end

% Check for mapping toolbox functions
if ~exist('m_proj','file') || ~exist('m_grid','file')
    error('m_map toolbox either not installed or not on matlab path')
else
    m_proj(proj,'long',lon,'lat',lat);
    m_grid('linewidth',1,'linestyle','--','tickdir','out','fontsize',12);
end

feval('m_usercoast',fname,varargin{:});
