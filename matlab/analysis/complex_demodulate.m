function r = complex_demodulate( ts, f, B, A, filt_func, varargin )
% COMPLEX_DEMODULATE  Complex demodulation using a low pass filter.
%
% Usage: res = complex_demodulate( time_series, frequency, B, A, filt_func );
%
% frequency should be in the same units as time series (i.e. if time series
% is hourly, frequency should be in inverse hours).  frequency can also be a
% row vector with as many elements as columns in time_series, in which case
% a different frequency will be used for each column.  filt_func defaults to
% @filttappered.  If time_series is a matrix with many columns, then it
% operates over columns.
%
% This function won't work on time_series arrays with more than 2
% dimensions.
%
% res is a structure with the following components:
%
%   semimaj = amplitude of major axis
%   semimin = amplitude of minor axis ( if time_series is complex )
%   inc = inclination of major axis with respect to real no. line (if complex)
%   phase = phase of time series (in radians).
%
% NOTE: Calculation of the inclination is a hack and I am not sure if
% phase is correctly calculated.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: complex_demodulate.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5
  filt_func = 'filttappered';
end

f = f(:)';
s = size(ts);

f = exp( - 2 * pi * (0:s(1)-1)' * f * i );

rp = feval( filt_func, B, A, ts .* repmat( f, s ./ size(f) ), varargin{:} );
rm = feval( filt_func, B, A, ts .* repmat( conj(f), s ./ size(f) ), varargin{:} ); 

r.semimaj = abs(rp) + abs(rm);
r.semimin = abs(rp) - abs(rm);
r.inc = mod((angle(rp) + angle(rm))/2,pi); 
r.phase = (angle(rp) - angle(rm))/2; 
