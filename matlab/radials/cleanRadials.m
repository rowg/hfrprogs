function [R,I] = cleanRadials(R,maxspd)
% CLEANRADIALS  Remove radial current measurements exceeding a speed threshold
%
% Usage: [RADIALclean,I] = cleanTotals(RADIALorig,maxspd)
%
% Bad radial current measurements will be replaced with NaN.
%
% Inputs
% ------
% RADIALorig = a RADIAL structure to be cleaned.  Can be an array of
%              radial structures.
% maxspd = a maximum radial speed cutoff.  It can also be a double array
%          of the same size as RADIALorig.
%
% Outputs
% -------
% RADIALclean = Cleaned RADIAL structure
% I = Index of data points that were removed.  This will have a zero for
%     good data, a 1 for data whose speed is above maxspd.  If RADIALorig
%     was an array of radial structures, then this will be a cell array
%     with one element for each element of RADIALorig.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: cleanRadials.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with case of multiple radial structures.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if numel(R) > 1
  if prod(size(maxspd)) == 1
    maxspd = repmat( maxspd, size(R) );
  end
  
  I = cell(size(R));
  for k = 1:numel(R)
    [R(k),I{k}] = cleanRadials( R(k), maxspd(k) );
  end
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now for a single radial structure.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add processing steps
R.ProcessingSteps{end+1} = mfilename;

% Index
I = abs(R.RadComp) > maxspd;

% Clean data
for m = RADIALmatvars
  R.(m{:})(I) = NaN;
end

% Now save metadata
R.OtherMetadata(1).(mfilename).maxspd = maxspd;
