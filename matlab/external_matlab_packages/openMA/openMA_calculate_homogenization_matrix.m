function K = openMA_calculate_homogenization_matrix( varargin )
% OPENMA_CALCULATE_HOMOGENIZATION_MATRIX - calculates homogenization term
% for fitting data to modes that is simply the square of the maximum current
% for each mode.
%
% Usage: K = openMA_calculate_homogenization_matrix( mode_struc1,
%                                                    mode_struc2, ... )
%        K = openMA_calculate_homogenization_matrix( [ mode_struc1,
%                                                    mode_struc2, ... ] )
%
% K will actually be a vector of diagonal elements.  This format is
% appropriate for using in openMA_modes_fit (after multiplying it
% by a scalar weight).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_calculate_homogenization_matrix.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate max velocity for each mode.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nn = 0; % Start counter

K = [];

try 
  nm = [ varargin{:} ];
catch
  error( 'Mode structures must all have the same format.' );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over modes and calc max vel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(nm)
  [uux,uuy] = pdegrad( nm(k).p, nm(k).t, nm(k).u );
  
  nn = nn + 1;
  K(nn) = max( uux.^2 + uuy.^2 );
end

