function r = radians(d)

%RADIANS  Converts degrees to radians.
%	
%  r = radians(d) will convert d (which can be
%      a scalar or matrix of degrees) to radians.
%

%	MIKE COOK - NPS Oceanography Dept. - v1.0 MAY94

r = d .* pi ./ 180;
