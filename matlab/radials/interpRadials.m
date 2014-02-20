function [R,range,bear,head] = interpRadials( R, varargin )
% INTERPRADIALS  Used for range and bear interpolation of radials.  
%
% Usage: [RADIAL,RANGE,BEAR,HEAD] = interpRadials( RADIAL, PARAM1, VAL1, ..., PARAMn, VALn )
%
% Inputs
% ------
% RADIAL = A radial structure to be interpolated.  This must be a single
% radial structure, as opposed to an array of radial structures with
% multiple sites.
%
% PARAMn,VALn = string parameter names and associated values.  The list
% of possible parameters is:
%
% RangeLims: Can be either a three element vector of
%            [ rangelowerlim, rangeincrement, rangeupperlim ] or a
%            vector of range values.  If absent or empty, defaults to
%            unique(RADIAL.RangeBearHead(:,1)).  This could cause problems
%            if 3 ranges are in RADIAL structure.
% BearLims: Can be either a three element vector of [ bearlowerlim,
%            bearincrement, bearupperlim ] or a vector of bear values.
%            If absent or empty, defaults to unique(RADIAL.RangeBearHead(:,2)).
%            This could cause problems if only three bears are in RADIAL
%            structure. Note that if a three element vector is given, then
%            angleVector will be used to generate the list of bear values.
% RangeDelta: Value indicating how far a range value of a radial measurement
%             can be from the grid range value and be considered the
%             same range.  Defaults to eps.
% BearDelta: Value indicating how far an bear value of a radial measurement
%             can be from the grid bear value and be considered the
%             same bear.  Defaults to eps.
% MaxRangeGap: size of the largest range gap in array index units over which
%              interpolation is to be performed.  Defaults to 2.5 (results
%              in filling in single gaps in range).  Set to zero to turn off
%              range interpolation (though data will still be placed on the
%              grid).
% MaxBearGap: size of the largest bear gap in array index units over which
%              interpolation is to be performed.  Defaults to 3.5 (results
%              in filling in gaps of up to two missing bearing bins).  Set
%              to zero to turn off bear interpolation (though data will
%              still be placed on the grid).
% CombineMethod: A string that determines how to combine results of bear
%                and range interpolation.  Can be 'range', in which case
%                range interpolation is preferred over bear
%                interpolation, 'bear', in which case bear
%                interpolation is preferred, or 'average', in which case
%                the average of the two is returned. Defaults to 'average'.
%
% Outputs
% -------
% RADIAL = RADIAL structure after interpolation.  Interpolation will only be
% performed over U, V, RadComp and Error.  The Flag will contain a number
% indicating where the data came from: 1 = original data, 2 = range
% interpolation, 4 = bear interpolation, 6 = average of both.
%
% RANGE = Range grid on which the interpolation was performed.
% BEAR = Bear grid on which the bear interpolation was performed.
% HEAD = Heading grid corresponding to RANGE, HEAD and SiteOrigin.
% 
%
% NOTE: No attempt will be made to interpolate the variables in
% RADIAL.OtherMatrixVars.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: interpRadials.m 643 2008-04-23 04:06:28Z cook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First deal with parameters passed to function.
% Process and validate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default parameters
p.RangeDelta = eps;
p.BearDelta = eps;
p.MaxRangeGap = 2.5;
p.MaxBearGap = 3.5;
p.CombineMethod = 'average';

