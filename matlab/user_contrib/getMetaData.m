function [hdt,rdt] = getMetaData(filename,outnum)  
% T. Garner rewritten August 2, 2007
% extracts radial and hardware diagnostic tables from an RUV file
% INPUT 
%  filename    = the CODAR radial (RUV) file name, including the full path to the file
%  outnum      =1 to return numeric arrays (default)
%              =0 for character arrays including headers, for easy readability            
% OUTPUT is hdt and rdt variables (returns numeric array if 
% NOTE and WARNING: This is dependent on the current CODAR format of the radial
% files!!  Generally, if it fails, it returns empty variables! Incomplete
% files may cause other problems.
%
%    rdt contains the following data:
%     Time       Calculated      Calculated     Corrected        Noise Floor     SignalToNoise   Diag  Valid  Dual  Radial RadsV Rads   Max   Vel    Vel    Bearing  Radial Spectra Time
%   FromStart   Amp1    Amp2   Phase13 Phase23 Phase1 Phase2   NF1   NF2   NF3   SN1  SN2  SN3   Range Dopplr Angle Vector  per  Range Range  Max    Aver   Average   Type   Type   Year Mo Dy  Hr Mn  S
%    Seconds  (1/v^2) (1/v^2)   (deg)   (deg)   (deg)  (deg)  (dBm) (dBm) (dBm)  (dB) (dB) (dB)  Cell  Cells  Prcnt Count  Range Cells  (km) (cm/s) (cm/s) (deg CWN)
%
%    hdt contains the following data:
%    LogTime Rcvr Awg3 XmtTrip Awg3Run Supply +5VDC -5VDC +12VDC XInt XAmp XForw XRefl X+Ampl X+5VDC GpsRcv GpsDsp  PLL   HiRcvr Humid Supply  CompRunTime   Year Mo Dy Hr Mn  S
%    Minutes degC degC HexCode Seconds Volts  Volts Volts  Volts degC degC Watts Watts  Volts  Volts  Mode   Mode  Unlock  degC     %   Amps     Minutes    

if ~exist('outnum','var')
    outnum = 1;
end

[h,fn,ff] = getRDLHeader( filename );
[ti,tn,tv] = getNameValuePair('TableType', fn, ff);
[si,sn,sv] = getNameValuePair('TableStart', fn, ff);
[ei,en,ev] = getNameValuePair('TableEnd', fn, ff);

% find correct index for radial and hardware diagnostic tables
% assumes appropriate TableStart and TableEnd indices will match indices for TableType
rdtindx = strmatch('rads rad1',char(tv));
hdtindx = strmatch('rcvr rcv2',char(tv));

CH = char(h);
if ~isempty(rdtindx)
    if (outnum) 
      rdt = str2num(CH(si(rdtindx)+1+3:ei(rdtindx)-1,2:end));
    else
      rdt = CH(si(rdtindx)+1:ei(rdtindx)-1,3:end);
    end
else 
    rdt = [];
end;

if ~isempty(hdtindx)
    if (outnum)
      hdt = str2num(CH(si(hdtindx)+1+2:ei(hdtindx)-1,2:end));
    else
      hdt = (CH(si(hdtindx)+1:ei(hdtindx)-1,3:end));
    end
else
    hdt = [];
end