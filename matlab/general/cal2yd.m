function yearday = cal2yd(caltime,relyear)
%CAL2YD  Converts from year/month/day/ etc.. to yearday
%
%  Usage: 
%     YEARDAY = CAL2YD(CALTIME,BASEYEAR)
%
%  INPUTS:
%    CALTIME - an N row x 3-6 column array, where column #:
%      1=   year  can be either the last 2 digits of the year - eg. 89,
%                 or all 4 digits - eg. 1989. (but MUST be integer)
%                 If year is last 2 digits, years 0 to 25 are mapped to 
%                 2000-2025 and 26 to 99 to 1926-1999.
%      2=   month = a number rather than a name - (1-12) (MUST be integer)
%      3=   day   = 1-31      
%      4=   hour  = 0-23   (optional)
%      5=   min   = 0-59   (optional)
%      6=   sec   = 0-59   (optional)
%
%      The user *MUST* supply at least the first 3 arguments, so:
%         CAL2YD([YEAR, MONTH, DAY])
%         CAL2YD([YEAR, MONTH, DAY, HOUR])
%         CAL2YD([YEAR, MONTH, DAY, HOUR, MIN])
%         CAL2YD([YEAR, MONTH, DAY, HOUR, MIN, SEC])
%      are all valid.
%
%    BASEYEAR will create yeardays that are relative to another year.  So
%      for example:   CAL2YD([1997,1,1,0],1996) will yield 367.
%      BASEYEAR is optional.  If BASEYEAR is not supplied 
%      BASEYEAR = CALTIME(1,1) 
%      BASEYEAR can be 1 x 1 or N x 1 vector of years.
%
%  OUTPUT:
%    YEARDAY - decimal day of the year relative to BASEYEAR.
%
%
%  NOTES: 
%    The yearday is relative to 0000 Jan 1st of the input 'year'
%    where, 1200 Jan 1st is yearday 1.5, NOT 0.5.
%   
%	 The day, hour, min, and/or sec argument can be decimal, 
%    but the year and month *MUST* be integer for function
%    to work correctly.
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	$Id: cal2yd.m 396 2007-04-02 16:56:29Z mcook $
%
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%	Mike Cook  -  DEC 93  - Department of Oceanography, NPS.
%   Ver. 1.0. Modified by Mike Cook MAR 94:  Add more error checking and
%   add warning messages if day, hour, min, or sec exceed
%   normal limits.
%
%   Ver. 1.1. Modified by Mike Cook AUG95:  Converted code from only being
%   able to handle scalars to vector/matrix handling. -MCOOK
%   
%   Ver. 2.0. Major mod. by Mike Cook 27 Feb 98:  Use the daynumber
%   function to calculate the day of the year. -MCOOK
%
%   Ver. 3.0. Major mod. 26 Jan 2007.  Replace the daynumber function with
%   matlab's datenum call.  Do Y2K checking in this program, was previously
%   done in daynumber. -MCOOK


% Get size of one of the inputs, assume all inputs are the 
% same size; i.e. no error checking for different sizes.
[rows,cols] = size(caltime);

%	Do some crude error checking
if cols < 3
   error('Must supply at least [yr, mon, day]')
end
if cols > 6
   error('Must supply 3 to 6 time components: [yr, mon, day, hour, min, sec]')
end

% Do default checking
if nargin < 2
   relyear = caltime(1,1);
end

if cols < 4
   addcols = zeros(rows,3);
elseif cols < 5
   addcols = zeros(rows,2);
elseif cols < 6
   addcols = zeros(rows,1);
else
   addcols = [];
end

caltime = [caltime addcols];
year  = caltime(:,1);
month = caltime(:,2);
day   = caltime(:,3);
hour  = caltime(:,4);
min   = caltime(:,5);
sec   = caltime(:,6);

% Display a warning message if the day, hour, min, or sec
% are not within the 'expected' range, but calculate yearday anyway
% If however, month is out of 1-12 range, terminate program.
if any(month < 1  |  month > 12);
    error('ERROR:  some month data > 12 or < 1 ... TERMINATING')
end

if any(day < 1  |  day > 31);
    disp('WARNING:  some day data > 31 or < 1.')
end

if any(hour < 0  |  hour > 24);
    disp('WARNING:  some hour data > 24 or < 0.')
end

if any(min < 0  |  min > 60);
    disp('WARNING:  some minute data > 60 or < 0.')
end

if any(sec < 0  |  sec > 60);
    disp('WARNING:  some second data > 60 or < 0.')
end

% Y2K business
year = year + (year <  26) * 2000;
year = year + (year < 100) * 1900;
relyear = relyear + (relyear <  26) * 2000;
relyear = relyear + (relyear < 100) * 1900;

% Algorithm: 
% Calculate the matlab datenum time at beginning of relative
% year (year,month=1,day=1,hour=0,min=0,sec=0)
mlBaseTime = datenum(relyear,1,1);
% Calculate the user input times
mlTime = datenum(year,month,day,hour,min,sec);
% Difference + 1 is the yearday relative to baseyear.
yearday = mlTime+1 - mlBaseTime; 