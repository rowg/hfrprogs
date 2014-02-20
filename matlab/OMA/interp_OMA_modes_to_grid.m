function interp_OMA_modes_to_grid(gridLonLat,modes_fn,interp_fn)
% INTERP_OMA_MODES_TO_GRID  Interpolates a set of OMA modes to a set of
% totals grid points for later use in generating TUV data from OMA fits.
% 
% Usage: interp_OMA_modes_to_grid(LonLat,modes_filename,interp_filename)
%
% Inputs
% ------
% LonLat = a two column matrix of Lon,Lat coordinates of the points at
%          which to interpolate modes.
% modes_filename = name of file containing modes.  Typically created by
%                  generate_OMA_modes.
% interp_filename = name of file to save resulting interpolated modes.
%                   If empty or absent, it is assumed that you want to
%                   append the results of this function to the data in
%                   modes_filename.
%
% NOTE: This is basically a convenience function that wraps around
% pdeintrp_arbitrary.  See that functions for details of interpolation.
% Also note that interpolation is done in Lon,Lat space.  This should
% work fine for triangles that are sufficiently small, but could produce
% distortion for large triangles (i.e., triangles that are probably too
% large to do OMA on a flat earth in the first place).
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: interp_OMA_modes_to_grid.m 460 2007-07-20 19:24:22Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

m = load(modes_fn,'ux_tri','uy_tri','pLonLat','t');

% Do interpolation at grid points using currents previously determined on
% triangular grip
[ux_interp_grid,uy_interp_grid] = pdeintrp_arbitrary( [gridLonLat(:,1), ...
                    gridLonLat(:,2)], m.pLonLat, m.t, m.ux_tri, m.uy_tri );

% Save
if exist( 'interp_fn', 'var' ) & ~isempty( interp_fn )
  save(interp_fn,'ux_interp_grid','uy_interp_grid', 'gridLonLat' );
else
  save(modes_fn,'ux_interp_grid','uy_interp_grid', 'gridLonLat', '-APPEND' );
end

