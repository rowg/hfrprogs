function [Toma,OMA_cov_alpha] = fit_OMA_modes_to_totals( T, eS, modes_fn, interp_fn, K )
% FIT_OMA_MODES_TO_TOTALS  Do OMA fit to totals data.
%
% Usage: [TUVoma,OMA_cov_alpha] = fit_OMA_modes_to_totals( TUV, error_type, modes_filename, ...
%                                          interp_filename, K )
%
% Inputs
% ------
% TUV = TUV structure containing the total currents data.  Can contain
%       multiple time steps.
% error_type = string name of the type of error in TUV.ErrorEstimates to
%              use for error propagation.  If empty, no error propagation
%              will be attempted and OMA_cov_alpha will be empty.
% modes_filename = name of file where OMA modes information is stored.
% interp_filename = name of file where interpolation of OMA modes to points
%                   where totals data will be calculated is kept. If
%                   absent or empty, it is assumed this is the same as
%                   the modes_filename.
% K = Value of the "homogenization" constant in the fit.  See the openMA
%     toolbox for more details on this.  If absent or empty, defaults to
%     0.
%
% Outputs
% -------
% TUVoma = A TUV structure containing the results of the fit.  Will contain
%          extra metadata, including TUVoma.OtherTemporalVars.OMA_alpha.
% OMA_cov_alpha = a matrix of error covariances among the coefficients in
%                 OMA_alpha.  This is not normally included in the metadata
%                 as this matrix can be very very large, but this
%                 information will be necessary if error propagation at
%                 locations other than those in the grid in the
%                 interp_filename file.  The result will be a two
%                 dimensional matrix with one column for each timestep
%                 and the number of rows equal to (number of modes)^2.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: fit_OMA_modes_to_totals.m 460 2007-07-20 19:24:22Z dmk $	
%
% Copyright (C) 2006 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist( 'K', 'var' ) || isempty(K)
  K = 0;
end

if ~exist( 'interp_fn', 'var' ) || isempty(interp_fn)
  interp_fn = modes_fn;
end

% Fail if no data found.
if isempty(T.U), error( 'No data found.' ); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find out which errors to propagate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty( eS )
  eI = strmatch( eS, { T.ErrorEstimates.Type }, 'exact' );
  
  if isempty( eI )
    error( [ 'Could not find error type ''' eS ''' for error propagation.' ] );
  end
  
  if numel(eI) > 1, warning( 'Multiple errors of that type found.' ); end
  
  eI = eI(1);
else
  eI = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load in modes data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic needed files
m = load( modes_fn, 'pLonLat', 't', 'ux_tri', 'uy_tri' );
load( modes_fn, 'homogeneous_matrix' );
g = load( interp_fn, 'ux_interp_grid', 'uy_interp_grid', 'gridLonLat' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create an empty TUV structure for storing result now.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DIM = [ size( g.gridLonLat, 1 ), size(T.U,2) ];
Toma = TUVstruct( DIM, double(isempty(eI)) );
Toma.Type = 'OMA';

% Copy relevant stuff over from original totals data
Toma.DomainName = T.DomainName;
Toma.CreationInfo = T.CreationInfo;
Toma.TimeStamp = T.TimeStamp;
Toma.TimeZone = T.TimeZone;
Toma.ProcessingSteps = T.ProcessingSteps;

% Add processing steps
Toma.ProcessingSteps{end+1} = mfilename;

% Put grid in place
Toma.LonLat = g.gridLonLat;

% Save some additional metadata
Toma.OtherMetadata.(mfilename).K = K;
Toma.OtherMetadata.(mfilename).error_type = eS;
Toma.OtherMetadata.(mfilename).modes_filename = modes_fn;
Toma.OtherMetadata.(mfilename).interp_filename = interp_fn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare for fit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Interpolate modes at positions of data - faster to do it now, rather
% than with openMA_modes_fit_NaNs.
[ux,uy] = pdeintrp_arbitrary( T.LonLat, m.pLonLat, m.t, m.ux_tri, m.uy_tri );
clear m

% Thetas
thU = zeros(size(T.U));
thV = repmat(pi/2,size(T.V));

% Weights - none currently
weU = [];
weV = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do fit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(eI)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Create the covariance matrix for error propagation
  % NOTE: This has the potential to create VERY LARGE
  % matrices.  This may limit the use of this function
  % for multiple timesteps.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  s = size(T.ErrorEstimates(eI).Uerr);
  covm = repmat( NaN, [ 2*s(1), 2*s(1), s(2) ] );
  for k = 1:size(covm,3)
    covm(:,:,k) = [ diag( T.ErrorEstimates(eI).Uerr(:,k) ), ...
                    diag( T.ErrorEstimates(eI).UVCovariance(:,k) ); ...
                    diag( T.ErrorEstimates(eI).UVCovariance(:,k) ), ...
                    diag( T.ErrorEstimates(eI).Verr(:,k) ) ];
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do fit.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [alpha, cov_alpha] = openMA_modes_fit_with_errors_NaNs( ...
      [ux;ux], [uy;uy], K * homogeneous_matrix, ...
      [thU; thV], [T.U; T.V], [weU; weV], covm );

  clear covm
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save error information.
  % This calculates errors and covariances a quicker way than
  % direct matrix multiplication.  Can do this because 
  % we are not interested in the full covariance matrix.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for i = 1:size(cov_alpha,3)
    ca = ( cov_alpha(:,:,i) * g.ux_interp_grid' )';
    Toma.ErrorEstimates.Uerr(:,i) = sum( g.ux_interp_grid .* ca, 2 );
    
    Toma.ErrorEstimates.UVCovariance(:,i) = sum( g.uy_interp_grid .* ca, 2 );
    
    ca = ( cov_alpha(:,:,i) * g.uy_interp_grid' )';
    Toma.ErrorEstimates.Verr(:,i) = sum( g.uy_interp_grid .* ca, 2 );
  end
  
  % Save cov_alpha
  if nargout > 1
    OMA_cov_alpha=reshape(cov_alpha,[size(cov_alpha,1)^2,size(cov_alpha, 3)]);
  end
  % The above reshape is a bit weird, but necessary to make things work.
  % Basically each square covariance matrix gets turned into a long
  % vector. To use this, one would need to undo the reshape.
  
  clear ca cov_alpha
  
  Toma.ErrorEstimates.TotalErrors = sqrt( norm_covariance_matrix( ...
      Toma.ErrorEstimates.Uerr, Toma.ErrorEstimates.Verr, ...
      Toma.ErrorEstimates.UVCovariance ) );  

  Toma.ErrorEstimates.Type = 'OMA_from_totals';
else
  % Do fit.
  alpha = openMA_modes_fit_NaNs( ux, uy, K * homogeneous_matrix, thU, ...
                                 T.U, weU, thV, T.V, weV );
  if nargout > 1
    cov_alpha = [];
  end
end

% Save alpa and cov_alpha
Toma.OtherTemporalVars.OMA_alpha = alpha;

% Calc interpolated currents
Toma.U = g.ux_interp_grid * alpha;
Toma.V = g.uy_interp_grid * alpha;

% Calc currents at data points - this is useful for diagnostics
% Currently commented out as this takes up disk space.
%Toma.OtherTemporalVars.U_data_points = ux * alpha;
%Toma.OtherTemporalVars.V_data_points = uy * alpha;

