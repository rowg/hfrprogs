function [EOFStruct,MassagedSignal]=GetEOFsCMH(SeriesIn,ModeNumSwitch,ModeNum,MeanSwitch,NormSwitch,RotSwitch)
%
%  [EOFStruct,MassagedSignal]=GetEOFsCMH(SeriesIn,ModeNumSwitch,ModeNum,MeanSwitch,NormSwitch,RotSwitch);
%
%  CMH, 2007
%
%  Inputs:
%
%  SeriesIn is a matrix, set up here so that each row is a different
%  spatial location, each column is a different time  (will be flipped and
%  flipped back in the routine to be consitent with typical EOF derivations
%  using SVD)
%
%  ModeNumSwitch is how many shapes to return.  'All' means all, PerVar
%  means return up to the number that explains x% of the variance, and
%  SetNum means returns a set number (like 5).  ModeNum is the value that
%  goes with ModeNumSwitch.  Set to NaN (or anything) if
%  ModeNumSwitch='All';
%
%  MeanSwitch = 'All' means to remove the mean in both space and time
%  before processing, 'None' means to not remove the mean, and 'Individual'
%  means to remove the time mean from each spatial location first.  The
%  means are returned.
%
%  NormSwitch = 'STDNorm' means to normalize the series at each spatial
%  location by its standard deviation prior to processing.  'NONE' means to
%  not do any normalization.
%
%  RotSwitch = 'ROT' means to rotate the series at each spatial location to
%  its along axis components (major,minor) prior to finding the shapes...
%  not implemented yet.  'NONE' means to not do this.  Only do for a
%  complex series.
%
%  Note:  std call is the square root of teh variance in matlab, variance
%  is calulate correctly.  So the std and variance factors, which were set
%  up using real arrays, should work for complex arrays as well.
%    The portions where I calculate the variance myself was modified to use
%    the complex conjugate.
%
%  Outputs:
%
%  EOFStruct.Means --->  the means that need to be added back at each point
%  in order to reconstruct the whole series.  If MeanSwitch = 'All', then
%  the means at each point are the same.  Set to NaN if no means removed.
%  EOFStruct.Stds --->  The standard deviations used to normalize the
%  signal at each point.  Set to NaNs if this switch is not thrown.
%  EOFStruct.Shapes --->  The shapes, normalized so that the maximum
%  absolute value is equal to one.  Each row is a different location, each
%  column is a different shape.  Number of columns output will either be
%  all of the shapes found, or the number requested.
%  EOFStruct.PerVarExplained ---> The percentage of variance in the
%  signal explained by each shape.  This percentage is based on
%  the signal after the means have been removed, and the signal has been
%  normalized according to the parameters specified.  A row vector (1 x
%  number of shapes)
%  EOFStruct.VarPerShape --->  The variance associated with each individual
%  shape over the array.  Also a row vector.
%  EOFStruct.AmpPerTime --->  The amplitude of the shapes vs time.  Each
%  row represents a different shape, each column represents a different
%  time.  A matrix, number of rows equal number of shapes, number of
%  columns equal number of input times.
%  EOFStruct.ReconstructedSignal.Massaged --->  the reconstructed, massaged
%  signal, using the speciified number of modes or percent variance options
%  EOFStruct.ReconstructedSignal.Original --->  the reconstructed, original
%  signal, using the number of modes or percent variance options.  Rescaled
%  by the standard deviations, if necessary, and means added back in.
%  EOFStruct.TypicalError.Massaged.real --->  Column 1 is the standard deviation
%  (taken over time) of the error at each site, column 2 is that typical
%  error divided by the standard deviation of the fluctuations at that
%  site.  This is for comparison with the Massaged Signal.
%  EOFStruct.TypicalError.Original.real  ---> same, but for comparison with
%  the original signal.
%  EOFStruct.TypicalError.Massaged.imag --->  As for the real component of
%  the measurements, but for the imaginary component.  Only does if teh
%  input is complex.
%  EOFStruct.TypicalError.Original.imag --->  Compares to the original
%  signal.
%  EOFStruct.TypicalError.Massaged.mag --->  AS for the real component, but
%  for the magnitude of the measurements.  Only does if complex.
%  EOFStruct.TypicalError.Original.mag --->  For the original signal, again
%  only if complex.
%  EOFStruct.TypicalTimeError.Massaged--->  the typical error (vs time)
%  when comparing the massaged and massaged reconstructed signal
%  EOFStruct.TypicalTimeError.Original--->  the typical error (vs time)
%  when comparing the original and original reconstructed signal
%
%
%  MassagedSignal - the original signal, after the options specified by
%  the user have been applied to it.  The signal that the EOFs are found
%  for.
%
%  !!!  this routine assumes the shapes are automatically output from
%  largest (most significant) to smallest by Matlab.  Could add a check,
%  but would be redundant.
%
%  Step 1 - take transpose, so that a more standard format is used, time
%  going down the rows, space across the columns.
%
%
%  now take transpose to make them into a more standard format, time going down the rows
%
%  NOTE!!!  for the STD nprmalization, locations where teh standard
%  deviations are less than 1/10 of teh typical standard deviation are left
%  unormalized.  These fluctuations are small anyway.
%
OriginalSignal=SeriesIn;  % will need later for error calculations
%
[NumSpaces,NumTimes]=size(SeriesIn);
%
SeriesIn=SeriesIn';
%
%  Step 2 - remove means if necessary
%
switch upper(MeanSwitch)
    case 'ALL'
        GlobalMean=mean(mean(SeriesIn));
        SeriesIn=SeriesIn-GlobalMean;
        EOFStruct.Means=GlobalMean*ones(NumSpaces,1);
        clear GlobalMean
    case 'INDIVIDUAL'
        IndMean=mean(SeriesIn);
        [mrows,ncols]=size(SeriesIn);
        MeanRem=ones(mrows,1)*IndMean;
        SeriesIn=SeriesIn-MeanRem;
        EOFStruct.Means=IndMean';
        clear MeanRem IndMean
    otherwise
        EOFStruct.Means=NaN*ones(NumSpaces,1);
        disp('No Means Removed From Signal')
        disp('Make sure that MeanSwitch = NONE')
