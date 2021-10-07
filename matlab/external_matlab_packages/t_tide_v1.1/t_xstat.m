function [xstat,unit]=t_xstat(long,lat);
% function [xstation,units]=t_xstat(long,lat);
% Find the closest tidal station to location long(E), lat(N)
% xstation = character string of location.
% For use with R.Pawlowicz'z t_tide.
% RKD 05/02
load('t_xtide.mat');
slong=xharm.longitude;
slat=xharm.latitude;
stat=xharm.station;
units=xharm.units;
clear xharm xtide
%
[dist,hdg]=t_gcdist(slat,slong,lat,long);
indx=find(dist==min(dist));
if ~isempty(indx),
   xstat=stat(indx(1),1:40);
   unit=units(indx(1),:);
   disp([xstat,'   Units: ',unit]);
else
   xstat=[];
   disp('No XTide Station found.');
end
%

function [d,hdg]=t_gcdist(lat1,lon1,lat2,lon2)
% function [d,hdg]=t_gcdist(lat1,lon1,lat2,lon2)
% Function to calculate distance in kilometers and heading between two
% positions in latitude and longitude.
% Assumes -90 > lat > 90  and  -180 > long > 180
%    north and east are positive
% Uses law of cosines in spherical coordinates to calculate distance
% calculate conversion constants
raddeg=180/pi;
degrad=1/raddeg;
% convert latitude and longitude to radians
lat1=lat1.*degrad;
lat2=lat2.*degrad;
in1=find(lon1>180);lon1(in1)=lon1(in1)-360;
in2=find(lon2>180);lon2(in2)=lon2(in2)-360;
lon1=-lon1.*degrad;
lon2=-lon2.*degrad;
% calculate some basic functions
coslat1=cos(lat1);
sinlat1=sin(lat1);
coslat2=cos(lat2);
sinlat2=sin(lat2);
%calculate distance on unit sphere
dtmp=cos(lon1-lon2);
dtmp=sinlat1.*sinlat2 + coslat1.*coslat2.*dtmp;

% check for invalid values due to roundoff errors
in1=find(dtmp>1.0);dtmp(in1)=1.0;
in2=find(dtmp<-1.0);dtmp(in2)=-1.0;

% convert to meters for earth distance
ad = acos(dtmp);
d=(111.112) .* raddeg .* ad;

% now find heading
hdgcos = (sinlat2-sinlat1.*cos(ad))./(sin(ad).*coslat1);

% check value to be legal range
in1=find(hdgcos>1.0);hdgcos(in1)=1.0;
in2=find(hdgcos<-1.0);hdgcos(in2)=-1.0;
hdg = acos(hdgcos).*raddeg;

% if longitude is decreasing then heading is between 180 and 360
test = sin(lon2-lon1);
in1=find(test>0.0);
hdg(in1)=360-hdg(in1);
% fini