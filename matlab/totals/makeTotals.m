function [TUV,R] = makeTotals(R,varargin)
% MAKETOTALS  Generates total vectors from radial measurements 
% via least-squares method.
%
% Usage: [TUV,RADIAL] = makeTotals( RADIAL, PARAM1, VAL1, PARAM2, VAL2, ... )
%
% Inputs
% ------
% RADIAL: RADIAL structure containing the radial data to use for fitting.
% PARAMn,VALn: String parameter names and value pairs (described below).
%
% Outputs
% -------
% TUV: A TUV structure containing the resulting total vectors.
% RADIAL: Same as RADIAL structure array input, except that RADIAL
%         structures with no data will be removed and some extra metadata
%         indicating how many radials from each site went into each total
%         vector will be added.
%
% Parameters:
% ----------
% There are a number of different parameters that can be specified to
% this function.  Some are mandatory, others are not.  Each is listed
% below with a description:
%
% MANDATORY Parameters:
% --------------------
% 'Grid' - 2 column vector with lon-lat coords. of grid to use for totals
%          generation
% 'TimeStamp' - vector of times at which to generate totals in matlab
%               datenum units.
% 'spatthresh' - radius in KMS of area inside of which radial vectors are
%                considered for generating total vector at grid point.
% 'tempthresh' - number indicating window of time to use around each
%                'TimeStamp' - radial maps inside that window are used to
%                generate total vectors for that map.  This should be in
%                fractions of a day.
% 
% OPTIONAL Parameters:
% -------------------
% 'MinNumSites' - Minimum number of radial sites. Defaults to 2.
% 'MinNumRads' - Minimum number of radial vectors. Defaults to 3.
% 'WhichErrors' - a cellstr indicating which errors to record.
%                 Defaults to {'GDOPMaxOrthog','GDOP','FitDif'}.  Other
%                 possibilities are 'GDOPRadErr', which includes the
%                 measured radial error, and 'GDOPSites', which uses the
%                 mean radial angle from each radar site for the error
%                 calculation (more or less assuming perfect error
%                 covariance for all radials from a site).
% 'DomainName' - a name for the totals domain (e.g. 'BML')
% 'CreationInfo' - possibly person generating totals (e.g., 'DMK')
% 'verbosity' - how often to spit out something about state of processing.
%               The higher the number, the less is spit out.  -1 for
%               nothing. Defaults to 24, i.e. report every 24 timesteps.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: makeTotals.m 647 2008-04-23 14:28:54Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic % Calculate total time.
disp( [ 'Starting ' mfilename ' @ ' datestr(now) ] );
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First deal with parameters passed to function.
% Process and validate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default parameters
p.MinNumSites = 2;
p.MinNumRads = 3;
p.WhichErrors = {'GDOPMaxOrthog','GDOP','FitDif'};
p.DomainName = '';
p.CreationInfo = '';
p.verbosity = 24;

% Mandatory parameters
mand_params = { 'Grid', 'TimeStamp', 'spatthresh', 'tempthresh' };

% known parameters
param_list = { 'Grid', 'TimeStamp', 'spatthresh', 'tempthresh',  'MinNumSites', ...
               'MinNumRads', 'WhichErrors', ...
               'DomainName', 'CreationInfo', 'verbosity' };

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
TUV = TUVstruct( DIM );
TUV.Type = 'TUV';
TUV.TimeStamp = p.TimeStamp(:)';

TUV.DomainName = p.DomainName;
p = rmfield(p,'DomainName');
TUV.CreationInfo = p.CreationInfo;
p = rmfield(p,'CreationInfo');

% Assume time zone is the same as radials.
TUV.TimeZone = R(1).TimeZone;

TUV.Depth = zeros(size(p.Grid(:,1)));

TUV.LonLat = p.Grid;
p = rmfield(p,'Grid');

% Save parameters
TUV.OtherMetadata.(mfilename).parameters = p;

% Generate "SiteCode" and remove empty radial structures.
% Removing them here saves checking later.
TUV.OtherMetadata.(mfilename).SiteCode = 0;
for k = 1:length(R)
  goodRADs(k) = ~isempty(R(k).RadComp);
  if ~goodRADs(k), continue; end
  TUV.OtherMetadata.(mfilename).SiteCode = TUV.OtherMetadata.(mfilename).SiteCode ...
      + R(k).SiteCode;
