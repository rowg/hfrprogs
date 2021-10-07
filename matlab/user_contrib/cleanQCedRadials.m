function [R,I] = cleanQCedRadials(R,varargin)
% CLEANQCEDRADIALS  Remove radial current measurements with specific
% flags as identified in input
%
% Usage: [RADIALclean,I] = cleanQCedRadials(RADIALorig,'testID',[values to remove],'testID',[values to remove],...)
%
% Bad radial current measurements will be replaced with NaN.
%
% Tests that data is filtered on are included as a note in
%       R.ProcessingSteps; any tests requested but not included in the
%       radial file are ignored but noted in R.ProcessingSteps
%
% Inputs
% ------
% RADIALorig = a RADIAL structure to be cleaned.  Can be an array of
%              radial structures.
% 'testID' = QC test ID as listed in radial file 'TableColumnTypes';
%              Can also replace with 'all: pattern' to filter on any fields
%              in file that meet the given pattern (ie 'all: *QC' would
%              filter on any fields ending in 'QC')
% [values to remove] = array (or single digit) of flag values under test
%              listed as immediately previous input that data will be
%              removed for (will usually correspond with QARTOD flag
%              meanings: 1=pass, 2=not evaluated, 3=suspect, 4=fail, 9=not
%              evaluated, and will most likely usually be [3 4] or 4)
%
% Outputs
% -------
% RADIALclean = Cleaned RADIAL structure
% I = Index of data points that were removed.  This will have a zero for
%     good data, a 1 for data failing the vector flag.  If RADIALorig
%     was an array of radial structures, then this will be a cell array
%     with one element for each element of RADIALorig.

if(iscell(varargin{1})&length(varargin)==1)
    varargin=varargin{1};
end

if ~isequal(mod(length(varargin),2),0)
    error('Invalid number of test,flag options specified.');
end


if numel(R) > 1
  I = cell(size(R));
  for k = 1:numel(R)
    [R(k),I{k}] = cleanQCedRadials( R(k), varargin );
  end
  return
end

if nargin < 2
    warning('No tests provided to filter on.')
    I=false(size(R.VectorFlag));
    R.ProcessingSteps{end+1} = [mfilename '; no tests provided to filter data on.'];
    return
end
    

I=false(size(R.VectorFlag));
donetests=[];
skiptests=[];

if(length(varargin)==2&strncmpi(varargin{1},'all:',4))
    flags=varargin{2};
    testexp=varargin{1};
    testexp=testexp(5:end);
    testexp(testexp==' ')=[];
    if(testexp(1)=='*')
        if(testexp(end)=='*')
            wildtype='anywhere';
        else
            wildtype='end';
        end
    elseif(testexp(end)=='*')
        wildtype='start';
    else
        wildtype='none';
    end
    testexp(testexp=='*')=[];
    vars=fieldnames(R);
    if(strcmp(wildtype,'none'))
        ind=find(strcmp(vars,testexp));
    else
        vars_exp=regexp(vars, testexp);
        ind=find(~cellfun(@isempty,vars_exp));
    end
    for x=1:length(ind)
        if(strcmp(wildtype,'start')&vars_exp{ind(x)}~=1)
            continue;
        end
        if(strcmp(wildtype,'end')&vars_exp{ind(x)}~=length(vars{ind(x)})-length(testexp)+1)
            continue;
        end
        test=vars{ind(x)};
        I(ismember(R.(test),flags))=true;
        donetests=[donetests,{test}];
    end
    
else
    for x = 1:2:length(varargin)
        test = varargin{x};
        flags = varargin{x+1};

        if(~isfield(R,test))
            skiptests=[skiptests,{test}];
            continue;
        end

        I(ismember(R.(test),flags))=true;
        donetests=[donetests,{test}];
    end
end

testinfo=' -';
testinfo=[testinfo ' data filtered on tests:'];
for x=1:length(donetests)
    testinfo=[testinfo ' ' donetests{x} ','];
end
if(isempty(donetests))
    testinfo=[testinfo ' none;'];
end
testinfo(end)=';';
if(~isempty(skiptests))
    testinfo=[testinfo ' flags unavailable for tests:'];
    for x=1:length(skiptests)
        testinfo=[testinfo ' ' skiptests{x} ','];
    end
end
testinfo(end)=[];


% Clean data
if(sum(I)>0)
    for m = RADIALmatvars
       R.(m{:})(I) = NaN;
    end
end

% Add processing steps
R.ProcessingSteps{end+1} = [mfilename testinfo];
