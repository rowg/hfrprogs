function [maxAngleSpread,anglePair] = angSpread(angles)
% ANGSPREAD  Finds the 2 angles with the difference between them closest to 90
% degrees.
%
% Usage: [angleSpread,anglePair] = angSpread(angles)
%
% Input:  angles (in degrees) can be n x 1 or 1 x n.  angles must
%         be in the 0 - 360 degree system.
% Output: angleSpread (in degrees) of the difference of the 2 angles
%         closest to orthogonal (90 degrees).
%         anglePair (in degrees) of the 2 angles with angleSpread described
%         above.  Note that if the input list of angles has more than 1
%         pair that have the same angleSpread, it only returns the first
%         one it finds.  
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: angSpread.m 396 2007-04-02 16:56:29Z mcook $
%
% Copyright (C) 2007 David M. Kaplan and
%                    Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Mike Cook, NPS Oceanography Dept, 07 July 2006.
%
% 7 Feb 2007 - Changed algorithm to work via dot product. Faster. DMK
%
% 6 Feb 2007 - Fixed bug where repetition elimination was done before
% checking if 2 or more angles were input.  If user input 2 angles, but
% they were the same angle, the program would eliminate one and report an
% error.  Now repetition removal is done after minimum # angle check.
% MCOOK

if size(angles(:),1) < 2
    error('%s needs at least 2 input angles ... terminating abnormally\n', ...
        mfilename);
end

% Make long vector
angles = unique(angles(:));

% Get cosine and sine of angles
c = cosd(angles(:));
s = sind(angles(:));

% Find most orthogonal via minimum dot product.  This could be achieved
% with [cc,ii] = min( c * c' + s * s' ), but this runs into memory
% problems for lots of angles.  The algorithm below with the for loop is
% safer for large numbers of angles.
cc = 1;
ii = [1 1];
for k = 1:length(c)-1
  t = abs( c(k) * c(k+1:end) + s(k) * s(k+1:end) );
  [c1,i1] = min(t);
  
  if c1 < cc
    cc = c1;
    ii = [k,k+i1];
  end
end

maxAngleSpread = acosd( min(cc(:)) );
anglePair = [ angles(ii(1)), angles(ii(2)) ];
