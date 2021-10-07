function mTime = epoch2datenum(epochTime)
%
% Usage: mTime = epoch2datenum(epochTime)
%
% Converts the unix/epoch timestamp to a matlab datenum datatype.
%
% SEE ALSO datenum datenum2epoch
% ============================================================================
% $RCSfile: epoch2datenum.m,v $
% $Source: /home/kerfoot/cvsroot/matlab/bin/epoch2datenum.m,v $
% $Revision: 1.2 $
% $Date: 2009/11/17 21:40:44 $
% $Author: kerfoot $
% ============================================================================
%

% Calculate the number of days elapsed between January 1, 0000 and January 1, 
% 1970.  January 1, 1970 is the beginning of time in the unix world and is 
% referred to as the epoch.
epoch_offset = datenum(1970, 1, 1) - datenum(0000, 1, 0);

% Divide the input (epochTime) by the number of seconds in 1 day.
from_epoch = epochTime/(24 * 60 * 60);

% Add the 2 to get the datenum number.
mTime = epoch_offset + from_epoch;
