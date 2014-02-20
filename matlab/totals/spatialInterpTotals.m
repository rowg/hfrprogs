function Ti = spatialInterpTotals( T, LonLat, E, O, varargin )
% SPATIALINTERPTOTALS  Spatial interpolation of total vector
% currents.
%
% This function uses griddata to do spatial interpolation of 2D currents
% data in a TUV structure.  This function removes bad data from each
% timestep before performing interpolation.
%
% Usage: TUVi = spatialInterpTotals(TUVo,LonLat,Errors,Others,...)
%
% Inputs
% ------
% TUVo = TUV structure with the total currents data.
% LonLat = 2 column matrix of new Lon,Lat coordinates.  If empty or
%          absent, then TUVo.LonLat will be used (i.e. the function will
%          fill in missing values).
% Errors = boolean indicating whether or not to attempt spatial
%          interpolation of errors.  Defaults to false.  If false and LonLat
%          is neither empty nor absent, then no errors will be present in
%          the new TUV structure.
% Others = boolean indicating whether or not to attempt spatial
%          interpolation of variables in OtherMatrixVars and
%          OtherSpatialVars.  Defaults to false.  If false and LonLat is
%          neither empty nor absent, then OtherMatrixVars and
%          OtherSpatialVars will be empty in the new TUV structure.
% ... = Extra arguments for interp2.
%
% Outputs
% -------
% TUVi = TUV structure with interpolated data.  If the input LonLat
%        was absent or empty, then TUVi.OtherMatrixVars will contain an
%        extra variable spatialInterpTotalsGrid_Flag that has a 1 for
%        original data, 2 for interpolated data and NaN for data that
%        could not be interpolated.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: spatialInterpTotals.m 401 2007-04-03 19:07:44Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('O','var') || isempty(O)
  O = false;
end
if ~exist('E','var') || isempty(E)
  E = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Ti based on input ts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('LonLat','var') || isempty(LonLat)
  Ti = T;
  fn = [ mfilename '_Flag' ];
else
  % Use subsrefTUV to keep metadata easily
  Ti = subsrefTUV(T,ones([size(LonLat,1),1]),':',E,O);
  Ti.OtherTemporalVars = T.OtherTemporalVars;
  
  Ti.LonLat = LonLat;
end

% Add processing steps
Ti.ProcessingSteps{end+1} = mfilename;

% Add metadata 
Ti.OtherMetadata.(mfilename).InterpErrors = E;
Ti.OtherMetadata.(mfilename).InterpOthers = O;
Ti.OtherMetadata.(mfilename).varargin = varargin;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do interpolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[X,Y] = deal( T.LonLat(:,1), T.LonLat(:,2) );
[XI,YI] = deal( Ti.LonLat(:,1), Ti.LonLat(:,2) );
gd = isfinite( T.U + T.V );
for k = 1:numel(T.TimeStamp) % Loop over times.
  gg = gd(:,k);
  
  Ti.U(:,k) = my_griddata(X(gg),Y(gg),T.U(gg,k),XI,YI,varargin{:});
  Ti.V(:,k) = my_griddata(X(gg),Y(gg),T.V(gg,k),XI,YI,varargin{:});

  % Interpolation of Errors
  if E & ~isempty(T.ErrorEstimates)
    for k = 1:numel(T.ErrorEstimates)
      % Normal error vars
      for f = TUVerrorMatvars
        f = f{:};
        if ~isempty( T.ErrorEstimates(k).(f) )
          xx = my_griddata(X(gg),Y(gg), ...
                        T.ErrorEstimates(k).(f)(gg,k),XI,YI, ...
                        varargin{:});
          Ti.ErrorEstimates(k).(f)(:,k) = xx;
        end
      end
      
      % Extra error vars
      if ~isempty(T.ErrorEstimates(k).OtherMatrixVars)
        for f = fieldnames(T.ErrorEstimates(k).OtherMatrixVars)'
          f = f{:};
          xx = my_griddata(X(gg),Y(gg), ...
                        T.ErrorEstimates(k).OtherMatrixVars.(f)(gg,k), ...
                        XI,YI, varargin{:});
          Ti.ErrorEstimates(k).OtherMatrixVars.(f)(:,k) = xx;
        end  
      end
      
    end
  end
  
  % Interpolation of others
  if O & ~isempty(T.OtherMatrixVars)
    for f = fieldnames(T.OtherMatrixVars)'
      f = f{:};
      xx = my_griddata(X(gg),Y(gg),T.OtherMatrixVars.(f)(gg,k),XI,YI, ...
                    varargin{:});
      Ti.OtherMatrixVars.(f)(:,k) = xx;
    end
  end
end

% Interpolation of OtherSpatialVars - don't even try to determine if any
% of the data in OtherSpatialVars is bad because there is no consistent
% way to do so.  Just use all data.
if O & ~isempty(T.OtherSpatialVars)
  for f = fieldnames(T.OtherSpatialVars)'
    f = f{:};
    for k = 1:size(T.OtherSpatialVars.(f),2) % Number of columns in this var
      xx = my_griddata(X,Y,T.OtherSpatialVars.(f)(:,k),XI,YI,varargin{:});
      Ti.OtherSpatialVars.(f)(:,k) = xx;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flag if required
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('fn','var')
  Ti.OtherMatrixVars.( fn ) = repmat(NaN,size(Ti.U));
  Ti.OtherMatrixVars.( fn )( isfinite(T.U+T.V) ) = 1;
  Ti.OtherMatrixVars.( fn )( ~isfinite(T.U+T.V) & isfinite(Ti.U+Ti.V)) = 2;
end


%% ------------- Subfunctions ------------- %%
function ZI = my_griddata( x, y, z, XI, YI, varargin )
% This function deals with case of no good data which causes failure in
% Matlab > 7.0 apparently.
if isempty(x)
  ZI = repmat(NaN,size(XI));
else
  ZI = griddata( x, y, z, XI, YI, varargin{:} );
end
