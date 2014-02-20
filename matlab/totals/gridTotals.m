function [TT,DIM,III] = gridTotals( T, E, O )
% GRIDTOTALS  Place total current data on a regular grid 
% using meshgrid_vector_data on TUV.LonLat.
%
% This function basically assumes that the totals data lies on a regular,
% but incomplete, Lon,Lat grid and then uses meshgrid_vector_data to
% complete that grid.
%
% Usage: [TUVgrid,DIM,I] = gridTotals( TUV, grid_errors, grid_others )
%
% Inputs
% ------
% TUV = Input TUV structure on an irregular grid
% grid_errors = boolean indicating whether or not to attempt gridding of
%               ErrorEstimates. Defaults to True.
% grid_others = boolean indicating whether or not to attempt gridding of
%               variables in OtherMatrixVars and OtherSpatialVars.  Defaults
%               to True.
%
% Outputs
% -------
% TUVgrid = TUV structure on a rectangular grid.
% DIM = dimension of that TUV structure.  Also recorded in
%       TUVgrid.OtherMetadata.gridTotals.DIM.
% I = index indicating where original grid points ended up in rectangular grid
%
% To get back grid from resulting TUVgrid and DIM, one would do:
%
%    Lon = reshape( TUVgrid.LonLat(:,1), DIM);
%    Lat = reshape( TUVgrid.LonLat(:,2), DIM );
%    U = reshape( TUVgrid.U, [ DIM, size(TUVgrid.U,2) ] );
%
% U will be a 3D matrix with dimensions [ Lat, Lon, Time ] (note that the
% order is Lat then Lon because of the way meshgrid works).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: gridTotals.m 583 2008-01-26 00:24:27Z cook $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'E', 'var' ), E = true; end
if ~exist( 'O', 'var' ), O = true; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get dimensionality of grid and indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Lon,Lat,III] = meshgrid_vector_data( T.LonLat(:,1), T.LonLat(:,2) );

II = III( isfinite(III) );
I = isfinite(III); % This matrix index works even if the object is reshaped
                   % to be a column vector or set of column vectors.

DIM = size(Lon);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create new TUV structure and begin filling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TT = subsrefTUV( T, ones(numel(Lon),1), ':', E, O );

% Add processing steps
TT.ProcessingSteps{end+1} = mfilename;

% Add dimensionality info
TT.OtherMetadata.(mfilename).DIM = DIM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copy gridded info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TT.LonLat = [ Lon(:), Lat(:) ];

TT.U( I, : ) = T.U( II, : );
TT.U( ~I, : ) = NaN;

TT.V( I, : ) = T.V( II, : );
TT.V( ~I, : ) = NaN;

TT.Depth( I ) = T.Depth( II );
TT.Depth( ~I, : ) = NaN;

% Do errors
if E
  for k = 1:numel(T.ErrorEstimates)

    % Regular variables
    for f = {'Uerr','Verr','UVCovariance','TotalErrors'}
      f = f{:};
      if ~isempty(T.ErrorEstimates(k).(f))
        TT.ErrorEstimates(k).(f)(I,:) = T.ErrorEstimates(k).(f)(II,:);
        TT.ErrorEstimates(k).(f)(~I,:) = NaN;
      end
    end
    
    % Extra variables
    if ~isempty( T.ErrorEstimates(k).OtherMatrixVars )
      for f = fieldnames( T.ErrorEstimates(k).OtherMatrixVars )'
        f = f{:};
        TT.ErrorEstimates(k).OtherMatrixVars.(f)(I,:) = ...
            T.ErrorEstimates(k).OtherMatrixVars.(f)(II,:);
        TT.ErrorEstimates(k).OtherMatrixVars.(f)(~I,:) = NaN;
      end
    end

  end
end

% Do Others
if O
  if ~isempty( T.OtherMatrixVars )
    for f = fieldnames( T.OtherMatrixVars )'
      f = f{:};
      TT.OtherMatrixVars.(f)(I,:) = T.OtherMatrixVars.(f)(II,:);
      TT.OtherMatrixVars.(f)(~I,:) = NaN;
    end
  end
  
  if ~isempty( T.OtherSpatialVars )
    for f = fieldnames( T.OtherSpatialVars )'
      f = f{:};
      TT.OtherSpatialVars.(f)(I,:) = T.OtherSpatialVars.(f)(II,:);
      TT.OtherSpatialVars.(f)(~I,:) = NaN;
    end
  end
end

