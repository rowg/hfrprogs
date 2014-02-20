function anglemean = angles_mean(angles)
% A function to calculate the mean of a set of angles (0 - 360 degree
% convention).  The angle calculated is the average angle.  The argument
% angles should be in degrees and ranging from 0 - 360.  
%
% Example ang = angles_mean([2, 0, 358]) --> ang = 0.

% From Lev Shulman - modified by M. Cook to handle matrices - Dec 04.

% NOTE FROM DMK: This function only works approximately for small ranges
% of angles.  For example, angles_mean([0,0,90]) ~= 30!

%radang = deg2rad(angles);
radang = radians(angles);

%anglemean = rad2deg(atan2(sum(sin(radang)),sum(cos(radang))));
anglemean = degrees(atan2(sum(sin(radang)),sum(cos(radang))));

% Change to handle matrices - MC
% if(anglemean < 0)   % range of atan2 is -pi <= x <= pi
%     anglemean = 360 + anglemean;
% end
% Use mod instead - it is vectorized.
anglemean = mod(anglemean,360);

return;