function [R,bear] = interpRadialsBear( R, BearLims, MaxBearGap, varargin )
% INTERPRADIALSBEAR  Used for bearing interpolation of radials.  
%
% This function uses a slightly different algorithm for bearing
% interpolation than interpRadials (which also does range interpolation).
% Instead of first forcing data onto a grid using grid_data_nointerp and
% then interpolating it using interp1_gaps, as interpRadials does, this
% function interpolates data to a bearing grid from the actual range,bearing
% location of the radial data.
%
% Usage: [RADIAL,BEAR] = interpRadialsBear( RADIAL, BearLims, MaxBearGap, ... )
%
% Inputs
% ------
% RADIAL: A radial structure to be interpolated.  This must be a single
%         radial structure, as opposed to an array of radial structures with
%         multiple sites.
%
% BearLims: Can be either a three element vector of [ bearlowerlim,
%            bearincrement, bearupperlim ] or a vector of bearing values.
%            If absent or empty, defaults to unique(RADIAL.RangeBearHead(:,2)).
%            This could cause problems if only three bears are in RADIAL
%            structure. Note that if a three element vector is given, then
%            angleVector will be used to generate the list of bearing
%            values.
%
% MaxBearGap: size of the largest bearing gap to interpolate over in
%             degrees.  Defaults to 15 degrees.
%
% ... = extra arguments for interp1_gaps, such as interpolation method.
%
% Outputs
% -------
% RADIAL = RADIAL structure after interpolation.  Interpolation will only be
% performed over U, V, RadComp and Error.  The Flag will contain a number
% indicating where the data came from: 1 = original data, 4 = bearing
% interpolation.  This number is not particularly reliable as it is very
% sensitive to how exactly the original bearings match the new bearings.
%
% BEAR = List of bearings on which the interpolation was performed.
%
%
% NOTE: No attempt will be made to interpolate the variables in
% RADIAL.OtherMatrixVars.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: interpRadialsBear.m 640 2008-04-18 09:25:26Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myRADIALmatvars = RADIALmatvars;
myRADIALmatvars(1:2) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First deal with parameters passed to function.
% Process and validate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist( 'MaxBearGap', 'var' )
  MaxBearGap = 15;
end
if ~exist( 'BearLims', 'var' )
  BearLims = unique( R.RangeBearHead(:,2) );
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now create list of bearings for interpolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(BearLims) == 3
  bear = angleVector( BearLims(1), BearLims(2), BearLims(3) );
else
  bear = BearLims;
  BearLims = 'VECTOR';
end

% For range grid
range = unique( R.RangeBearHead(:,1) );

% Create grids
[range,bear] = meshgrid( range, bear );

% Generate equivalent lon, lat and headings using m_fdist
[Lon,Lat,head] = m_fdist( R.SiteOrigin(1), R.SiteOrigin(2), math2true(bear), ...
                          range * 1e3 );

% Fix longitude so that it is -180 to 180
Lon(Lon>180) = Lon(Lon>180) - 360;

% Put headings in math format
head = true2math( head );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put data on initial non-uniform grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[RR,BB,II] = meshgrid_vector_data(R.RangeBearHead(:,1),R.RangeBearHead(:,2));
JJ = find( isfinite(II) );
II = II(isfinite(II));

% Set flag to 4 for so this will propagate to interpolated results.
R.Flag = repmat(4,size(R.Flag));
R.Flag( isnan(R.RadComp) ) = NaN;

% Put data on grid.
clear UVSEF
for m = myRADIALmatvars
  m = m{:};
  UVSEF.(m) = repmat(NaN,[numel(RR),size(R.RadComp,2)]);
  UVSEF.(m)(JJ,:) = R.(m)(II,:);
  
  UVSEF.(m) = reshape( UVSEF.(m), [ size(RR), size(R.RadComp,2) ] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix angles so that they are suitable for interp1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bear = degrees( unwrap( radians( bear ), 2*(pi-eps) ) );
n = floor( bear(1) / 360 );

BB = mod(BB,360) + n * 360; % This should put Bear and BB on same page
BB = degrees( unwrap( radians( BB ), 2*(pi-eps) ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now interpolate to new grid worrying about gaps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for m = myRADIALmatvars
  m = m{:};
  UVSEF.(m)=interp1_gaps(MaxBearGap,BB(:,1),UVSEF.(m),bear(:,1),varargin{:});
  
  UVSEF.(m) = reshape( UVSEF.(m), [ prod(size(bear)), size(R.RadComp,2) ] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Try to fix flag - not particularly effective.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RBH = [ range(:), mod(bear(:),360), mod(head(:),360) ];

[c,Iorig,Inew] = intersect( R.RangeBearHead(:,1:2), RBH(:,1:2), 'rows' );

% Set flag of ones in common to 1 - assume that is original data
ii = double( isfinite( R.RadComp(Iorig,:) ) );
ii(~ii) = NaN;
UVSEF.Flag( Inew, : ) = ii;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put humpty dumpty back together again
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for m = myRADIALmatvars
  m = m{:};
  R.(m) = UVSEF.(m);
end
R.LonLat = [ Lon(:), Lat(:) ];
R.RangeBearHead = RBH;

% Add processing step
R.ProcessingSteps{end+1} = mfilename;

% Add metadata
R.OtherMetadata.(mfilename).MaxBearGap = MaxBearGap;
R.OtherMetadata.(mfilename).BearLims = BearLims;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Recreate U and V
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R.U = R.RadComp .* repmat(cosd(R.RangeBearHead(:,3)),[1,size(R.U,2)]);
R.V = R.RadComp .* repmat(sind(R.RangeBearHead(:,3)),[1,size(R.U,2)]);