end
goodRADs = find(goodRADs);

% Initialize matrices for storing site codes and number of radials for
% individual grid points and time steps
TUV.OtherMatrixVars.([mfilename '_TotalsSiteCode']) = TUV.U;
TUV.OtherMatrixVars.([mfilename '_TotalsNumRads']) = TUV.U;
if nargout > 1
  for k = 1:length(R)
    R(k).OtherMetadata.(mfilename).TotalsNumRads = TUV.U;
  end
end

% Add processing steps
TUV.ProcessingSteps{end+1} = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sort out errors info initially for speed.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
known_errors = { 'FitDif', 'GDOPMaxOrthog', 'GDOP', 'GDOPRadErr', 'GDOPSites' };
err = TUVerrorstruct([0,0]); % Stripped off at end
for ee = p.WhichErrors(:)'
  switch ee{:}
    case known_errors
      err(end+1) = TUVerrorstruct( [ DIM ] );
      err(end).Type = ee{:};
      eval([ ee{:} ' = length(err)-1;' ]);
    otherwise
      warning( [ 'Unknown error type "' ee{:} '" will be ignored.' ] );
  end
end
err(1) = [];

% Particular stuff for each error type
if exist('FitDif','var')
  % Make things a bit smaller
  [err(FitDif).Uerr,err(FitDif).Verr,err(FitDif).UVCovariance] = ...
      deal([]);
  
  % No units for empty elements
  [err(FitDif).UerrUnits,err(FitDif).VerrUnits, err(FitDif).UVCovarianceUnits] ...
      = deal('NA');
end

if exist('GDOPRadErr','var')
  % Square radial uncertainties now for speed.
  raderr = {};
  for k = goodRADs
    raderr{k} = R(k).Error.^2;
  end
end

TUV.ErrorEstimates = err;
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

% This allows the spatial window to vary over space.
% Somewhat experimental - make spatthresh a vector to vary for each
% grid point.
sw = p.spatthresh;
if prod(size(sw)) == 1
  sw = repmat( sw, size(TUV.LonLat(:,1)) );
end
    
