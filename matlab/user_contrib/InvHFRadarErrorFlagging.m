function InvHFRadarErrorFlagging(DirIn,FileIn,StructName,BaseMapLocation)
%
%  InvHFRadarErrorFlagging(DirIn,FileIn,StructName,BaseMapLocation);
%
%  To investigate the error flagging for the HF Radar currents.  Helps to
%  asnwer the question of "was the error flagging appropriate"? and "what
%  if we make the flagging more severe?"  Good to run on uncleaned currents
%  before setting flags.
%
%  Usage:
%  DirIn=the directory containing the file with the Tuv structure, in
%  single quotes (ex = '/users/chrishalle/HFRadarStuff/')
%  FileIn=the mat file containing the Tuv structure, in single quotes
%  (ex='Totals.mat')
%  StructName=the structure name, in single quotes (ex, 'TUVclean')
%  BaseMapLocation=the full filename of the map used to plot the HF Radar
%  vectors
%
%  User is prompoted for which of the errors to investigate.  If user
%  wishes to investgate another error, then the prgram must be run again.
%
%  4 figures are made - one of unflagged
%  velocities, one of onflagged error levels, one of flagged velocities,
%  and one of flagged error levels.
%
%  User is prompted for which timestep to choose.  User can step through
%  and choose several timesteps, and see how the error choices affect the
%  velocities.
%
%  Get lat lon limits from basemap
%
%  setting up the data to plot is done by setting up strucures, which is
%  unecessarily complicated for this, but will allow for easy expasnion in
%  the future if we want to plot some data with vectors and not colordots
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: InvHRRadarErrorFlagging.m 2007-08 cmh $	
%
% Copyright (C) 2007 Christopher M. Halle
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
load(BaseMapLocation)
LonLim=[nanmin(ncst(:,1)) nanmax(ncst(:,1))];
LatLim=[nanmin(ncst(:,2)) nanmax(ncst(:,2))];
clear Area k ncst
%
disp('loading file, please be patient')
pause(1);
%
StructFileIn=fullfile(DirIn,FileIn);
%
load(StructFileIn)
%
disp('file loaded')
pause(1);
%
eval(['NumFigs=numel(' StructName '.TimeStamp);']);  % actually, the number of available timestamps
%
%  check limits in the input structure, see if we should use those instead
%  of the limits from basemap when making the plots
%
eval(['TemLim=' StructName '.LonLat(:,1);']);
LonLim(1)=min([LonLim(1) nanmin(TemLim)]);
LonLim(2)=max([LonLim(2) nanmax(TemLim)]);
eval(['TemLim=' StructName '.LonLat(:,2);']);
LatLim(1)=min([LatLim(1) nanmin(TemLim)]);
LatLim(2)=max([LatLim(2) nanmax(TemLim)]);
%
clear TemLim
%
%  Choose which error estimate to use
%
eval(['ErrReturn=ChooseErrorEstimate(' StructName ');']);
%
if isequal(ErrReturn,'None'),
    return;
end
%
%  Find start TimeStep and end TimeStep in the data - used b/c sometimes we
%  have radials from one site and not another, etc., so we don't always end
%  up with data from all times.
%
DataFound=NaN*ones(1,NumFigs);
for TimeStep=1:NumFigs,
    eval(['TemVal=' StructName '.U(:,TimeStep);']);
    if sum(~isnan(TemVal))>=1,   % we have some measurements
        eval(['TemVal=' StructName '.V(:,TimeStep);']);
        if sum(~isnan(TemVal))>=1,
            DataFound(TimeStep)=1;
        end
    end
end
%
temmarktstep=find(~isnan(DataFound));
if numel(temmarktstep)>0,
    disp(['the first timestep for which data is available is ' num2str(min(temmarktstep))]);
    disp(['the last timestep for which data is available is ' num2str(max(temmarktstep))]);
    disp(['there are a total of ' num2str(NumFigs) ' timestamps in the file'])
    disp('hit return to continue')
    pause
else
    disp('no times with valid data found')
    disp('routine ending')
    return;
