function [pl33Weights] = pl33(deltaT)
% PL33  Generate pl33 weights
%
% Usage: weights = pl33( deltaT )
%
% deltaT - time series delta T in HOURS
% generate weights for pl low pass filter function
%
% Modified by David Kaplan from Steve Cook's version.

if nargin < 1
   deltaT = 1;   % use 1 hour for default delta time
   disp('Using 1 hr delta time by default')
end

ddt = deltaT;
dt = [-33:ddt:33];

% Filter function is set up for times of hours.
% Note also that the dt=0 value uses l'hopital's rule to be computed
% and is equal to 0.06;
% The weights are then normalized by the sum to have a sum of 1.

%%fname=input('Enter filename for outputing weights: ','s');
%%fid=fopen(fname,'w+');

n1=0.06;
n2=0.03;
n3=0.09;
d1=0.0009;
denom=d1.*(pi^3).*(dt.^3);
num1=2.*sin(n1.*pi.*dt);
num2=sin(n2.*pi.*dt);
num3=sin(n3.*pi.*dt);
w=(num1./denom)-((num2+num3)./denom);
ll=isnan(w);
w(ll)=0.06;
d=sum(w);
nw=w./d;

%%keyboard

%%for i=1:length(dt),
	%%fprintf(fid,'%f\n',nw(i));
%%	pl33Weights(i) = nw(i);
%%end
%%fclose(fid);

pl33Weights = nw(:);