% Get grid points that are inside window.
% This way is slower than computing all distances at onces,
% but it saves on memory.
% sds will be a cell array listing all radar points sufficiently close to
% grid points.
sds = {};
for j = goodRADs
  for k = 1:size(TUV.LonLat,1)
    s = lonlat2dist( TUV.LonLat(k,:), R(j).LonLat' );

    %%% Commenting this out because it is a big performance hit over
    %%% lonlat2dist
%     s = m_idist( TUV.LonLat(k,1), TUV.LonLat(k,2), ...
%                  R(j).LonLat(:,1), R(j).LonLat(:,2) ) / 1e3;
    
    sds{ j, k } = find( s < sw(k) );
  end    
end
clear sw

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
    t{j} = find( abs( p.TimeStamp(i) - R(j).TimeStamp ) < ...
		 p.tempthresh );
    ns = ns + ( length(t{j}) > 0 ); % Count number of possible sites.
  end
  
  % Continue if possible number of sites is too small.
  if ns < p.MinNumSites, continue, end
  
  % Now loop over grid points and pull out pieces of interest
  for k = 1:size(TUV.LonLat,1)
    sp = []; angle = []; re = []; sc = 0; ns = 0; si = [];
    for j = goodRADs
      % Relevant radial locations.
      s = sds{j,k};
      
      % Relevant data at relevant times and locations.
      ss = R(j).RadComp(s,t{j});
      ss = ss(:); % Make a long vector if multiple timesteps used to
                  % create each total
      aa = R(j).RangeBearHead(s,3);
      aa = repmat( aa, [ length(t{j}), 1 ] ); % Needed if multiple timesteps used
                                              % to make each total
      
      % Relevant errors
      if exist('GDOPRadErr','var')
        r = raderr{j}(s,t{j});
        r = r(:); % Again, make a long vector
        
        % Remove bad data and add to end
        r( isnan(ss) ) = [];
        if ~isempty(r), re = [ re; r ]; end
      end
      
      % Remove possible bad data - only worry about data, not uncertainty
      % estimate 
      aa( isnan(ss) ) = [];
      ss( isnan(ss) ) = [];
      
      % Bookkeeping
      if ~isempty(ss)
        sc = sc + R(j).SiteCode;
        ns = ns + 1;
        
        sp = [ sp; ss ];
        angle = [ angle; aa ];

        if exist( 'GDOPSites', 'var' )
          si = [ si; repmat(j,size(ss)) ];
        end
        
        if nargout > 1
          R(j).OtherMetadata.(mfilename).TotalsNumRads(k,i) = size(ss,1);
        end
      end
    end
    
    TUV.OtherMatrixVars.([mfilename '_TotalsSiteCode'])(k,i) = sc;
    TUV.OtherMatrixVars.([mfilename '_TotalsNumRads'])(k,i) = size(sp,1);
    
    % Continue if number of sites or rads is too small.
    if ns < p.MinNumSites, continue, end
    if size(sp,1) < p.MinNumRads, continue, end
    
    % All looks good - generate total
    if exist('GDOPRadErr','var')
      [u,v,C,fd,CE] = tuvLS(sp,angle,re);
      TUV.ErrorEstimates(GDOPRadErr).Uerr(k,i) = CE(1,1);
      TUV.ErrorEstimates(GDOPRadErr).Verr(k,i) = CE(2,2);
      TUV.ErrorEstimates(GDOPRadErr).UVCovariance(k,i) = CE(1,2);
    else
      [u,v,C,fd] = tuvLS(sp,angle);
    end
    
    TUV.U(k,i) = u;
    TUV.V(k,i) = v;    
    
    % Do rest of special error estimates
    if exist('GDOP','var')
      TUV.ErrorEstimates(GDOP).Uerr(k,i) = C(1,1);
      TUV.ErrorEstimates(GDOP).Verr(k,i) = C(2,2);
      TUV.ErrorEstimates(GDOP).UVCovariance(k,i) = C(1,2);
    end
    
    if exist('FitDif','var')
      TUV.ErrorEstimates(FitDif).TotalErrors(k,i) = fd;      
    end
    
    if exist('GDOPMaxOrthog','var')
      C = gdop_max_orthog( angle );
      TUV.ErrorEstimates(GDOPMaxOrthog).Uerr(k,i) = C(1,1);
      TUV.ErrorEstimates(GDOPMaxOrthog).Verr(k,i) = C(2,2);
      TUV.ErrorEstimates(GDOPMaxOrthog).UVCovariance(k,i) = C(1,2);
    end
    
    if exist( 'GDOPSites', 'var' )
      C = gdop_one_rad_per_site( angle, si );
      %C = gdop_site_rad_covariance( angle, si );
      TUV.ErrorEstimates(GDOPSites).Uerr(k,i) = C(1,1);
      TUV.ErrorEstimates(GDOPSites).Verr(k,i) = C(2,2);
      TUV.ErrorEstimates(GDOPSites).UVCovariance(k,i) = C(1,2);
    end
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate total errors at end for speed.
% This total error calculation uses formulation
% I got from Cedric that is the largest eigenvalue
% of the covariance matrix.  This is the mathematical
% "norm" of the covariance matrix and is typically 
% used as a measure of the "size" of a matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( [ 'Starting calculation of total errors @ ' ...
        datestr( now ) ] );

% Calculate total errors for those that need it.
for k = 1:length(TUV.ErrorEstimates)
  switch TUV.ErrorEstimates(k).Type
    case {'GDOPMaxOrthog','GDOP','GDOPRadErr','GDOPSites'}
      TUV.ErrorEstimates(k).TotalErrors = sqrt( norm_covariance_matrix( ...
          TUV.ErrorEstimates(k).Uerr, TUV.ErrorEstimates(k).Verr, ...
          TUV.ErrorEstimates(k).UVCovariance ) );
  end
end

% Correct units where needed.
for k = 1:length(TUV.ErrorEstimates)
  switch TUV.ErrorEstimates(k).Type
    case {'GDOPMaxOrthog','GDOP','GDOPSites'}
      [TUV.ErrorEstimates(k).UerrUnits,TUV.ErrorEstimates(k).VerrUnits, ...
       TUV.ErrorEstimates(k).UVCovarianceUnits] = deal('unitless_velocity^2');
      TUV.ErrorEstimates(k).TotalErrorsUnits = 'unitless_velocity';
  end
end

% Finished
disp( [ 'Finishing ' mfilename ' @ ' datestr(now) ] );
disp( [ 'Total time for ' mfilename ': ' num2str(toc/60) ' minutes' ] );
