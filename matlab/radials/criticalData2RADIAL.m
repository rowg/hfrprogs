function R = criticalData2RADIAL( ts, LL, head, RadComp, varargin )
% CRITICALDATA2RADIAL  Puts minimum set of data variables necessary into
% a RADIAL structure
%
% This function simplifies getting non-RDL data files into RADIAL structures
% by taking the minimal data variables for the data to be useful and placing
% it in a RADIAL structure.  If you have RDL files, then it is probably
% better to use loadRDLFile.
%
% Usage: RADIAL = criticalData2RADIAL( TimeStamp, LonLat, Heading, ...
%                             RadialComponent, PARAM1, VAL1, ... )
%
% Inputs
% ------
% TimeStamp = Times of radial data.  Should be a vector.
% LonLat = a 2 column matrix of Lon,Lat coordinates of radial grid
%          points.
% Heading = Direction of radial component at each grid point.  Must have
%           the same number of elements as rows in LonLat.  The
%           convention is that the Heading always points from the radial
%           grid point towards the radar, but this is not essential for
%           many tasks.
% RadialComponent = radial velocity measurement at each radial grid point
%                   and time.  A matrix with each row for a single grid
%                   point and each column for a time in TimeStamp.  Can
%                   be positive or negative depending on whether velocity
%                   is in the same sense as Heading or in the opposite
%                   direction.
% PARAMn,VALn = parameter, value pairs described below.
%
% Parameters
% ----------
% 'Bearing' = Bearing from radar site to each radial grid point.
%             Convention is that this points from radar to radial grid
%             point.  This is MANDATORY if you want to do interpolation
%             of radial data afterwards.
% 'Range' = distance from radar to grid point.  Same size as Bearing and
%           Heading.
% 'Error' = error estimate for each radial measurement.  Same size as
%           RadialComponent.
% 'Flag' = a flag for each radial measurement.  Same size as
%          RadialComponent.
% 'SiteOrigin' = Lon,Lat location of radar site.  MANDATORY for
%                interpolation of radial data at a later time.
% 'SiteName' = Name of radar site.  Necessary if you plan to use
%              temporalConcatRadial with this radial data.
% 'FileName' = Name of data files.  Should be a cell array with same number
%              of elements as TimeStamp.
%
% Outputs
% -------
% RADIAL = RADIAL structure with data.  This will be a very minimal
%          radial structure in the sense that it has little or no
%          metadata such as Header, time zones and perhaps others.
%          However, U and V will be computed from the RadComp
%          and Heading.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: criticalData2RADIAL.m 398 2007-04-02 22:46:32Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ts = ts(:)';
head = head(:);

if numel(head) ~= size(LL,1)
  error( 'Bad input LonLat or Heading.' );
end

if any( [size(LL,1),numel(ts)] ~= size(RadComp) )
  error( 'RadialComponent size does not agree with LonLat and TimeStamp.' );
end

% Default extra inputs
p.SiteOrigin = [ NaN NaN ];
p.SiteName = '';

p.FileName = repmat( {''}, size(ts) );

[p.Bearing,p.Range] = deal( repmat(NaN,size(head)) );
[p.Error,p.Flag] = deal( repmat(NaN,size(RadComp)) );

% Figure out extra arguments
param_list = { 'Bearing', 'Range', 'Error', 'Flag', 'SiteOrigin', 'SiteName', ...
               'FileName' };

[p,pb] = checkParamValInputArgs( p, param_list, {}, varargin{:} );

if ~isempty(pb)
  pb = strcat(fieldnames(pb), {' '} );
  pb = [ pb{:} ];
  error( 'The following unknown parameters were given: %s ', pb );
end

% Put data in place.
R = RADIALstruct;

R.SiteName = p.SiteName;
R.SiteOrigin = p.SiteOrigin;

R.FileName = p.FileName;

R.TimeStamp = ts;
R.LonLat = LL;
R.RangeBearHead = [ p.Range(:), p.Bearing(:), head ];

R.RadComp = RadComp;
R.Error = p.Error;
R.Flag = p.Flag;

% Compute U and V
R.U = R.RadComp .* repmat( cosd(head), [1,numel(ts)] );
R.V = R.RadComp .* repmat( sind(head), [1,numel(ts)] );

% Add processing steps
R.ProcessingSteps{end+1} = mfilename;