end
%
ChangeSTDs=zeros(NumSpaces,1);  % will be used to set relative error to zero
%  later if need be
%
switch upper(NormSwitch)
    case 'STDNORM'
        StdMeas=std(SeriesIn);
        temmark=find(StdMeas==0);  % in case we have zeroed out some measurements
        if numel(temmark)>0,
            StdMeas(temmark)=1;
            ChangeSTDs(temmark)=1;
            disp('some standard deviations were zero, set to 1 for normalization')
        end
        %
        %  now find ones that are too small
        %
        temmark=find(StdMeas<=0.1*std(StdMeas));
        if numel(temmark)>0,
            StdMeas(temmark)=1;
            ChangeSTDs(temmark)=1;
            disp('some standard deviations were small, set to 1 for normalization')
        end
        %
        %
        [mrows,ncols]=size(SeriesIn);
        StdNorm=ones(mrows,1)*StdMeas;
        SeriesIn=SeriesIn./StdNorm;
        EOFStruct.Stds=StdMeas';
        clear StdMeas StdNorm
    otherwise
        EOFStruct.Stds=NaN*ones(NumSpaces,1);
        disp('No Standard Deviation Normalization Performed On Signal')
        disp('Make sure that NormSwitch = NONE')
end
%
switch upper(RotSwitch)  % not implemented yet
    case 'ROT'
        %
    otherwise
        %
end
%
MassagedSignal=SeriesIn';  % the signal we are analyzing now
%
%  Next Step, perform SVD
%
[U,S,V] = svd(full(SeriesIn));
%
Amp=U*S;
%
%  normalize each column of V so that the maximum absolute value is 1
%
[MaxValV]=max(abs(V));
[mv,nv]=size(V);
MaxValVmatrix=ones(mv,1)*MaxValV;
V=V./MaxValVmatrix;
%
%  now we have to normalize the amplitudes to correspond
%
[mAmp,nAmp]=size(Amp);
MaxValVmatrix=ones(mAmp,1)*MaxValV;
%
Amp=Amp.*MaxValVmatrix;
%
%  calculate the variance of the signal, and the percent variance
%  explained by each shape.  Also the variance associated with each shape.
%
VarExplained=NaN*ones(1,mAmp);
%
VT=V';
for jvar=1:mAmp,
    TemSer=Amp(:,jvar)*VT(jvar,:);
    TemSer=TemSer.*conj(TemSer);
    VarExplained(jvar)=sum(sum(TemSer))/(numel(TemSer)-1);  % could leave off the minus 1
