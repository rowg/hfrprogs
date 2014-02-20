function [Toma,OMA_cov_alpha] = fit_OMA_modes_to_radials( R, varargin )
% FIT_OMA_MODES_RADIALS  Do OMA fit to radial current measurements.
% 
% Usage: [TUVoma,OMA_cov_alpha] = fit_OMA_modes_to_radials( RADIAL, PARAM1, VAL1, PARAM2, VAL2, ... )
%
% Inputs
% ------
% RADIAL: RADIAL structure containing the radial data to use for fitting.
% PARAMn,VALn: String parameter names and value pairs (described below).
%
% Outputs
% -------
% TUVoma = A TUV structure containing the results of the fit.  Will contain
%          metadata, including TUVoma.OtherTemporalVars.OMA_alpha. 
% OMA_cov_alpha = a matrix of error covariances among the coefficients in
%                 OMA_alpha.  This is not normally included in the metadata
%                 as this matrix can be very very large, but this
%                 information will be necessary if error propagation at
%                 locations other than those in the grid in the
%                 interp_filename file.  The result will be a two
%                 dimensional matrix with one column for each timestep
%                 and the number of rows equal to (number of modes)^2.
%
% Parameters:
% ----------
% There are a number of different parameters that can be specified to
% this function.  Some are mandatory, others are not.  Each is listed
% below with a description:
%
% MANDATORY Parameters:
% --------------------
% 'modes_filename' - name of file where OMA modes information is stored.
% 'TimeStamp' - vector of times at which to generate totals in matlab
%               datenum units.
% 'tempthresh' - number indicating window of time to use around each
%                'TimeStamp' - radial maps inside that window are used to
%                generate total vectors for that map.  This should be in
%                fractions of a day.
% 
% OPTIONAL Parameters:
% -------------------
% 'interp_filename' - name of file where interpolation of OMA modes to
%                     points where totals data will be calculated is
%                     kept. If absent or empty, it is assumed this is the
%                     same as the 'modes_filename'.
% 'K' - Value of the "homogenization" constant in the fit.  See the openMA
%       toolbox for more details on this.  If absent or empty, defaults to
%       0.
% 'error_type' - a string indicating which errors to use for error
%                propagation. Can be 'radials', for using the measured
%                radial uncertainties, 'constant', to assume an uncertainty
%                of 1 for each radial measurement, and 'none', for no error
%                propagation.  Defaults to 'constant'.
% 'DomainName' - a name for the totals domain (e.g. 'BML')
% 'CreationInfo' - possibly person generating totals (e.g., 'DMK')
% 'verbosity' - how often to spit out something about state of processing.
%               The higher the number, the less is spit out.  -1 for
%               nothing. Defaults to 24, i.e. report every 24 timesteps.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: fit_OMA_modes_to_radials.m 554 2007-12-20 10:34:20Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
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
p.K = 0;
p.error_type = 'constant';
p.DomainName = '';
p.CreationInfo = '';
p.verbosity = 24;

% Mandatory parameters
mand_params = { 'modes_filename', 'TimeStamp', 'tempthresh' };

% known parameters
param_list = [ mand_params, { 'interp_filename', 'K', 'error_type', ...
                    'DomainName', 'CreationInfo', 'verbosity' } ];

[p,pb] = checkParamValInputArgs( p, param_list, mand_params, varargin{:} );

% Fix interp_filename
if ~isfield( p, 'interp_filename' )
  p.interp_filename = p.modes_filename;
end

% Warn if found some unknown parameters.
if ~isempty(pb)
  pb = strcat(fieldnames(pb), {' '} );
  pb = [ pb{:} ];
  warning( ['The following unknown parameters were given and will be ' ...
            'ignored: %s '], pb );
  clear pb
end

