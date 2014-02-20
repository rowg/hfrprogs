function [rotU,rotV] = rotUV(u,v,angle)
%ROTUV  Translate (rotate) coordinate axis an input number of degrees
%
% USAGE:
%   [rotU, rotV] = rotUV(u,v,angle)
%
% Will rotate the u/v data angle number of degrees, passed back to the
% calling program as rotU/rotV.
%
% Example: [rotU, rotV] = rotUV(1,0,90)
% This will return rotU = 0, rotV = 1.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2007 David M. Kaplan and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Mike Cook - NPS Oceanography Dept., Monterey CA
% 8 APR 99
%
% DMK - I have modifed this a bit.  In particular, rotUV now adds angles
% to original angle of the vector.

c = cos(radians(angle));
s = sin(radians(angle));

rotU = u .* c - v .* s;

if nargout > 1
  rotV = u .* s + v .* c;
end
