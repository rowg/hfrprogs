function TE = subsasgnTUVerror( TE, v, I )
% SUBSASGNTUVERROR  Used to replace values in total error structures, 
%
% Usage: Terr = subsasgnTUVerror( Terr, val, I )
%
% Inputs
% ------
% Terr = total error structure to be operated on (created by
%        TUVerrorstruct).
% val = values to be put in TUV error structure.  This can be a matrix or
%       another TUV error structure.
% I = Index of values to be replaced.  See subsasgnTUV for more details.
%
% Output
% ------

% Terr = total error structure that has values replaced.
%
% NOTE: To operate on all values, user I = ':'.
%
% See subsasgnTUV for more info on how this works.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: subsasgnTUVerror.m 481 2007-09-13 21:20:30Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Do errors
if ~isempty( TE )
  for k = 1:length(TE)
    % Normal variables
    for f = { 'Uerr', 'Verr', 'UVCovariance', 'TotalErrors' }
      if ~isempty( TE(k).(f{:}) )
        if isstruct(v)
          TE(k).(f{:}) = myref( TE(k).(f{:}), v(k).(f{:}), I );
        else
          TE(k).(f{:}) = myref( TE(k).(f{:}), v, I );
        end
      end
    end
    
    % Extra variables
    if ~isempty( TE(k).OtherMatrixVars )
      for f = fieldnames( TE(k).OtherMatrixVars )'
        if ~isempty( TE(k).OtherMatrixVars.(f{:}) )
          if isstruct(v)
            TE(k).OtherMatrixVars.(f{:}) = myref( TE(k).OtherMatrixVars.(f{:}), ...
                                                  v(k).OtherMatrixVars.(f{:}), ...
                                                  I );
          else
            TE(k).OtherMatrixVars.(f{:}) = myref( TE(k).OtherMatrixVars.(f{:}), ...
                                                  v, I );
          end
        end
      end
    end
    
  end
end


%%%%%%%%%--------SUBFUNCTIONS-----------%%%%%%%%%%%%
function V = myref( V, v, I )
if iscell(I)
  V( I{:} ) = v;
else
  V( I ) = v;
end