end
%
scrsz = get(0,'ScreenSize');  % will be used to place figures
%
LookAgain=1;
%
while LookAgain,
    %
    LookResponse=questdlg('Do you wish to look at another time?','Continue?','LookYes','LookNo','LookYes');
    %
    switch LookResponse
        %
        case 'LookYes'
            %
            StopSelectTime=0;
            %
            while ~StopSelectTime,
                %
                prompt={'Enter TimeStep to examine:'};
                name='TimeStep To Examine';
                numlines=1;
                temstr=[num2str(min(temmarktstep))];
                defaultanswer={temstr};
                xlimitscell=inputdlg(prompt,name,numlines,defaultanswer);
                TimeStep=[str2num(char(xlimitscell{1}))];
                clear xlimitscell
                TitleStr=['TimeStep ' num2str(TimeStep) ' Selected'];
                %
                TemCheck=intersect(temmarktstep,TimeStep);
                if numel(TemCheck)<1,
                    [minval,TemPos]=min(abs(temmarktstep-TimeStep));
                    TimeStep=temmarktstep(TemPos);
                    TitleStr=['TimeStep Not Available, closest TimeStep is ' num2str(TimeStep)];
                end
                %
                TemFig1=figure;
                %
                plotBasemap(LonLim,LatLim,BaseMapLocation,'lambert', 'patch', [0.5 0.5 0.5] );
                hold
                eval(['[handles,TimeIndex]=plotData(' StructName ',''m_vec'',TimeStep,0.01);']);
                xlabel('longitude')
                ylabel('latitude')
                title(TitleStr);
                colorbar('vert');
                %
                pause(2);
                %
                TimeResponse=questdlg('Does this TimeStep selection look o.k.?','TimeStep?','Yes','No','Yes');
                %
                switch TimeResponse
                    case 'Yes'
                        StopSelectTime=1;
                    case 'No'
                        %
                        %  do nothing
                        %
                end
                %
                delete(TemFig1);
                %
            end
            %
            %  At this point, we have selected the time to look at
            %
            TemFig1=figure('Position',[1 0.6*scrsz(4) scrsz(3)/2 0.4*scrsz(4)]);
            TemFig2=figure('Position',[scrsz(3)/2 0.6*scrsz(4) scrsz(3)/2 0.4*scrsz(4)]);
            TemFig3=figure('Position',[1 1 scrsz(3)/2 0.4*scrsz(4)]);
            TemFig4=figure('Position',[scrsz(3)/2 1 scrsz(3)/2 0.4*scrsz(4)]);
            %
            %  the unclean currents
            %
            figure(TemFig1);
            %
            plotBasemap(LonLim,LatLim,BaseMapLocation,'lambert', 'patch', [0.5 0.5 0.5] );
            hold
            eval(['[handles,TimeIndex]=plotData(' StructName ',''m_vec'',TimeStep,0.01);']);
            xlabel('longitude')
            ylabel('latitude')
            title(['Uncleaned Currents, Time Step ' num2str(TimeStep)]);
            colorbar('vert')
            %
            %  uncleaned error estimates
            %
            figure(TemFig2)
            %
            eval(['SizeNewStruct=numel(' StructName '.U(:,1));']);
            TTem = TUVstruct( [SizeNewStruct 1], 1 );
            eval(['TTem.TimeStamp=' StructName '.TimeStamp(TimeStep);']);
            eval(['TTem.LonLat=' StructName '.LonLat;']);
            %
            ErrSet=0;
            if numel(char(ErrReturn))>=13, % the string 'TotalsNumRads' has 13 characters
                SizeErrReturn=numel(char(ErrReturn));
                TemErrReturnChar=char(ErrReturn);
                if isequal(TemErrReturnChar(SizeErrReturn-13+1:SizeErrReturn),'TotalsNumRads'),
                    eval(['TTem.U=' StructName '.OtherMatrixVars.makeTotals_TotalsNumRads(:,TimeStep);']);
                    TTem.V=zeros(size(TTem.U));
                    ErrSet=1;
                end
            end
            %
            if ~ErrSet,  %Error to use was not the NumRads
                %
                %  error to use is one of the standard calculated errors that
                %  was included in the input structure
                %
                eval(['StandardErrorNum=numel(' StructName '.ErrorEstimates);']);
                ErrFound=0;
                for jtype=1:StandardErrorNum,
                    eval(['TemErr=' StructName '.ErrorEstimates(jtype).Type;']);
                    if isequal(TemErr,ErrReturn),
                        ErrFound=jtype;
                    end
                end
                %
                %  we now know the error to use
                %
                eval(['TTem.U=' StructName '.ErrorEstimates(ErrFound).TotalErrors(:,TimeStep);']);
                TTem.V=zeros(size(TTem.U));
            end
            plotBasemap(LonLim,LatLim,BaseMapLocation,'lambert', 'patch', [0.5 0.5 0.5] );
            hold
            CAxisToUse=[nanmin(TTem.U) nanmax(TTem.U)];
            %InfoOnly=questdlg('look at keyboard','Error Info','OK','OK','OK');
            %keyboard
            [h,ts] = colordot(TTem.LonLat(:,1),TTem.LonLat(:,2),TTem.U(:,1),CAxisToUse,'m_line');
            colorbar('vert')
            title('Total Error Estimate, Unthresholded')
            %
            InfoOnly=questdlg('Values < NumRads will be flagged','Error Info','OK','OK','OK'); 
            InfoOnly=questdlg('All Others values > error flagged','Error Info','OK','OK','OK'); 
            InfoOnly=questdlg('Hit return to continue','Error Info','OK','OK','OK'); 
            pause
            %
            SelectMoreErrLevels=1;
            %
            while SelectMoreErrLevels,
                %
                ContinueSelecting=questdlg('Do you wish to continue selecting levels?','Select Levels','Yes','No','Yes');  % change to while loop?
                switch ContinueSelecting
                    case 'Yes'
                        %
                        delete(TemFig3);
                        delete(TemFig4);
                        %
                        eval(['TTemStruct=' StructName ';']);
                        TTemErr=TTem;
                        %
                        prompt={'Enter the limit to use'};
                        name='Total Error Value For Flagging:';
                        numlines=1;
                        defaultanswer={'0'};
                        xlimitscell=inputdlg(prompt,name,numlines,defaultanswer);
                        ErrLimit=[str2num(char(xlimitscell{1}))];
                        clear prompt name numlines defaultanswer xlimitscell
                        %
                        ErrSet=0;
                        if numel(char(ErrReturn))>=13, % the string 'TotalsNumRads' has 13 characters
                            SizeErrReturn=numel(char(ErrReturn));
                            TemErrReturnChar=char(ErrReturn);
                            if isequal(TemErrReturnChar(SizeErrReturn-13+1:SizeErrReturn),'TotalsNumRads'),
                                %
                                %  we need to flag according to the number of radials
                                %
                                ErrSet=1;
                                %
                                temmark=find(TTemErr.U(:,1)<=ErrLimit);
                                if numel(temmark)>=0,
                                    TTemStruct.U(temmark,TimeStep)=NaN;
                                    TTemStruct.V(temmark,TimeStep)=NaN;
                                    %
                                    TTemErr.U(temmark,1)=NaN;  % also set the corresponding error levels to NaN
                                    TTemErr.V(temmark,1)=NaN;
                                end
                            end
                        end
                        %
                        if ~ErrSet,
                            temmark=find(TTemErr.U(:,1)>=ErrLimit);
                            if numel(temmark)>=0,
                                TTemStruct.U(temmark,TimeStep)=NaN;
                                TTemStruct.V(temmark,TimeStep)=NaN;
                                %
                                TTemErr.U(temmark,1)=NaN;  % also set the corresponding error levels to NaN
                                TTemErr.V(temmark,1)=NaN;
                            end
                        end
                        %
                        %  we now have the velocity vectors and the errors set up to
                        %  plot
                        %
                        TemFig3=figure('Position',[1 1 scrsz(3)/2 0.4*scrsz(4)]);
                        %
                        figure(TemFig3);
                        %
                        plotBasemap(LonLim,LatLim,BaseMapLocation,'lambert', 'patch', [0.5 0.5 0.5] );
                        %
                        hold
                        [handles,TimeIndex]=plotData(TTemStruct,'m_vec',TimeStep,0.01);
                        xlabel('longitude')
                        ylabel('latitude')
                        title(['Cleaned Currents, Time Step ' num2str(TimeStep)]);
                        colorbar('vert')
                        %
                        TemFig4=figure('Position',[scrsz(3)/2 1 scrsz(3)/2 0.4*scrsz(4)]);
                        %
                        figure(TemFig4);
                        %
                        plotBasemap(LonLim,LatLim,BaseMapLocation,'lambert', 'patch', [0.5 0.5 0.5] );
                        hold
                        CAxisToUse=[nanmin(TTemErr.U) nanmax(TTemErr.U)];
                        %
                        if (sum(~isnan(CAxisToUse))>1&(CAxisToUse(1)~=CAxisToUse(2))&(CAxisToUse(2)>CAxisToUse(1))),
                            %
                            [h,ts] = colordot(TTemErr.LonLat(:,1),TTemErr.LonLat(:,2),TTemErr.U(:,1),CAxisToUse,'m_line');
                            colorbar('vert')
                            title('Errors, THRESHOLDED')
                        else
                            title('Errors, THRESHOLDED, all values NaNs')
                        end
                        %
                    otherwise
                        %
                        SelectMoreErrLevels=0;
                        %
                        delete(TemFig1);
                        delete(TemFig2);
                        delete(TemFig3);
                        delete(TemFig4);
                        %                        
                end
            end
        case 'LookNo'
            %
            LookAgain=0;
    end