end
% 
%  get variance of whole signal
%
TemVar=sum(sum(SeriesIn.*conj(SeriesIn)))/(numel(SeriesIn)-1);
%
PercentVarExplained=(1/TemVar)*VarExplained;
PercentVarExplained=100*PercentVarExplained;
%
[TemRows,NumShapesFound]=size(V);
%
VarPerShape=var(V);  % normalized by N-1 as we have been doing
%
switch upper(ModeNumSwitch)
    case 'ALL'
        %
        NumShapesToUse=NumShapesFound;
        %
    case 'PERVAR'
        %
        CumVar=cumsum(PercentVarExplained);
        temmark=find(CumVar>=ModeNum);
        if numel(temmark)>0,
            NumShapesToUse=temmark(1);
        else
            NumShapesToUse=NumShapesFound;
        end
        %        
    case 'SETNUM'
        %
        if ModeNum<=NumShapesFound,
            NumShapesToUse=ModeNum;
        else
            NumShapesToUse=NumShapesFound;
        end
        %
    otherwise
        %
        disp('improper value of ModeNumSwitch thrown')
        disp('Enough shapes to explain 75% of the variance will be returned')
        %
        CumVar=cumsum(PercentVarExplained);
        temmark=find(CumVar>=75);
        if numel(temmark)>0,
            NumShapesToUse=temmark(1);
        else
            NumShapesToUse=NumShapesFound;
        end        
end
%
EOFStruct.Shapes=V(:,1:NumShapesToUse);
%
EOFStruct.PerVarExplained=PercentVarExplained(1:NumShapesToUse);
%
EOFStruct.VarPerShape=VarPerShape(1:NumShapesToUse);
%
AmpOut=Amp(:,1:NumShapesToUse);
AmpOut=AmpOut';
EOFStruct.AmpPerTime=AmpOut;
clear AmpOut
%
%  now obtain the reconstructed signals
%
%  Modify the Amp and V matrices at this point
%
if NumShapesToUse<NumShapesFound,
    V(:,NumShapesToUse+1:NumShapesFound)=0;
    Amp(:,NumShapesToUse+1:NumShapesFound)=0;
end
%
TemReconstruct=Amp*V';
%
EOFStruct.ReconstructedSignal.Massaged=TemReconstruct';  % put in same order 
%  as input matrix
%
%  now scale the signal by the standard deviations, if need be
%
switch upper(NormSwitch)
    case 'STDNORM'
        StdMeas=EOFStruct.Stds;
        StdMeas=StdMeas';
        [mrows,ncols]=size(SeriesIn);
        StdNorm=ones(mrows,1)*StdMeas;
        TemReconstruct=TemReconstruct.*StdNorm;
        clear StdMeas StdNorm
    otherwise
        %
        %  do nothing to the reconstructed signal
        %
end
%
%  now add the means back in, if need be
%
switch upper(MeanSwitch)
    case 'ALL'
        MeanNum=EOFStruct.Means;  % overkill, since only one mean found here
        MeanNum=MeanNum';
        [mrows,ncols]=size(SeriesIn);
        MeanAdd=ones(mrows,1)*MeanNum;
        TemReconstruct=TemReconstruct+MeanAdd;
        clear MeanAdd MeanNum
    case 'INDIVIDUAL'
        MeanNum=EOFStruct.Means;
        MeanNum=MeanNum';
        [mrows,ncols]=size(SeriesIn);
        MeanAdd=ones(mrows,1)*MeanNum;
        TemReconstruct=TemReconstruct+MeanAdd;
        clear MeanAdd MeanNum
    otherwise
        %
        %  do nothing
        %
