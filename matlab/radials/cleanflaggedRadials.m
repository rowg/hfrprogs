function [R,I] = cleanflaggedRadials(R,rmflg)
% CLEANFLAGGEDRADIALS  Remove radial current measurements with specific
% flags in VFLG (vector flag)
%
% Usage: [RADIALclean,I] = cleanflaggedRadials(RADIALorig,rmflg)
%
% Bad radial current measurements will be replaced with NaN.
%
% Inputs
% ------
% RADIALorig = a RADIAL structure to be cleaned.  Can be an array of
%              radial structures.
% rmflg = an array of flag values (binary) to exclude (default if not 
%              provided: only remove 128/flagged AngSeg).
%
% Outputs
% -------
% RADIALclean = Cleaned RADIAL structure
% I = Index of data points that were removed.  This will have a zero for
%     good data, a 1 for data failing the vector flag.  If RADIALorig
%     was an array of radial structures, then this will be a cell array
%     with one element for each element of RADIALorig.
% 



if(nargin==1)
    rmflg=128;
end

if numel(R) > 1
  I = cell(size(R));
  for k = 1:numel(R)
    [R(k),I{k}] = cleanflaggedRadials( R(k), rmflg );
  end
  return
end


vflg=R.VectorFlag;
vflgmax=max(vflg);

rmflg(rmflg>vflgmax)=[];
if(isempty(rmflg))
    I=zeros(size(R.VectorFlag));
    fprintf('No vectors flagged to be removed.\n')
    return;
end

rmflgcol=log2(rmflg)+1;

flagbin=0:floor(log2(vflgmax));
flagbin=2.^flagbin;

vflgbin=zeros(length(vflg),length(flagbin));

for n=length(flagbin):-1:1
    indflg=vflg>=flagbin(n);
    vflgbin(indflg,n)=1;
    vflg(indflg)=vflg(indflg)-flagbin(n);
end

if(any(vflg(~isnan(vflg))~=0))
    fprintf(2,'VFLG not recognized as binary. No data removed.\n')
    return;
end

vflgbin=vflgbin(:,rmflgcol);
vflgbin=max(vflgbin,[],2); 

% Index
I = vflgbin>0;

% Clean data
if(sum(I)>0)
    for m = RADIALmatvars
       R.(m{:})(I) = NaN;
    end
end

% Add processing steps
R.ProcessingSteps{end+1} = mfilename;
