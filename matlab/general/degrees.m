function d = degrees(r)

%DEGREES  Converts radians to degrees.
%
%  d = degrees(r) will convert r (which can be
%      a scalar or matrix of radian values) to degrees.
%

%	MIKE COOK - NPS Oceanography Dept. - v1.0 MAY94

d = 180 .* r ./ pi;