end
%
%  the routine is done
%
return;
%
function [ErrReturn]=ChooseErrorEstimate(StructIn)
%
%  [ErrReturn]=ChooseErrorEstimate(StructIn);
%
%  to display what error estimates are available and to return the string
%  corresponding to the error estimate to the calling routine
%
%  Let's actually set up the calling routine to pass teh actuial structure,
%  not just the name, that way we don't have to worry about converting in
%  here.
%
NumErrorsIncluded=numel(StructIn.ErrorEstimates);
NumErrorsIncluded=NumErrorsIncluded+1;  %  we can also choose NumRads here
%
ErrorsIncluded=cell(NumErrorsIncluded,1);
for jerr=1:NumErrorsIncluded-1,
    ErrorsIncluded{jerr,1}=StructIn.ErrorEstimates(jerr).Type;
end
ErrorsIncluded{NumErrorsIncluded,1}='NumberOfRadials';
%
[Selection,OK]=listdlg('PromptString','Select An Error Method:','SelectionMode','single',...
    'ListString',ErrorsIncluded);
%
if ~OK,
    disp('no error selection method chosen')
    disp('routine will end')
    ErrReturn='None';
end
%
if Selection<NumErrorsIncluded,
    ErrReturn=StructIn.ErrorEstimates(Selection).Type;
else
    ErrReturn='OtherMatrixVars.makeTotals_TotalsNumRads';
end
%
%  the routine is done
%
return;
%

