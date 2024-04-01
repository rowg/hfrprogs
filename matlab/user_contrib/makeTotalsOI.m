function [TOI,R] = makeTotalsOI(R,varargin)
% MAKETOTALSOI  Generates total vectors from OI of radials 


tic % Calculate total time.
disp( [ 'Starting ' mfilename ' @ ' datestr(now) ] );
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First deal with parameters passed to function.
% Process and validate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default parameters
p.MinNumSites = 2;
p.MinNumRads = 3;
%p.WhichErrors = {'GDOPMaxOrthog','GDOP','FitDif'};
p.DomainName = '';
p.CreationInfo = '';
p.verbosity = 24;
p.weighting = 2;  

p.normr = 2; % normalized radius  %new for OI
%The search radius is a function of the decorrelation scale.  You could theoretically %throw every possible radial data point into the calculation of each grid point, but %this would be incredibly inefficient, as most points greater than a few decorrelation %lengths away have Infinitesimally small weights.  We currently use a factor of 2, %such that a radial measurement must be within
%     sqrt( (x/sx)^2 + (y/sy)^2 ) < 2
%where sx an sy are the X and Y decorrelation scales and x and y are the distances %from the model grid point.  If you do the math backwards and assume sx=sy, you get my %estimate of 37km above.

% Mandatory parameters
mand_params = { 'Grid', 'TimeStamp', 'mdlvar', 'errvar', 'sx', 'sy', 'tempthresh', 'weighting' };

% known parameters
param_list = { 'Grid', 'TimeStamp', 'mdlvar', 'errvar', 'sx', 'sy', 'normr', 'tempthresh', 'weighting', 'MinNumSites', 'MinNumRads', 'DomainName', 'CreationInfo', 'verbosity' };

[p,pb] = checkParamValInputArgs( p, param_list, mand_params, varargin{:} );

% Warn if found some unknown parameters.
if ~isempty(pb)
  pb = strcat(fieldnames(pb), {' '} );
  pb = [ pb{:} ];
  warning( ['The following unknown parameters were given and will be ' ...
            'ignored: %s '], pb );
  clear pb
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create initial empty TUV structure and fill with
% basic data and metadata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIM = [ size(p.Grid,1), length(p.TimeStamp) ];
TOI = TUVstruct( DIM );
TOI.TimeStamp = p.TimeStamp(:)';
TOI.Type = 'OI';

% Copy relevant stuff from origional array
TOI.DomainName = p.DomainName;
p = rmfield(p,'DomainName');
TOI.CreationInfo = p.CreationInfo;
p = rmfield(p,'CreationInfo');

% Assume time zone is the same as radials.
TOI.TimeZone = R(1).TimeZone;

TOI.Depth = zeros(size(p.Grid(:,1)));

TOI.LonLat = p.Grid;
p = rmfield(p,'Grid');

% Save parameters
TOI.OtherMetadata.(mfilename).parameters = p;

% Generate "SiteCode" and remove empty radial structures.
% Removing them here saves checking later.
TOI.OtherMetadata.(mfilename).SiteCode = 0;
for k = 1:length(R)
  goodRADs(k) = ~isempty(R(k).RadComp);
  if ~goodRADs(k), continue; end
  TOI.OtherMetadata.(mfilename).SiteCode = TOI.OtherMetadata.(mfilename).SiteCode ...
      + R(k).SiteCode;
end
goodRADs = find(goodRADs);

% Initialize matrices for storing site codes and number of radials for
% individual grid points and time steps
TOI.OtherMatrixVars.([mfilename '_TotalsSiteCode']) = TOI.U;
TOI.OtherMatrixVars.([mfilename '_TotalsNumRads']) = TOI.U;
if nargout > 1
  for k = 1:length(R)
    R(k).OtherMetadata.(mfilename).TotalsNumRads = TOI.U;
  end
end

% Add processing steps
TOI.ProcessingSteps{end+1} = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup Error Array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
err = TUVerrorstruct( [ DIM ] );
err.Type = 'OIuncert';
% Remove unused arrays
%err.TotalErrors = deal([]);
%err.TotalErrorsUnits = deal('NA');

TOI.ErrorEstimates = err;
clear err

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trivial check for sufficient sites - might save time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(goodRADs) < p.MinNumSites
  warning( 'Not enough sites to calculate totals.' );
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now do heavy lifting.  Figure out which radial
% grid points are within the spatthresh of each grid
% point.  Do this now to save time for multiple 
% time steps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( [ 'Starting radial points to grid points distance calculations @ ' ...
        datestr( now ) ] );

