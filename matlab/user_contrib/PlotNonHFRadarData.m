function PlotNonHFRadarData(TemFigHandle,TimeStep,DateNumSelect,TimeAxisIn,DataIn,SymbType,SymbRange,DataRange,ColorMapType,MapPos)
%
%  PlotNonHFRadarData(TemFigHandle,TimeStep,DateNumSelect,TimeAxisIn,DataIn
%  ,SymbType,SymbRange,DataRange,ColorMapType,MapPos);
%
%  to place a symbol on a field of HF Radar velocity vectors
%
%  The value of TimeStep is used to plot the data, unless it is equal to
%  NaN.  If so, the value of DateNumSelect is used to find which value to
%  plot.  TimeAxisIn can be NaN if the TimeStep value is set.
%
%  Example useage, to plot TimeStep 1 with square symbols:
%
% PlotNonHFRadarData(TemFigHandle,1,NaN,NaN,'s',[10 20],[-15 15],'jet',[longitude latitude]);
%
%  Inputs:
%
%  TemFigHandle:  the handle of the prviously held figure of CODAR vectors
%  TimeStep:      the number of the data point to plot
%  DataIn:        the scalar Data - can be a row or column vector
%  SymbType:      the symbol to use for plotting - can be 's', or 'o', for
%                 example.  See plot for more details.
%  SymbRange:     The range in size of the symbols (MarkerSize).  Good ranges to use are
%                 [11 20].  Format is [minrange maxrange]
%  DataRange:     The range of the data to use for deciding what color to
%                 make the symbols and to scale the marker sizes
%  ColorMapType:  The colormap to use, see colormap.  'jet' is a good one
%                 if you want to vary from blue to red.
%  MapPos:        The [lon lat] position of the location to plot the
%                 symbol.
%
%  Outputs:       A symbol on the HF Radar map.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: PlotNonHFRadarData.m 2007-08 cmh $	
%
% Copyright (C) 2007 Christopher M. Halle
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
figure(TemFigHandle);
%
%  Step 1 - find the TimeStep
%
if isnan(TimeStep),
    if isnan(DateNumSelect),
        disp('both TimeStep and DateNumSelect have been set to NaN')
        disp('PlotNonHFRadarData routine ending')
        return;
    else
        [MinValDate,TimeStep]=min(abs(TimeAxisIn-DateNumSelect));
    end
end
%
try
    eval(['TemMap=' ColorMapType '(100);']);
catch
    disp('error in specifying ColorMapType')
    disp('jet colormap assumed')
    TemMap=jet(100);
end
%
CurrMeas=DataIn(TimeStep);
%
if isnan(CurrMeas),
    return;
end
%
FullScale=nanmax(DataRange)-nanmin(DataRange);
PartScale=CurrMeas-nanmin(DataRange);
RelScale=PartScale/FullScale;
RelScaleColor=round(100*RelScale);  % convert to percent to get 0 to 100 values for the colormap
%
if RelScaleColor<=0,
    RelScaleColor=1;
end
%
if RelScaleColor>=100,
    RelScaleColor=100;
end
%
TemColor=TemMap(RelScaleColor,:);
%
SymbDelta=max(SymbRange)-min(SymbRange)+1;
RelScaleSymbol=round(SymbDelta*RelScale);  % convert to get numbers for symbol size
%
if RelScaleSymbol<=0,
    RelScaleSymbol=1;
end
%
if RelScaleSymbol>=SymbDelta,
    RelScaleSymbol=SymbDelta;
end
%
TemMarkerSize=RelScaleSymbol+min(SymbRange)-1;
%
m_plot(MapPos(1),MapPos(2),SymbType,'Color',TemColor,'MarkerSize',TemMarkerSize,'LineWidth',[2]);
%
%  routine is done
%
return;
%
