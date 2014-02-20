function wts=pl64(dt);
% PL64  Generate pl64 weights.
%
% Usage: weights = pl64( deltaT )
%
% PL64 filtered described in Rosenfeld, 1983
% WHOI technical report 85-35, pg.21.
%
% half power point 38 hours
% half amplitude 33 hours
%
% deltaT specifies the timestep in hours.  Defaults to 1.
%
% Steve Lentz 22 July 1992
% modified by Ed Dever to match tech report 15 April 1998
% modified by David Kaplan to just return weights and 
% deal with variable deltaT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 1, dt = 1; end

%generate filter weights
t=1:dt:64;
t=pi.*t;
den=0.0009.*t.^3;
wts=(2.*sin(0.06.*t)-sin(0.03.*t)-sin(0.09.*t))./den;
% make symmetric filter weights
% coefficient is to make sum of wts == 1
wts=0.99949687728729.*[wts(end:-1:1),0.06,wts];

% Renormalize for cases dt ~= 1.
wts = wts / sum(wts);