end
%
EOFStruct.ReconstructedSignal.Original=TemReconstruct';  % to put back into the same orientation
%  as the input signal - space down the rows, time across the columns
%
%  Calculate the errors....  first, for comparison with the massaged
%  Signal
%
ErrToInvestigate=MassagedSignal-EOFStruct.ReconstructedSignal.Massaged;
ErrToInvestigate=ErrToInvestigate';
%
STDReal=std(real(ErrToInvestigate));
STDReal=STDReal';
%
STDMeas=std(real(MassagedSignal'));
STDMeas=STDMeas';
%
STDMeas=STDReal./STDMeas;
%
temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
if numel(temmark)>0,
    STDMeas(temmark)=0;
end
%
EOFStruct.TypicalError.Massaged.real=[STDReal STDMeas];
%
if ~isreal(OriginalSignal),
    %
    STDImag=std(imag(ErrToInvestigate));
    STDImag=STDImag';
    %
    STDMeas=std(imag(MassagedSignal'));
    STDMeas=STDMeas';
    %
    STDMeas=STDImag./STDMeas;
    %
    temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
    if numel(temmark)>0,
        STDMeas(temmark)=0;
    end
    %
    EOFStruct.TypicalError.Massaged.imag=[STDImag STDMeas];
    %
    %
    ErrToInvestigate=abs(MassagedSignal)-abs(EOFStruct.ReconstructedSignal.Massaged);
    ErrToInvestigate=ErrToInvestigate';
    %
    STDAbs=std(ErrToInvestigate);
    STDAbs=STDAbs';
    %
    STDMeas=std(abs(MassagedSignal'));
    STDMeas=STDMeas';
    %
    STDMeas=STDAbs./STDMeas;
    %
    temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
    if numel(temmark)>0,
        STDMeas(temmark)=0;
    end
    %
    EOFStruct.TypicalError.Massaged.mag=[STDAbs STDMeas];
    %
end
%
%  now repeat the above with the original signal
%
ErrToInvestigate=OriginalSignal-EOFStruct.ReconstructedSignal.Original;
ErrToInvestigate=ErrToInvestigate';
%
STDReal=std(real(ErrToInvestigate));
STDReal=STDReal';
%
STDMeas=std(real(OriginalSignal'));
STDMeas=STDMeas';
%
STDMeas=STDReal./STDMeas;
%
temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
if numel(temmark)>0,
    STDMeas(temmark)=0;
end
%
EOFStruct.TypicalError.Original.real=[STDReal STDMeas];
%
if ~isreal(OriginalSignal),
    %
    STDImag=std(imag(ErrToInvestigate));
    STDImag=STDImag';
    %
    STDMeas=std(imag(OriginalSignal'));
    STDMeas=STDMeas';
    %
    STDMeas=STDImag./STDMeas;
    %
    temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
    if numel(temmark)>0,
        STDMeas(temmark)=0;
    end
    %
    EOFStruct.TypicalError.Original.imag=[STDImag STDMeas];
    %
    %
    ErrToInvestigate=abs(OriginalSignal)-abs(EOFStruct.ReconstructedSignal.Original);
    ErrToInvestigate=ErrToInvestigate';
    %
    STDAbs=std(ErrToInvestigate);
    STDAbs=STDAbs';
    %
    STDMeas=std(abs(OriginalSignal'));
    STDMeas=STDMeas';
    %
    STDMeas=STDAbs./STDMeas;
    %
    temmark=find(ChangeSTDs==1);  % if small fluctuations, set STDMeas to zero
    if numel(temmark)>0,
        STDMeas(temmark)=0;
    end
    %    
    EOFStruct.TypicalError.Original.mag=[STDAbs STDMeas];
    %
end
%
%  Now investgate the errors across time, for all points
%  (space is down the rows, time is across the columns)
%
ErrToInvestigate=MassagedSignal-EOFStruct.ReconstructedSignal.Massaged;
EOFStruct.TypicalTimeError.Massaged=std(ErrToInvestigate);
%
ErrToInvestigate=OriginalSignal-EOFStruct.ReconstructedSignal.Original;
EOFStruct.TypicalTimeError.Original=std(ErrToInvestigate);
%
%  the routine is done
%
return;
%
