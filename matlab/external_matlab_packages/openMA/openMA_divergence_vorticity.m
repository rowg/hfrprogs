function [ div, vor ] = openMA_divergence_vorticity( varargin )
% OPENMA_DIVERGENCE_VORTICITY - computes divergence and vorticity from a
% set of modes and mode coefficients at a series of coordinates.
%
% Usage: [div,vor] = openMA_divergence_vorticity( vfm, dfm, bm, alpha ) 
%        [div,vor] = openMA_divergence_vorticity( cc, vfm, dfm, bm, alpha ) 
%        DV = openMA_divergence_vorticity( vfm, dfm, bm ) 
%
% vfm, dfm and bm are the vorticity-free, divergence-free and boundary mode
% structures produced by the openMA_pdetool solver functions. cc is a two
% (or three) column matrix of coordinates (in the dimensions of the modes
% themselves).
%
% In the first form, it is assumed that all modes are on the same grid
% and that you want the divergence and vorticity on the triangular grid
% (which can then be interpolated to another grid using
% pdeintrp_arbitrary if desired).
%
% In the second form, it is assumed that all modes are on different grids
% and that you want the divergence and vorticity at the points in cc.  In
% this case, cc should have the format desired by openMA_modes_interp.
%
% vfm, dfm or bm can be empty arrays, but must be given.
%
% If only boundary modes are supplied, then just a scalar divergence and
% vorticity will be returned as divergence is constant over space in this
% case.
%
% If only one output argument is requested, then the return argument, DV, is
% a two row matrix with the coefficients for calculating the divergence and
% vorticity.  This is useful if you want to calculate divergence and
% vorticity for modes that have already been interpolated, or for
% calculating the errors in the divergence and vorticity.  Remember that
% boundary mode divergence is uniform over space.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: openMA_divergence_vorticity.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find out type of input arguments - mode structures or matrices
if ~isa(varargin{1},'struct') & ~isempty( varargin{1} )
  cc = varargin{1};
  varargin = varargin(2:end);
end

% Mode structures
mm = varargin(1:3);

% Calculate DV and return if just one output arg.
dv = getdivvor( mm{:} );
if nargout == 1
  div = dv; 
  return
end

% Get alpha
alpha = varargin{4};

% Interpolate modes on grid if need be.
if exist('cc','var')
  warning off
  uu = openMA_modes_interp( cc, mm{1:2} );
else  
  warning off
  uu = openMA_modes_group_same_grid( mm{1:2} );
end

% Use ones for boundary modes stuff as they are uniform over space.
nb = length(mm{3});
uu(:,end+1:end+nb) = 1;

% Calculate divergence and vorticity
div = uu * diag(dv(1,:)) * alpha;
vor = uu * diag(dv(2,:)) * alpha;

%%%-----------Subfunctions-------------%%%
function dv = getdivvor( nm, dm, bm )

% Negative sign is to account for a difference in the definition of the
% eigenvalue between the PDETOOL ( -laplacian(phi) = lambda*phi ) and
% what is used in the papers ( laplacian(phi) = lambda*phi ).

try, nm = -1 * horzcat( nm.lambda ); end % nm should be empty in this case
try, dm = -1 * horzcat( dm.lambda ); end % dm should be empty in this case
try, bm = horzcat( bm.laplacian ); end % bm should be empty in this case

dv = [ zeros(2,0), ...
       [ nm; zeros(size(nm)) ], ...
       [ zeros(size(dm)); dm ], ...
       [ bm; zeros(size(bm)) ] ...
     ];