p.TimeStamp = p.TimeStamp(:)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find out which errors to propagate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch p.error_type
  case {'none','constant','radials'}
  otherwise
    error( [ 'Unknown error type ''' p.error_type ''' for error propagation.' ...
           ] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load in modes data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
m = load( p.modes_filename, 'pLonLat', 't', 'ux_tri', 'uy_tri', 'border' );
load( p.modes_filename, 'homogeneous_matrix' );
g = load( p.interp_filename, 'ux_interp_grid', 'uy_interp_grid', 'gridLonLat' ...
          );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create an empty TUV structure for storing result now.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIM = [ size( g.gridLonLat, 1 ), numel(p.TimeStamp) ];
Toma = TUVstruct( DIM, ~strcmp(p.error_type,'none') );
Toma.Type = 'OMA';

% Copy relevant stuff over from original totals data
Toma.DomainName = p.DomainName;
Toma.CreationInfo = p.CreationInfo;
Toma.TimeStamp = p.TimeStamp;

% Assume time zone is the same as radials.
Toma.TimeZone = R(1).TimeZone;

% Add processing steps
Toma.ProcessingSteps{end+1} = mfilename;

% Put grid in place
Toma.LonLat = g.gridLonLat;

% Save some additional metadata
Toma.OtherMetadata.(mfilename) = rmfield( p, {'DomainName', ...
                    'CreationInfo','TimeStamp'} );

Toma.OtherTemporalVars.OMA_NumRadSites = zeros( size(p.TimeStamp) );

% Place for alpha
Toma.OtherTemporalVars.OMA_alpha = repmat( NaN, [ size(m.ux_tri,2), ...
                    numel(p.TimeStamp) ] );
if nargout > 1
  OMA_cov_alpha = repmat( NaN, [ size(m.ux_tri,2)^2, numel(p.TimeStamp) ] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare radials for fit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( [ 'Preparing radials for fit to modes @ ' datestr( now ) ] );

% Generate "SiteCode" and remove empty radial structures.
% Removing them here saves checking later.
kk = [];
for k = 1:numel(R)
  if isempty(R(k).RadComp)
    warning( [ 'RADIAL structure #' int2str(k) ' had no data. Removing!' ] );
    kk = [ kk, k ];
  end
end
R(kk) = []; 
Toma.OtherMetadata.(mfilename).SiteCode = sum( [ R.SiteCode ] );
Toma.OtherTemporalVars.OMA_NumRadialsPerSite = zeros( [ numel(R), ...
                    numel(p.TimeStamp) ] );

if isempty(R)
  warning( 'No valid data. Exiting!' );
  return
end

% Remove radials outside domain - faster to attempt now.
R = maskRadials( R, m.border );

% Interpolate modes at positions of data - faster to do it now, rather
% than with openMA_modes_fit_NaNs.
[ux,uy] = deal({});
for k = 1:numel(R)
  [ux{k},uy{k}] = pdeintrp_arbitrary( R(k).LonLat, m.pLonLat, m.t, m.ux_tri, ...
                                      m.uy_tri );
end
clear m

% Weights - none currently
weights = [];

% Square radial uncertainties now for speed.
if strcmp('radials',p.error_type)
  for k = 1:numel(R)
    R(k).Error = R(k).Error.^2;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop over timesteps and do fits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get totals
for i = 1:length(p.TimeStamp)
  if mod( i-1, p.verbosity ) == 0
    disp( [ 'Starting on OMA fit for timestep ' ...
	    datestr( p.TimeStamp(i) ) ' @ ' datestr( now ) ] );
  end

  % Loop over radials and get useful info.
  [uux,uuy,head,speed,err] = deal([]);
  for j = 1:numel(R)
    tt = find( abs( p.TimeStamp(i) - R(j).TimeStamp ) < ...
		 p.tempthresh );

    uux = [ uux; repmat( ux{j}, [ length(tt), 1 ] ) ];
    uuy = [ uuy; repmat( uy{j}, [ length(tt), 1 ] ) ];
    head = [ head; repmat( R(j).RangeBearHead(:,3), [ length(tt), 1 ] ) ];

    ss = R(j).RadComp(:,tt);
    speed = [ speed; ss(:) ];
           
    % Some bookkeeping about radials that go into each fit
    Toma.OtherTemporalVars.OMA_NumRadialsPerSite(j,i) = sum(isfinite(ss(:)));
    
    % errors
    if strcmp('radials',p.error_type)
      ee = R(j).Error(:,tt);
      err = [ err; ee(:) ];
    end
  end
    
  % Number of sites contributing
  ns = sum( Toma.OtherTemporalVars.OMA_NumRadialsPerSite(:,i) > 0 );
  
  % Continue if possible number of sites is too small.
  if ns < 1, continue, end
  
  % More bookkeeping
  Toma.OtherTemporalVars.OMA_NumRadSites(i) = ns;
  
  % Actually do fits.
  if strcmp('constant',p.error_type)
    err = 1;
  end
  if strcmp('none',p.error_type) % No errors
    alpha = openMA_modes_fit_NaNs( uux, uuy, p.K * homogeneous_matrix, ...
                                   radians(head), speed, weights );
  else % Calculate errors
    [alpha,cov_alpha] = openMA_modes_fit_with_errors_NaNs( ...
        uux, uuy, p.K * homogeneous_matrix, ...
        radians(head), speed, weights, err );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save error information.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save cov_alpha
    if nargout > 1
      OMA_cov_alpha(:,i) = cov_alpha(:);
    end
    % The above reshape is a bit weird, but necessary to make things work.
    % Basically each square covariance matrix gets turned into a long
    % vector. To use this, one would need to undo the reshape.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save error information.
    % This calculates errors and covariances a quicker way than
    % direct matrix multiplication.  Can do this because 
    % we are not interested in the full covariance matrix.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ca = ( cov_alpha * g.ux_interp_grid' )';
    Toma.ErrorEstimates.Uerr(:,i) = sum( g.ux_interp_grid .* ca, 2 );
    
    Toma.ErrorEstimates.UVCovariance(:,i) = sum( g.uy_interp_grid .* ca, 2 );
    
    ca = ( cov_alpha * g.uy_interp_grid' )';
    Toma.ErrorEstimates.Verr(:,i) = sum( g.uy_interp_grid .* ca, 2 );

    clear ca cov_alpha
    
  end
  
  Toma.OtherTemporalVars.OMA_alpha(:,i) = alpha;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calc interpolated currents for all times at once
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Toma.U = g.ux_interp_grid * Toma.OtherTemporalVars.OMA_alpha;
Toma.V = g.uy_interp_grid * Toma.OtherTemporalVars.OMA_alpha;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate total errors now that we are done with fits.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch p.error_type
  case {'constant','radials'}
    Toma.ErrorEstimates.TotalErrors = sqrt( norm_covariance_matrix( ...
        Toma.ErrorEstimates.Uerr, Toma.ErrorEstimates.Verr, ...
        Toma.ErrorEstimates.UVCovariance ) );  

    Toma.ErrorEstimates.Type = [ 'OMA_from_radials, error_type=' p.error_type ...
                   ];
end

% Set error units to unitless if 'constant' error type
switch p.error_type
  case 'constant'
    [Toma.ErrorEstimates(k).UerrUnits,Toma.ErrorEstimates(k).VerrUnits, ...
     Toma.ErrorEstimates(k).UVCovarianceUnits] = deal('unitless_velocity^2');
    Toma.ErrorEstimates(k).TotalErrorsUnits = 'unitless_velocity';
end

% ALL DONE
disp( [ 'Finishing ' mfilename ' @ ' datestr(now) ] );
disp( [ 'Total time for ' mfilename ': ' num2str(toc/60) ' minutes' ] );
