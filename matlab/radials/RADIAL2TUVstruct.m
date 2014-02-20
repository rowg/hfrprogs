function T = RADIAL2TUVstruct( R )
% RADIAL2TUVSTRUCT  Converts RADIAL structures into TUV structures,
% which is useful for things like plotting
%
% NOTE: Must be a single RADIAL structure, not an array of such
% structures.
%
% Usage: TUV = RADIAL2TUVstruct( RADIAL )
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: RADIAL2TUVstruct.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

T = TUVstruct( size(R.RadComp), 1 );
T.Type = 'RADIAL';

T.DomainName = R.SiteName;

T.TimeStamp = R.TimeStamp;
T.TimeZone = R.TimeZone;

T.CreateTimeStamp = R.CreateTimeStamp;
T.CreateTimeZone = R.CreateTimeZone;

T.LonLat = R.LonLat;
T.OtherSpatialVars.RangeBearHead = R.RangeBearHead;

T.U = R.U;
T.V = R.V;

T.LonLatUnits = R.LonLatUnits;

T.UUnits = R.UUnits;
T.VUnits = R.VUnits;

T.OtherMatrixVars.RadialComponent = R.RadComp;

T.ErrorEstimates(1).Type = 'RadialError';
T.ErrorEstimates(1).TotalErrors = ...
    R.Error;
T.ErrorEstimates(1).TotalErrorsUnits = R.ErrorUnits;

T.OtherMatrixVars.RadialFlag = R.Flag;

if ~isempty(R.OtherMatrixVars)
  for f = fieldnames(R.OtherMatrixVars)'
    f = f{:};
    T.OtherMatrixVars.([ 'Radial_' f ]) = R.OtherMatrixVars.(f);
  end
end

% Add processing steps
T.ProcessingSteps{end+1} = mfilename;


R = rmfield( R, { 'SiteName', 'LonLat', 'LonLatUnits', 'RangeBearHead' ...
                  'TimeStamp', 'TimeZone', 'CreateTimeStamp', ...
                  'CreateTimeZone' 'UUnits', 'VUnits', 'U', 'V', ...
                  'RadComp', 'Error', 'Flag', 'ErrorUnits', ...
                  'OtherMatrixVars' } );

T.OtherMetadata(1).Radial = R;
