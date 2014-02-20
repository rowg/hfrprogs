function T = rotateTotals( T, angle, rerrors )
% ROTATETOTALS  Rotates total currents through an angle
%
% Usage: TUV = rotate( TUV, angles, rotate_errors )
%
% Rotation of total vectors is often useful for things like EOF analysis
% around the principal components of a vector, as well as other tasks.
% 
% Inputs
% ------
% TUV = a TUV structure
%
% angles = angles to rotate each U,V pair through in degrees.  This angle
%          will be added to the angle of U and V.  angles can be a scalar
%          to rotate all U,V pairs equally, a column vector to rotate
%          each spatial grid point a different angle, a row vector to
%          rotate each timestep a different angle or a matrix the
%          same size as TUV.U to rotate each U,V pair individually.
% rotate_errors = a boolean indicating whether or not to attempt rotating
%                 the covariance matrix formed by [ Uerr, UVCovariance;
%                 UVCovariance, Verr ] as well.  Defaults to False.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: rotateTotals.m 478 2007-09-11 01:01:59Z dmk $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'rerrors', 'var' )
  rerrors = false;
end

% Metadata
T.OtherMetadata.(mfilename).angle = angle;
T.OtherMetadata.(mfilename).rotate_errors = rerrors;
T.ProcessingSteps{end+1} = mfilename;

% Make angle size of T.U if it is not a scalar
if numel(angle) > 1
  angle = repmat( angle, size(T.U) ./ size(angle) );
end

% Do rotation of U and V
[T.U, T.V] = rotUV( T.U, T.V, angle );

% Rotate errors
if rerrors
  for k = 1:numel(T.ErrorEstimates)
    if ~isempty(T.ErrorEstimates(k).Uerr) & ...
          ~isempty(T.ErrorEstimates(k).Verr) & ...
          ~isempty(T.ErrorEstimates(k).UVCovariance)
      [T.ErrorEstimates(k).Uerr,T.ErrorEstimates(k).Verr, ...
       T.ErrorEstimates(k).UVCovariance] = ...
          mymatrot(T.ErrorEstimates(k).Uerr,T.ErrorEstimates(k).Verr, ...
                   T.ErrorEstimates(k).UVCovariance,angle);
    else
      warning([ 'Errors of type ' T.ErrorEstimates(k).Type ...
                ' could not be rotated.' ]);
    end
  end
end

%%%----SUBFUNCTIONS---%%%
function [uu,vv,uv] = mymatrot( uu, vv, uv, angle )
[a,c] = rotUV( uu, uv, angle );
[b,d] = rotUV( uv, vv, angle );

uu = rotUV( a, b, angle );
[uv,vv] = rotUV( c, d, angle );

