function [angVector] = angleVector(ll,incr,ul)
%ANGLEVECTOR  Generate a vector of angles from user specified angle limits.
%
% USAGE:
%        [angVector] = angleVector(lowerlim,incr,upperlim)
%        [angVector] = angleVector(lowerlim,upperlim)
%
%   lowerlim - the lower angle of the angle range in degrees (though see
%              below about ranges crossing 0 )
%            
%   incr - the angle increment.  If two arguments are passed to function,
%          incr will have a default = 5 degrees.
%
%   upperlim - the upper angle of the angle range in degrees (though see
%              below about ranges crossing 0 )
%
% OUTPUT:
%   angVector - a 1 x N vector of angles starting at lowerlim and moving
%               counterclockwise (in normal cartesian sense of angles) to
%               upperlim with an increment of incr.
%           
%   The angle limits can go across 0 degrees and the final angVector will
%   always have angles between 0 and 360.
%           Examples of the lims vector, and the angVector created are:
%           [0,190]   creates: 0, 5, 10, ... 190.
%           [260,320] creates: 260, 265, ... 320
%           [320,260] creates: 320, 325, ... 355, 0, 5, ... 260
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2007 David M. Kaplan and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Angle increment set to 5 degrees if not supplied
if nargin < 3
  ul = incr;
  incr=5;
  % warning('%s: setting angle increment to default %d degrees\n', ...
  %        mfilename,incr);
end

if ll > ul
  n = ceil( (ll-ul)/360 );
  angVector = ll:incr:ul+n*360;
else
  angVector = ll:incr:ul;
end

angVector = mod(angVector,360);
