function Xout = t_predic_matrix( t, ts, varargin )
% T_PREDIC_MATRIX  Tidal prediction of matrices of time series
%
% This function works identical to t_predic except that tidal
% constituents information can only be specified through an array of tide
% structures as produced by t_tide_matrix.
% 
% Usage: Xout = t_predic_matrix( TIM, TIDESTRUC, property,value,... )
%
% Inputs
% ------
% TIM = Column vector of times in datenum format to make predictions
% TIDESTRUC = an array of tide structures for making predictions
% property,value,... = parameter name,value pairs for t_predic.  See that
%                      function for details.  NOTE: Any of these can be a
%                      cell array, in which case it must have the same
%                      number of elements as TIDESTRUCT (i.e., the same
%                      number of columns as Xout), one of which will be
%                      used for predicting each column.
%
% Outputs
% -------
% Xout = predicted tides.  Each column of Xout will be the prediction for
%        an element of the TIDESTRUC array of structures.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: t_predic_matrix.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t = t(:);
Xout = repmat( NaN, [ numel(t), numel(ts) ] );

% Find cell arrays in variable arguments
for k = 1:numel(varargin)
  I(k) = iscell(varargin{k});
end
I = find(I);

for k = 1:numel(ts)
  v = varargin;
  for ii = I
    v{ii} = v{ii}{k};
  end
  if ~isempty( ts(k).tidecon )
    Xout(:,k) = t_predic( t, ts(k), v{:} );
  end
end
