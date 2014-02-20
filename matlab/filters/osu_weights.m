function osu=osu_weights(npcf,itotfl);
% OSU_WEIGHTS  Generate OSU weights.
%
% Usage: weights = osu_weights( cutoff_point, filter_length )
%
% OSU filter described in Rosenfeld, 1983
% WHOI technical report 85-35.
%
% modified after Lentz's pl64mat.m Ed Dever 26 April 1994
% modified by David Kaplan (2003) to just return weights.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%generate filter weights
osu = zeros(itotfl,1);
a = 2*pi;
nspan = floor((itotfl-1)/2);
i = (0:nspan)';
b = i/npcf;
c = i/(nspan+1);
m = length(c);
d = zeros(length(c),1);
d(1) = 1;
d(2:m) = sin(a*b(2:m))./(a*b(2:m));
e = (ones(m,1) + cos(pi*c)).*d;
f = 0.5*e;
ind = nspan + i + 1;
osu(ind) = f;
ind2 = nspan - i + 1;
osu(ind2) = f;
nsum = sum(osu(1:itotfl));
osu = osu./nsum;
