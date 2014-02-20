function fname = makeCoast(lon,lat,proj,fname,res)
%MAKECOAST  create coastline data file using m_map toolbox.
%
% makeCoast creates a coastline mat file from the GSHHS coastline database
% that contains the data necessary to plot a coastline on a figure created 
% using the m_map toolbox.
%
% Extracting the coastline from the GSHHS every time you want to put a
% coastline on a map can take a very, very long time since the entire
% database must be searched and the revelant coast section extracted.  This
% function allows you to save the portion of interest to a mat file,
% thereby speeding up the plotting process when you are drawing the same
% section of coast onto a basemap over and over.
%
% This function requires the m_map toolbox and the GSHHS coastline
% database.
%
% Usage:
%        fname = makeCoast(lon,lat,proj,fname,res)
%
% Inputs:
%   lon   - [min lon, max lon]
%   lat   - [min lat, max lat]
%   proj  - projection to use.  See m_map help for list. 
%           DEFAULT = 'lambert' if proj is an empty string or not supplied.
%   fname - path and name of mat file to save coast data.  
%           DEFAULT is COASTres_minLon_minLat.mat, where res is an integer 
%           specifying the resolution (see below), minLon and minLat are
%           the abs(lon(1)) and abs(lat(1)), and the file is saved in the
%           current directory.
%   res   - coastline quality. res can be a number from 1-5, defined as:
%                1  = 'crude'
%                2  = 'low'
%                3  = 'intermediate'  
%                4  = 'high'
%                5  = 'full'
%           DEFAULTS to 4, or 'high' resolution.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: makeCoast.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('proj','var') || isempty(proj)
    proj = 'lambert';
end

if ~exist('res','var')
    res = 4;
end

if ~exist('fname','var') || isempty(fname)
    fname = fullfile(pwd,sprintf('COAST%d_%g_%g.mat',res,abs(lon(1)),abs(lat(1))));
end

if ~exist('m_proj','file')
    error('m_map toolbox either not installed or not on matlab path')
end

m_proj(proj,'long',lon,'lat',lat);
m_gshhs(res,'save',fname);