% known parameters
param_list = [ fieldnames(p)', {'RangeLims','BearLims'} ];

[p,pb] = checkParamValInputArgs( p, param_list, {}, varargin{:} );

% Error if unknown CombineMethod
switch p.CombineMethod
  case {'average','range','bear'}
  otherwise
    error( [ 'Unknown CombineMethod: ' p.CombineMethod ] );
end

% Warn if found some unknown parameters.
if ~isempty(pb)
  pb = strcat(fieldnames(pb), {' '} );
  pb = [ pb{:} ];
  warning( ['The following unknown parameters were given and will be ' ...
            'ignored: %s '], pb );
  clear pb
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now create grids if necessary.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need to determine what the delta range and bearing are, and make filled
% vectors.  Actually could see if min and max are different, this would be
% the only time that you would need to do this. MCook
[range,bear,head] = deal([],[],[]);
if ~isfield( p, 'RangeLims' ) || isempty(p.RangeLims)
  range = unique(R.RangeBearHead(:,1));
  minRange = min(diff(range));
  maxRange = max(diff(range));
  % All dRanges same, unique OK
  if abs(maxRange - minRange) < 0.01 
      fprintf('%s: using unique ranges without modification\n', ...
              R.SiteName);
  % minRange too small - an insane number of ranges which will choke the
  % gridding process
  elseif minRange < 0.01
      fprintf('%s: minimum unique range is %f, too small!\n', ...
          R.SiteName,minRange);
      R.OtherMetadata.(mfilename) = 'Failed due in unique minRange < 0.01';
      return;
  % Create range vector because, for example, Missing look angle (spoke) 
  % or range ring (all angles), will mess up the interp1_gaps
  % interpolation using the array index method.
  else
      range = range(1):minRange:range(end);
      fprintf('%s: Min range = %f, Max range = %f\n', ...
              R.SiteName,minRange,maxRange);
  end
  p.RangeLims = 'VECTOR';
elseif numel(p.RangeLims) == 3
  range = p.RangeLims(1):p.RangeLims(2):p.RangeLims(3);
else
  range = p.RangeLims;
  p.RangeLims = 'VECTOR';
end


if ~isfield( p, 'BearLims' ) || isempty(p.BearLims)
  bear = unique(R.RangeBearHead(:,2));
  minBear = min(diff(bear));
  maxBear = max(diff(bear)); 
  % All dBearings same, unique OK
  if abs(maxBear - minBear) < 0.01 
      fprintf('%s: using unique bearings without modification\n', ...
              R.SiteName);
  % minBearing too small - an insane number of bearings which will choke 
  % the gridding process
  elseif minBear < 0.01
      fprintf('%s: minimum unique bearing is %f, too small!\n', ...
          R.SiteName,minBear);
      R.OtherMetadata.(mfilename) = 'Failed due in unique minBear < 0.01';
      return;
  % Missing look angle (spoke) or range ring (all angles), which will mess
  % up the interp1_gaps interpolation using the array index method.
  else
      bear = angleVector(bear(1),minBear,bear(end));
      fprintf('%s: Min bearing = %f, Max bearing %f\n', ...
              R.SiteName,minBear,maxBear);
  end
  p.BearLims = 'VECTOR';
elseif numel(p.BearLims) == 3
  bear = angleVector( p.BearLims(1), p.BearLims(2), p.BearLims(3) );
else
  bear = p.BearLims;
  p.BearLims = 'VECTOR';
end

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
% Put data on grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up matrices for storing gridded data.
for m = { 'Error', 'RadComp' }
  m = m{:};
  UVSEF.(m) = repmat(NaN,[numel(range),size(R.RadComp,2)]);
end

% Loop over each timestep and try to grid non-NaN data.  This is slower than
% gridding the whole thing, including NaNs, all at once, but avoids the
% conflict with temporalConcatRadials and multiple close-by grid points.
gd = isfinite( R.RadComp ); % Good data
for k = 1:size(R.RadComp,2) % Loop over times
  gg = find(gd(:,k));
  
  [I,NI] = griddata_nointerp( range, bear, R.RangeBearHead(gg,1), ...
                              R.RangeBearHead(gg,2), [], p.RangeDelta, ...
                              p.BearDelta );
  II = find( isfinite(I) ); % Index into range
  I = I(isfinite(I)); % Index into original good data

  if ~isempty(NI)
     warning( '###%s:\n%d of %d good radial data points did not fit on radial grid.\n', ...
              char(R.FileName), size(NI,1),size(R.RangeBearHead(gg,1),1) ); 
  end

  % Put data in its place.
  for m = { 'Error', 'RadComp' }
    m = m{:};
    UVSEF.(m)(II,k) = R.(m)(gg(I),k);
  end
end

% Reshape things appropriately
for m = { 'Error', 'RadComp' }
  m = m{:};
  UVSEF.(m) = reshape( UVSEF.(m), [ size(range), size(R.RadComp,2) ] );
end

% Set up initial flag of ones and zeros
UVSEF.Flag = isfinite( UVSEF.RadComp );

%keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do interpolation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for m = { 'Error', 'RadComp' }
  m = m{:};
  s = size(UVSEF.(m));
  
  % Bearing interpolation
  uu1 = interp1_gaps(p.MaxBearGap,UVSEF.(m));
  
  % Range interpolation - need shiftdim to put range dimension first for
  % interp1_gaps. 
  uu2 = interp1_gaps(p.MaxRangeGap,shiftdim(UVSEF.(m),1));
  uu2 = shiftdim(uu2,length(s)-1);
    
  switch p.CombineMethod
    case 'average'
      UVSEF.(m) = reshape(nanmean( [uu1(:),uu2(:)], 2 ),s);
    case 'range'
      UVSEF.(m) = uu1;
      UVSEF.(m)(isfinite(uu2)) = uu2(isfinite(uu2));
    case 'bear'
      UVSEF.(m) = uu2;
      UVSEF.(m)(isfinite(uu1)) = uu1(isfinite(uu1));
  end
end

% Deal with flag based on ind1 and ind2 from RadComp interpolation
ind1 = isfinite(uu1) & ~UVSEF.Flag;
ind2 = isfinite(uu2) & ~UVSEF.Flag;
switch p.CombineMethod
  case 'average'
    UVSEF.Flag = UVSEF.Flag + 2 * ind2 + 4 * ind1;
  case 'range'
    UVSEF.Flag = UVSEF.Flag + 2 * ind2 + 4 * (ind1 & ~ind2);
  case 'bear'
    UVSEF.Flag = UVSEF.Flag + 2 * (ind2 & ~ind1) + 4 * ind1;
end      
UVSEF.Flag( UVSEF.Flag == 0 ) = NaN; % Put NaNs in place of zeros

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put humpty dumpty back together again
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for m = { 'RadComp', 'Error', 'Flag' }
  m = m{:};
  R.(m) = reshape(UVSEF.(m),[numel(range),size(R.RadComp,2)]);
end
R.LonLat = [ Lon(:), Lat(:) ];
R.RangeBearHead = [ range(:), bear(:), head(:) ];

% Add processing step
R.ProcessingSteps{end+1} = mfilename;

% Add metadata
R.OtherMetadata.(mfilename) = p;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Recreate U and V
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R.U = R.RadComp .* repmat(cosd(R.RangeBearHead(:,3)),[1,size(R.U,2)]);
R.V = R.RadComp .* repmat(sind(R.RangeBearHead(:,3)),[1,size(R.U,2)]);
