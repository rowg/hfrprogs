function C = gdop_max_orthog(angles)
%GDOP_MAX_ORTHOG  Compute GDOP using most orthogonal vectors
%
% Usage:
%        C = gdop_max_orthog(angles)
%
% Input:  angles (in degrees), vector of angles, 1xN or Nx1.
% Output: C - the GDOP covariance matrix.  The sqrt of the trace of this
% matrix is what has traditionally been referred to as the mapping error.
%
% Calculate the GDOP based on equations 9-14 described in "Shipborne
% Measurement of Surface Current Fields by HF Radar" by K.-W. Gurgel, 1994.
% C (covariance) matrix in equation (13) of Gurgel paper reduces to GDOP if 
% variances of the radial components are set to 1, and only the 2 most 
% orthogonal angles are used.
%
% Call angSpread internally to determine 2 most orthogonal angles from a 
% list of 2 or more angles.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: gdop_max_orthog.m 405 2007-04-12 00:12:33Z dmk $
%
% Copyright (C) 2007 David M. Kaplan and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Calculate C using only the 2 angles of maximum orthogonality.
[maxAngSpr,angPair] = angSpread(angles);

% Form the angle matrix A.
A = [ cosd(angPair(:)), sind(angPair(:)) ];
C = inv( (A') * A);
