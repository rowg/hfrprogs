function ee = norm_covariance_matrix( varargin )
%NORM_COVARIANCE_MATRIX  Error estimates based on norm of covariance matrix
%
% NORM_COVARIANCE_MATRIX - this function calculates the
% error estimates based on the norm of the covariance matrix, as
% suggested by Cedric Chavanne in:
%
% http://www.satlab.hawaii.edu/hfradar/proj/hawaii/matlab/HFRadarmap4_1/HFRadarmap.m
%
% Usage: norm = norm_covariance_matrix( C )
%        norm = norm_covariance_matrix( Uerr, Verr, UVCovariance )
%
% This function returns the maximum eigenvalue of the covariance matrix.
% In the first usage, the covariance matrix is passed directly.  In the
% second usage, the elements of a 2x2 covariance matrix are passed.  In
% this latter case, it is assumed that all arguments have the same units
% (typically something like cm2/s2).
%
% The norm returned will have the same units as the initial covariance
% matrix (i.e., no sqrt will be taken).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: norm_covariance_matrix.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 1
  ee = max( eig( varargin{1} ) ); % Works for any size matrix
else
  tr = varargin{1} + varargin{2}; % Trace
  dt = varargin{1} .* varargin{2} - varargin{3}.^2; % Determinant

  % Write in terms of trace and determinant for transparency and so that it
  % is manifestly rotation invariant.
  ee = 1/2 * ( tr + sqrt( tr.^2 - 4 * dt ) );
end
