function [u,v,C,fitDif,CE] = tuvLS(rad_Speed,angle,raderr)
% TUVLS  Calculate total current vectors from radial currents
%
% tuvLS  - calculates the u/v components of a total vector from 2 to n
%   radial vector components.
%
% Usage:
%         [u,v,C,fitDif,CE] = tuvLS(rad_Speed,angle,raderr)
%
% Inputs:  rad_Speed - radial current speed
%          angle     - bearing angle, in degrees
%          raderr    - measure of the radial uncertainties to use in
%                      error calculation.  This can either be a vector of
%                      the same size as rad_Speed, in which case a
%                      diagonal covariance matrix is assumed for radial
%                      data, or a square matrix of covariances.  In
%                      either case, the units are assumed to be speed^2,
%                      so take care to square standard deviations before
%                      passing to this function. 
%
% Outputs:
%         u,v - the total currents
%         C - covariance matrix assuming uniform unit errors for all
%             radials (AKA GDOP)
%         fitDif - the RMS difference between the radial current and the
%                  radial current predicted by the model
%         CE - covariance matrix using specified radial error.  Only
%              returned if raderr is given and not empty.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: tuvLS.m 486 2007-09-27 15:59:08Z dmk $
% Copyright (C) 2007 David M. Kaplan and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Mike Cook - NPS Oceanography Dept.
% v 1.0 JUN 95.
% v 1.1 Apr 96.  Change the way the u and v error is calculated.
% v 2.0 AUG 98.  Add fit diff calculation, and pass back to calling program.
% v 2.1 MAR 99.  Changed the name of fitErr to fitDif
% v 3.0 27 Apr 04.  Pass radial speed and angle to function instead of
%                   calculating them from radial u/v.  This is done in
%                   another function now, since when the u=v=0 is a special
%                   case and has to be handled properly.   MC
%
% 07 Jul 2006:
%    Major changes ... better check for vector inputs, added the covariance
%    matrix C to the output list.  Calculate geometrical gdop by callin the
%    funcion gdop internally, and then putting it into the output list. -MC
%
% 07 Feb 2007: Relatively minor changes that make errors all be in units
%              of velocity^2 and have this function not return gdopmag as
%              that is now more appropriately calculated in maketuv.
%              Also, no more flipping of angles around as this isn't
%              truly necessary if everything is consistent and UVcov is
%              returned instead of full C matrix. DMK
%
% 08 Feb 2007: Adding ability to incorporate measured radial error.


%  Make sure that angle and rad_Speed are vectors
if ~isvector(rad_Speed)  ||  ~isvector(angle)
   error('%s: angle and radial velocity inputs *MUST* be vectors',mfilename);
end

if ~exist( 'raderr', 'var' ), raderr = []; end

% Make sure the vectors are column vectors.
angle = angle(:);
rad_Speed = rad_Speed(:);

% Form the angle (A) and radial_matrices
A = [ cosd(angle), sind(angle) ];

% NOTE: Passing angles in degrees instead of radians adds about 5% to the
% time for calculating totals with maketuv. -DMK

% Calculate the u and v for the total vector.
% a(1) = u  &  a(2) = v
% Note: C represents the covariance matrix.  variance(U) = C(1,1) and
%       variance(V) = C(2,2).
C = inv( (A') * A );

a = C * ( (A') * rad_Speed );
u = a(1);
v = a(2);

% Get an estimate for the model prediction of the data, ie the total
% u & v current components prediction of the radial currents.
pred = A * a;
fitDif = sqrt(mean((rad_Speed - pred) .^2));    % RMS fit difference

% Calculate errors including measured radial uncertainty
% DMK NOTE: I think this formulation is correct.  Need to check.
if ~isempty(raderr) || nargout > 4
  if isvector(raderr)
    % Faster to use repmat then matrix mult if diagonal
    CE = inv( A' * ( repmat( 1./raderr(:), [1,2] ) .* A ) );        
  else % Assume a full covariance matrix.
    CE = C * (A') * raderr * A * C'; 
  end
end
