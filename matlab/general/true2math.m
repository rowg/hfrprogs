function mathDir = true2math(trueDir)
%TRUE2MATH  Converts angle in degrees from the true system to math system.
%
%  MATHDIR = TRUE2MATH(TRUEDIR)  converts angle in degrees from the true
%  convention to the math convention.
%  I call the math convention, for lack of a better term, the direction of a
%  vector angle measured in degrees ccw from east, where east = 0 degrees,
%  north = 90 degrees, etc.
%  true convention is the direction of a vector angle measured in degrees 
%  cw from north, where north = 0 degrees, east = 90 degrees, etc.  This is
%  also commonly referred to as compass angle.
%
%  NOTE:  It is assumed that the angles are in degrees 0 < angle < 360.
%
% See also MATH2TRUE, SPDDIR2UV, UV2SPDIR, MET2OC.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%  Mike Cook - NPS Oceanography Dept., OCT 96
%  v 1.1 - replaced find code with mod code - apr 99.

mathDir = 90 - trueDir;
mathDir = mod(mathDir,360);