% Find radial grid points that are within the radius of influence
% sds will be a cell array listing all radial points sufficiently close to grid points.
sds = {};
for j = goodRADs
  for k = 1:size(TOI.LonLat,1)
    [dx,dy] = lonlat2km( TOI.LonLat(k,1),TOI.LonLat(k,2), R(j).LonLat(:,1),R(j).LonLat(:,2));  %finds distance in x and y with lonlat2km instead of using lonlatdist
    sds{ j, k } = find( sqrt((dx/p.sx).^2 + (dy/p.sy).^2) < p.normr );
  end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop over timesteps and grid points and
% generate totals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get totals
for i = 1:length(p.TimeStamp)
  if mod( i-1, p.verbosity ) == 0
    disp( [ 'Starting on total vector map for timestep ' ...
	    datestr( p.TimeStamp(i) ) ' @ ' datestr( now ) ] );
  end

  % Get times that are within tempthresh
  % Get these now for speeds sake.
  t = {}; ns = 0;
  for j = goodRADs
    t{j} = find( abs( p.TimeStamp(i) - R(j).TimeStamp ) < p.tempthresh );
    ns = ns + ( length(t{j}) > 0 ); % Count number of possible sites.
  end
  
  % Continue if possible number of sites is too small.
  if ns < p.MinNumSites, continue, end
  
  % Now loop over grid points and pull out pieces of interest
  for k = 1:size(TOI.LonLat,1)
    rad_speed = []; rad_angle = []; rad_lonlat=[];  %new in OI code
    sc = 0; ns = 0;
    
    for j = goodRADs
      % Relevant radial locations.
      s = sds{j,k};
      
      % Relevant data at relevant times and locations.
      ss = R(j).RadComp(s,t{j});
      ss = ss(:); % Make a long vector if multiple timesteps used to create each total
      aa = R(j).RangeBearHead(s,3);
      aa = repmat( aa, [ length(t{j}), 1 ] ); % Needed if multiple timesteps are used      

      ll = R(j).LonLat(s,:); %Note this might fail if multiple timesteps are used

      % Remove possible bad data - only worry about data, not uncertainty estimate 
      aa( isnan(ss) ) = [];
      ll( isnan(ss),: ) = [];
      ss( isnan(ss) ) = [];
      
      % Bookkeeping
      if ~isempty(ss)
        sc = sc + R(j).SiteCode;
        ns = ns + 1;
        rad_speed = [ rad_speed; ss ];
        rad_angle = [ rad_angle; aa ];
        rad_lonlat = [ rad_lonlat; ll ];
        
        if nargout > 1
          R(j).OtherMetadata.(mfilename).TotalsNumRads(k,i) = size(ss,1);
        end
      end

    end %j = goodRADs
    
    TOI.OtherMatrixVars.([mfilename '_TotalsSiteCode'])(k,i) = sc;
    TOI.OtherMatrixVars.([mfilename '_TotalsNumRads'])(k,i) = size(rad_speed,1);
    TOI.OtherMatrixVars.([mfilename '_TotalsSiteCodeDescription']) = ...
    'A sum of radial site codes for sites that contributed data to the total vector calculation.  Refer to codes in the radial structures.';
    
    % Continue if number of sites or rads is too small.
    if ns < p.MinNumSites, continue, end
    if size(rad_speed,1) < p.MinNumRads, continue, end
    
    % All looks good - generate total
    [u,v,xi] = tuvOI(rad_speed,rad_angle, rad_lonlat, TOI.LonLat(k,:), ...
              p.mdlvar, p.errvar, p.sx, p.sy, p.weighting); 
    TOI.U(k,i) = u;
    TOI.V(k,i) = v;    
    TOI.ErrorEstimates.Uerr(k,i) = xi(1,1);
    TOI.ErrorEstimates.Verr(k,i) = xi(2,2);
    TOI.ErrorEstimates.UVCovariance(k,i) = xi(1,2);
    TOI.ErrorEstimates.TotalErrors(k,i) = sqrt(xi(1,1).^2 + xi(2,2).^2);
        
  end %k = 1:size(TOI.LonLat,1)
  
end %i = 1:length(p.TimeStamp)

% Finished
disp( [ 'Finishing ' mfilename ' @ ' datestr(now) ] );
disp( [ 'Total time for ' mfilename ': ' num2str(toc/60) ' minutes' ] );
