function  [year,month,day,hour,minute,sec] = yd2cal(year,yd)
%YD2CAL  Convert yeardays to [year month day hour minute sec] format.
%
% USAGE:
%       [YEAR,MON,DAY,HR,MINUTE,SEC] = YD2CAL(YEAR,YD)
%
% Valid usages:
% [year, month, day] = yd2cal(year, yearday)
% [year, month, day, hour] = yd2cal(year, yearday)
% [year, month, day, hour, minute] = yd2cal(year, yearday)
% [year, month, day, hour, minute, sec] = yd2cal(year, yearday)
%
% INPUTS:
%        YEAR    - the year to which the YEARDAY is relative.  Note 
%                  year can be either the last 2 digits of the year - eg. 
%                  89, or all 4 digits - eg. 1989. (but MUST be integer)
%                  If year is last 2 digits, years 0 to 25 are mapped to 
%                  2000-2025 and 26 to 99 to 1926-1999.
%                  Can be 1 x 1 or N x 1.
%        YEARDAY - a yearday.  Can be 0, negative or > 366.
%                  Can be 1 x 1 or N x 1.
%
% NOTES:
%    The yearday is relative to 0000 Jan 1st of the input 'year'
%    where, 1200 Jan 1st is yearday 1.5, NOT 0.5.
%
%    YD2CAL will handle 0 and negative yeardays, so YD2CAL(1997,0) will
%    give you 31 Dec 1996 @0000, and YD2CAL(1997,-1) will give you 
%    30 Dec 1996 @0000.
% 
% Also can pass in a 1 x 1 year and a vector or N x 1 yearday, or an N x 1
% vector or years and a 1 x 1 year day, or both vectors or matrices of the
% same dimensions.
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: yd2cal.m 633 2008-03-28 04:41:01Z cook $
%
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Ver 1.0 - Mike Cook, NPS Oceanography, FEB 96
% Ver 2.0 - Mike Cook, 24 Feb 98
%           extend the function to calculate yeardays that extend   
%           beyond the base year.  For example, this function now
%           will handle :  [1996, 364
%                           1996, 365
%                           1996, 366
%                           1996, 367]; 
% Ver. 3.0. Major mod. 26 Jan 2007.  Replace my conversion code
% with matlab's datevec call.  Really cleans things up and makes this
% program much more versatile.  Add year Y2K checking.  -MCOOK


% Check for both input arguments
if nargin < 2
   error('Must supply year and yearday vectors ... TERMINATING!')
end

% Add a very small number to prevent roundoff error I have observed using
% datenum/datevec that will take a datenum time that maps to 
% 1999 12 1 0 0 0 but computes 1999 11 30 23 59 59.9999999999
yd = yd + eps;

% Y2K business
year = year + (year <  26) * 2000;
year = year + (year < 100) * 1900;

% Algorithm:
% Compute the matlab datenum time for year, month=1, day=1, hour=0 ... and
% then add the yearday to that and use datevec to compute the calendar
% time.
mlTime = datenum(year,1,1);
mlTime = mlTime + yd - 1;
[year,month,day,hour,minute,sec] = datevec(mlTime);
