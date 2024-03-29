function RADIAL = loadRDLFile_all(filename, saverawdata, warnfunc )
% LOADRDLFILE  Loads an RDL file into a RADIAL structure
%
% Usage: RADIAL = loadRDLFile( filename, saverawdata, warnfunc )
%
% This function loads the information from a RDL radial currents files
% into a RADIAL structure (as described by RADIALstruct.m).  No cleaning
% or interpolation of the radials is done.  Angles are converted from
% clockwise from north=0 to counterclockwise east=0.  Angles continue to
% be measured in degrees.
%
% Inputs
% ------
% filename = string name of file to be loaded.  Can also be a cell array
%            of strings with several filenames.  In this case, the
%            resulting structure will be an array of RADIAL structures,
%            one for each filename.
% saverawdata = boolean indicating whether or not to save the raw
%               original data in the OtherMetadata.RawData.  Defaults to
%               false.
% warnfunc = string name of function to execute when a critical problem is
%            found in a RDL file (e.g., missing data columns).  Typically
%            would be 'warning' or 'error', but could be some more
%            complicated function that reacts differently to different types
%            of problems. Defaults to 'warning'.
% Outputs
% -------
% RADIAL = radial structure with results.
%
% REQUIRED NON-STANDARD MATLAB FUNCTION(S): true2math, strparser,
% getNameValuePair, getRDLHeader, RADIALstruct
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: loadRDLFile.m 639 2008-04-17 20:40:33Z cook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('saverawdata','var')
  saverawdata = false;
end

if ~exist('warnfunc','var')
  warnfunc = 'warning';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal first with case of multiple filenames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isa(filename,'cell')
  RADIAL = RADIALstruct(length( filename ));
  
  for k = 1:length(filename)
    n = RADIAL(k).SiteCode;
    
    newRad = loadRDLFile_all( filename{k}, saverawdata, warnfunc );
    newfields=setdiff(fieldnames(newRad),fieldnames(RADIAL));
    for nf=1:length(newfields)
        for nr=1:length(RADIAL)
            RADIAL(nr).(newfields{nf})=[];
        end
    end
    newfields=setdiff(fieldnames(RADIAL),fieldnames(newRad));
    for nf=1:length(newfields)
        newRad.(newfields{nf})=[];
    end
    RADIAL(k) = newRad;
    RADIAL(k).SiteCode = n;
  end
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now deal with case of a single filename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp( [ 'Processing filename: ' filename ] );

RADIAL = RADIALstruct;
RADIAL.FileName = {filename};

% Give TimeStamp and matvars same size as FileName for consistency just
% in case we return early.
RADIAL.TimeStamp = NaN;
for m = RADIALmatvars
  RADIAL.(m{:}) = zeros(0,1);
end

% Get data
[Data,tttt,C] = loadDataFileWithChecks( filename );

% Generally save extra info if interesting
if C > 0
  RADIAL.OtherMetadata.loadDataFileWithChecks_CODE = C;
  RADIAL.OtherMetadata.loadDataFileWithChecks_TEXT = tttt;
end

% Check possible cases for failure to get data
if C >= 1e10 % Improbable that this should occur
  feval( warnfunc, [ mfilename ':UNKNOWN_DATA_TYPE' ], ...
         [ 'File of strange type.' ] );
  return
elseif C >=1e3
  feval( warnfunc, [ mfilename ':FILE_UNLOADABLE' ], ...
         [ filename ' could not be loaded.' ] );
  return
elseif C >= 1e2
  feval( warnfunc, [ mfilename ':FILE_NOT_FOUND' ], ...
         [ filename ' could not be found.  Returning empty radial ' ...
           'structure.' ] );
  return
elseif C >= 10
  feval( warnfunc, [ mfilename ':NO_DATA_IN_FILE' ], ...
         [ filename ' had no data.' ] );
elseif C >= 1 % This should have failed already
  feval( warnfunc, [ mfilename ':DATA_MATRIX_GIVEN' ], ...
         'Data matrix given - not valid input.' );
  return
end

% Get header
[RADIAL.OtherMetadata.Header,names,values] = getRDLHeader( filename );

