function trueDir = math2true(mathDir)
%MATH2TRUE  Converts angle in degrees from the math system to the true system.
%
%  TRUEDIR = MATH2TRUE(MATHDIR) converts angle in degrees from the math
%  convention to the true, or compass convention.
%  true convention is the direction of a vector angle measured in degrees 
%  cw from north, where north = 0 degrees, east = 90 degrees, etc.  This is
%  also commonly referred to as compass angle.
%  I call the math convention, for lack of a better term, the direction of a
%  vector angle measured in degrees ccw from east, where east = 0 degrees,
%  north = 90 degrees, etc.
%
% NOTE:  It is assumed that the angles are in degrees 0 <= angle <= 360.
%
%  See also UV2SPDIR, TRUE2MATH, SPDDIR2UV, MET2OC. 
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%  Mike Cook - NPS Oceanography Dept., OCT 96
%  v 1.1 - changed find code to mod code, APR 99.

trueDir = 90 - mathDir;
trueDir = mod(trueDir,360);