% Save data if desired
if saverawdata
  RADIAL.OtherMetadata.RawData = Data;
end

% Add processing step
RADIAL.ProcessingSteps{end+1} = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse out information that we need from header
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Turn off annoying multiple matches warning 
%ws=warning('query','getNameValuePair:MULT_MATCHES' );
%warning off getNameValuePair:MULT_MATCHES

% FileType
[ii,nn,vv] = getNameValuePair( 'FileType', names, values, 'exact' );
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_FILETYPE' ], ...
         'Could not find FileType in header. Returning empty structure.' ...
         );  
  return
end
if isempty(strfind(vv{1},'LLUV'))
    feval( warnfunc, [ mfilename ':INVALID_FILETYPE' ], ...
         'Invalid FileType in header. Only LLUV accepted. Returning empty structure.' ...
         );  
  return
end

% TimeStamp
[ii,nn,vv] = getNameValuePair( 'TimeStamp', names, values, 'exact' );
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_TIMESTAMP' ], ...
         'Could not find TimeStamp in header. Returning empty structure.' ...
         );  
  return
else
  RADIAL.TimeStamp = datenum(str2num(strparser(vv{1}))');
end

% TimeZone - as an offset from GMT
[ii,nn,vv] = getNameValuePair( 'TimeZone', names, values, 'exact' );
if isempty(names), keyboard, end
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_TIMEZONE' ], ...
         'Could not find TimeZone in header. Returning empty structure.' ); 
  return
else
  vv = cellstr(strparser( vv{1} ));
  if isempty(strfind(vv{1},'GMT')) & isempty(strfind(vv{1},'UTC'))
    feval( warnfunc, [ mfilename ':INVALID_TIMEZONE' ], ...
         'Invalid TimeZone in header. Only GMT or UTC accepted. Returning empty structure.' ...
         );  
    return
  end
  try
      gmtplus=str2double(vv{2});
      if gmtplus~=0
          feval( warnfunc, [ mfilename ':INVALID_TIMEZONE' ], ...
              'Invalid TimeZone in header. Only GMT or UTC accepted. Returning empty structure.' ...
              );
          return
      end
  catch
      feval( warnfunc, [ mfilename ':INVALID_TIMEZONE' ], ...
          'Invalid TimeZone in header. Only GMT or UTC accepted. Returning empty structure.' ...
          );
      return
  end
  RADIAL.TimeZone = [ 'GMT' vv{2} ];
end

% Origin
[ii,nn,vv] = getNameValuePair( 'Origin', names, values, 'exact' );
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_SITEORIGIN' ], ...
         'Could not find Origin in header. Returning empty structure.' ); 
  return
else
  vv = str2num( vv{1} );
  if vv(2)<-180 | vv(2)>360 | abs(vv(1))>90
      feval( warnfunc, [ mfilename ':INVALID_SITEORIGIN' ], ...
          'Invalid Origin in header. Must be [lat lon], -90<lat<90 and -180<lon<-180. Returning empty structure.' ...
          );
      return
  end
  RADIAL.SiteOrigin = vv([2,1]); % Given Lat,Lon, change to Lon,Lat
end

% Site
[ii,nn,vv] = getNameValuePair( 'Site', names, values, 'exact' );
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_SITENAME' ], ...
         'Could not find Site in header. Returning empty structure' ); 
  return
else
  vv = cellstr(strparser( vv{1} ));
  RADIAL.SiteName = vv{1};
end

% PatternType
[ii,nn,vv] = getNameValuePair( 'PatternType', names, values, 'exact' );
if isempty(ii) | isempty(vv{1})
  feval( warnfunc, [ mfilename ':NO_PATTERNTYPE' ], ...
         'Could not find PatternType in header. Returning empty structure.' );
  return
elseif ~ismember(vv{1},{'Measured','Ideal'})
    feval( warnfunc, [ mfilename ':INVALID_PATTERNTYPE' ], ...
         'Invalid PatternType in header. Must be ''Measured'' or ''Ideal''. Returning empty structure.' );
  return
else
  RADIAL.Type = [ 'RDL' vv{1} ];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get radial data columns that are particularly useful.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If data is empty, nothing to do.
if isempty(Data)
  feval( warnfunc, [ mfilename ':NO_DATA' ], ...
         'No Data in file.  Returning empty structure.' );
  return
end

% Find columns
ws=warning('query','getNameValuePair:MULT_MATCHES' );
warning off getNameValuePair:MULT_MATCHES % Deal with annoying multiple
                                          % match warnings.
[ii,nn,vv] = getNameValuePair( 'TableColumnTypes', names, values, 'exact' );
warning(ws)

if isempty(ii)
  feval( warnfunc, [ mfilename ':NO_TABLECOLUMNTYPES' ], ...
         [ 'Could not find TableColumnTypes in header.' ...
           ' Returning empty structure.' ] );
  return
end

vv = cellstr( strparser( vv{1} ) );

% List of columns that really should be present
II = [];
cc = { 'LOND', 'LATD', 'RNGE', 'BEAR', 'HEAD', 'VELO','VFLG' };
for k = 1:length(cc);
  ii = strmatch( cc{k}, vv, 'exact' );
  if isempty(ii)
    feval( warnfunc, [ mfilename ':MISSING_ESSENTIAL_DATA_COLUMN' ], ...
           [ 'One or more of the required data columns cannot be found.' ...
             ' Returning empty structure.' ] );
    return
  else
    II(k) = ii;
  end
end


% Get pieces of data we want if they are not empty.
RADIAL.LonLat = Data( :, II(1:2) );
RADIAL.RangeBearHead = Data( :, II(3:5) );  
RADIAL.RadComp = Data(:,II(6));
RADIAL.VectorFlag=Data(:,II(7));% added 20161007 HJR

% Change 999 in any field into NaN - NaN's create massive problems for
% using error field to calculate totals error.
for m = RADIALmatvars
  m = m{:};
  RADIAL.(m)( RADIAL.(m) == 999 ) = NaN;
end

% Change direction to cartesian convention.  Note, however, that bearing
% will still point away from radar and heading will still point towards radar.
RADIAL.RangeBearHead(:,2:3) = true2math( RADIAL.RangeBearHead(:,2:3) );

% U and V are optional but generally around - compute if absent
II = strmatch( 'VELU', vv, 'exact' );
JJ = strmatch( 'VELV', vv, 'exact' );
if isempty(II) || isempty(JJ)
  feval( warnfunc, [ mfilename ':MISSING_UV_DATA_COLUMN' ], ...
         'U or V component missing - calculating from RadComp and Heading');
  [RADIAL.U,RADIAL.V] = deal( RADIAL.RadComp .* cosd(RADIAL.RangeBearHead(:,3)), ...
                              RADIAL.RadComp .* sind(RADIAL.RangeBearHead(:,3)) ...
                              );
else
  RADIAL.U = Data(:,II);
  RADIAL.V = Data(:,JJ);
end

% Deal with two possible names for error column.
II = strmatch( 'ETMP', vv, 'exact' );
if isempty(II)
  II = strmatch( 'STDV', vv, 'exact' ); % old name
end
if isempty(II)
  feval( warnfunc, [ mfilename ':MISSING_ERROR_DATA_COLUMN' ], ...
         'Error column missing. Errors will all be NaN');
  RADIAL.Error = repmat(NaN,size(RADIAL.RadComp));
else
  RADIAL.Error = Data(:,II);
end
  
% Change 999 in any field into NaN - NaN's create massive problems for
% using error field to calculate totals error.
for m = RADIALmatvars
  m = m{:};
  RADIAL.(m)( RADIAL.(m) == 999 ) = NaN;
end

cc_leftovers = setdiff(vv,[cc,{'VELU','VELV','ETMP','STDV'}]);
for m=1:length(cc_leftovers)
    II = strmatch( cc_leftovers{m}, vv, 'exact' );
    RADIAL.(cc_leftovers{m}) = Data(:,II);
end

% Add currently unused Flag (1 is for original radials).
RADIAL.Flag = ones( size(RADIAL.RadComp) );

% Put warnings back in their initial state
%warning(ws)