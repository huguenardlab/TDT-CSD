function [fn,aveData,ts,elapsed,stimdelay,f,csd] = tdtcsd_new(varargin)
% block store, which is an episode of predefined number of samples, with a
% pre trigger period.  then it will display all channels, in order from top
% to bottom and create one  graph for each sweep, along with CSD, if enabled

%%  here are the custom defaults, change here to modify output behavior

% N.B. FOR EVOKED RESPONSES THAT HAVE LARGE RESPONSES, ...
% turn trendnormalizing off
% .  JRH 3/22/2018
%startdir=',datestr(now, 'ddmmmyyyy')'; % starting directory to read files. Set to empty to use current directory

addpath('/home/shared/matlabscripts');
startdir='/home/shared/TDT/Projects/TDTrecordings/SHANK3/20210222/run-5'; % starting directory to read files. Set to empty to use current directory
baselineoffset=false; % calculate offset from first part of trace and the do DC offset to bring to zero
droppedChannels=[];
droppedEpisodes=[];
zeroedChannels = [];


% in this table is channel number is 0, then measure will ignore it
% this table lists,
% signalTitle,startOfMeasWindow,EndOfMeasWindo,polarity(-1 means look for
% in), channel number


WindowTable= {'Ch3 Early Source' 0.007 0.013 1 3
    'Ch3 Late Source' 0.012 0.030 1 3
    'Ch4 Early Sink' 0.007 0.013 -1 4
    'Ch4 Late Source' 0.012 0.030 1 4
    'Ch5 Early Sink' 0.007 0.013 -1 5
    'Ch5 Late Sink' 0.012 0.030 -1 5
    'Ch6 Early Source' 0.007 0.013 1 6
    'Ch6 Late Sink' 0.012 0.030 -1 6
    'Ch7 Early Sink' 0.012 0.030 -1 7
    'Ch7 Late Source' 0.012 0.030 1 7
    'Blanking' 0.0306 0.031 0 0
    'Zoom' 0.001 0.005 0 0
    'CSD Peak' 0.7 1 0 0};

data=[1];
analysisType='SimpleLFP';
polarityswitch=false; % should be false (0-1) for flipped polarity
trendnormalizing=true;
displaySweeps=true;
filtering = true;
hp=0.001; % hz low pass filtering
lp=200; % hz high pass filtering
lfpgain=-0.025; %vertical scaling for lfp plot
csdgain=-2;  % vertical scaling for csd plot
contourgain=2.5;  % max (& min) for contour plot
averaging=false;
blankSweeps=false;
clearplots=false;
mapping=false;
CSDPeakAnalysis=false;
widthPercent=.8; % i.e. 80% width
plotEachMeasure=false;
auxiliaryAnalysis=false;
TanyaAutoAnalysis=false;
AfterStim=0.0052;% Pre trigger of 5ms and stimduration of 0.20ms
stimStart=0.0306;
stimEnd=0.0310;
saving=false;  % file save of plot
plottingcsd=false; % include lower plots of CSD calculation, not just lfp
zooming=false; % include second column zoomed in on time
quashingnoisy=false; % number of SDs that trace variance has to be above to reject from average
quashthreshold=10;  % microvolts
alternating=false;
measurementsRelative=true;
plottingUnaveraged=false;% to plot time series for a unique stim without averaging
baselinepct=3; % percent of baseline to use for offset or trend normalizing (100% for former, 50% for latter)
plottingzero=true; % place dotted zero lines for each channel in CSD
fillingcsd=false;
stimdelay=.032; %s, position of stim within sweep
prestimtime=.03; % s amount of time to display before stim
poststimtime=0.15; % s, amount of post-stim response to show, 0.030 for 0.06 ms
usetdtstimtime=true;
measuring=true;
channels = [4; 3; 4; 5];
l3PresynSinkChannel = 4;
l2PostsynSinkChannel = 3;
l3PostsynSourceChannel = 4;
l5PostsynSinkChannel = 5;
defaultmeaschannels = true;
meas_time=.15;
meas_dur=.05;
displayall=false;
firstchan=1;
lastchan=16;
chans='1..16';
pause_dur=1;
earlydetrend=false;
plottingcontour=false;
fnamepre='';
subtract=false;
vectorize=false;
bluewhiteredmap=false;
resample=1;
numcsdsteps=25;
swps='all';
bathChange='5:iGluRX';
useDirr=false;
nomenu=0;
TanyaAutoAnalysis=false;
LogCSD=false;
stimIntensityVariable = true;
fileType='tev';
paramspath='/home/shared/matlabscripts/LFPparams/';
pvpmod(varargin); % convert input parameter name variable names to instances of those variables
%start with defaults, or the parameter file passed in arguments
if ~exist('paramfile')
    paramfile='default';
end
load([paramspath paramfile '.mat']); % default parameter file, since not using dialogbox
v2struct(Answer);
pvpmod(varargin);  % over write any parameters gotten from the parameter file that are passed in from the commmand line
% set up dialogbox structure
defans = struct([]);
defans2 = struct([]);

dlgcols=1;
Options.ReadButton = 'on';
Options.SaveButton = 'on';
Options.ApplyButton = 'off';
simplewidth=50;
notdone=1;
%fn='/home/shared/TDT/Projects/TDTrecordings/SHANK3/20230105/run-1/';
while notdone
    if exist('fn')
        inputfiles={fn};
        [~,~,ext]=fileparts(fn);
        Answer.fileType=ext(2:end);
    else
        if useDirr
            [file,fn]=uigetfile([startdir '/*.' fileType],'Select Parent Folder to Crawl Through');
            if ~file
                display('Cancelled and done');
                return
            end
            [~,~,inputfiles]=dirr([fn '/*.' fileType],'name');
        else
            inputfiles = uipickfiles('FilterSpec',startdir);
            if ~iscell(inputfiles) % cancel button hit , not a cell but a zero
                display('Cancelled and done');
                return
            end
        end
    end

    startdir1=inputfiles{1};
    lastslash=find(ismember(startdir1,'/'),1,'last'); %remove last part of path to get to parent directory
    startdir=startdir1(1:lastslash-1);

    analyzing=true;
    while analyzing

        editing=1;
        if nomenu
            editing=0;
        end
        while editing
            currentpos=0; %initialize
            if ~isfield(Answer,'DisplayParams')
                Answer.DisplayParams='None';
            end
            trying_push_buttons=false;
            if trying_push_buttons
                [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
                formats(currentrow,currentcol).type='button';
                formats(currentrow,currentcol).size = 150;
                prompt(currentpos,:)={'PlotScaling',[],[]};
                formats(currentpos,currentcol).callback = @(hobj,evt,h,k)csdPlotDetails(evt);
            else
                [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
                formats(currentrow,currentcol).type='list';
                formats(currentrow,currentcol).format='text';
                formats(currentrow,currentcol).style = 'radiobutton';
                formats(currentrow,currentcol).items = {'PlotScaling','OutputDetails','None'};
                prompt(currentpos,:)={'Edit Display Parameters', 'DisplayParams',[]};
                defans(1).DisplayParams = Answer.DisplayParams;
            end
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='list';
            formats(currentrow,currentcol).format='text';
            formats(currentrow,currentcol).style = 'radiobutton';
            %formats(currentrow,currentcol).items = {'SimpleLFP','InputOutput','CSDmean','TimeSeries','CSDswitch'};
            formats(currentrow,currentcol).items = {'SimpleLFP','CSDmean','InputOutput','TimeSeries','CSDswitch'};
            prompt(currentpos,:)={'Analysis type', 'analysisType',[]};
            defans(1).analysisType = analysisType;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'text';
            formats(currentrow,currentcol).size = 100;
            prompt(currentpos,:)={'Channel List', 'chans',[]};
            defans.chans = Answer.chans;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='edit';
            formats(currentrow,currentcol).format = 'text';
            formats(currentrow,currentcol).size = 100;
            prompt(currentpos,:)={'Sweeps', 'swps',[]};
            defans.swps = Answer.swps;
[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Average sweeps', 'averaging',[]};
defans.averaging = Answer.averaging;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Filter Sweeps', 'filtering',[]};
defans.filtering = Answer.filtering;

            if analyzing
                [Answernew,Cancelled] = inputsdlgjh(prompt,sprintf('TDT %s',startdir),formats,defans,Options);
                Answer=mergestructures(Answer,Answernew);
                
            else
                Cancelled=1;
            end

            if Cancelled==1
                if exist('filename')
                    return
                end
                clear fn;
                editing=0;
                analyzing=0; % this look breaker does not seem to work.  the desired behavior is to return to file selection menu, when cancelling from run menu
            end
            if ~Cancelled && strcmp(Answer.DisplayParams,'OutputDetails')
                Answer=csdPlotDetails(Answer);
                Answer.DisplayParams='None';
                Cancelled=1;
            end
            if ~Cancelled && strcmp(Answer.DisplayParams,'PlotScaling')
                Answer=csdScaling(Answer);
                Answer.DisplayParams='None';
                Cancelled=1;
            end

            if Cancelled==10
                % save parameter file
                [file,path] = uiputfile(paramspath,...
                    'Select file name to save');
                if file
                    save(fullfile(path,file),'Answer')
                    v2struct(Answer);
                end
            end
            if Cancelled==100
                % read parameter file
                [file,path] = uigetfile(paramspath,...
                    'Select param file to load');
                if file
                    load(fullfile(path,file));
                    v2struct(Answer);
                end
            end
            if ~Cancelled
                editing=0;  % ultimately want to put in a test for saving options here
            end
        end
        if analyzing
            if ~nomenu
                v2struct(Answer);  % this takes the return values from the dialog box and assigns them into the original variables
            end
            polarity=1;
            if polarityswitch
                polarity=-1;
            end
            %%
            if clearplots
                close all;
            end

            exts ='.tev';
            for f = 1:numel(inputfiles)
                try
                    [p1,f1,e1]=fileparts(inputfiles{f});
                    if strcmp( e1,'.mat')
                        exts=e1;
                    end
                    [fn, fpath, fnamepre, ext] = fLoop(f,inputfiles,exts);
                    if numel(inputfiles)<2
                        subtract=false;
                    end
                    %% read episodes
                    Answer.dataid='SSwp';
                    Answer.channelmap=1;
                    Answer.stimid='EpcV';
                    Answer.mapping=mapping;
                    Answer.LogCSD=LogCSD;
                    Answer.overwrite=false;

       

                    [data,ts,elapsed,stimdelay,si,stimVals,notes]=tdtepisodes6(fn,Answer); % here to look at lfp data
                    Answer.notes=notes;
                    if isnan(stimVals(end))
                        data = data(1:(end -1),:,:);
                    end
                    stimdelay=stimdelay; % +.001; % TDT generated stimuli are off by 1 ms
                    % at least for the configuration we are using in Sept
                    % 2019. Rec16ChanLFPStimUnfilteredGabrielle
                    Answer.stimVals=stimVals;
                    Answer.stimdelay=stimdelay;
                    si=(ts(2)-ts(1)); % assumes that the sample rate is constant, and indicated by first sample interval

                    Fs= 1/si;
                    Answer.Fs=Fs;
                    Answer.Fs=Fs;
                    data=data(:,firstchan:lastchan,:);
                    csdpeaks=[];

                    if strcmp(Answer.analysisType ,'InputOutput')
                        averaging=0;
                    end
                    if blankSweeps
                        keptsweeps=[];
                        blanksamples=[int16(stimStart/si):int16(stimEnd/si)];
                        for swp=1:size(data,1)
                            if std(data(swp,1,blanksamples)) >30e-6
                                keptsweeps=[keptsweeps swp];
                            end
                        end
                        data=data(keptsweeps,:,:);
                    end
                    swpnums=1:size(data,1);


                    if ~strcmp(swps,'all')
                        % user has specified the sweeps to use.  now check
                        % it

                        % than once
                        numswps=size(data,1);
                        swpnums=validatevector(swps,size(data,1));
                        if ~(swpnums(1)<1)
                            data=data(swpnums,:,:);
                        end

                    end


                    %% average data across stimulus intensities
                    i=1;
                    numpointsinbaseline=int32(size(data,3)*baselinepct/100);
                    if baselineoffset  % i.e. if the a/c coupling on the pz5 is turned off as it should be for slow responses

                        for j=1:size(data,1)
                            for i=1:size(data,2)
                                % calculate mean voltage for first x (e.g. 100) pts
                                baseline=mean(data(j,i,1:numpointsinbaseline));
                                % now offset by subtracting mean of first pts
                                data(j,i,:)=data(j,i,:)-baseline;
                            end
                        end
                    end

                    if droppedChannels
                        data(:,droppedChannels,:)=[];
                    end

                    if zeroedChannels
                        data(:,:,zeroedChannels) = zeros(1,size(data,3));
                    end


                    nSweeps=size(data,1);
                    nChannels = size(data,2);

                    if trendnormalizing  % i.e. if the a/c coupling on the pz5 is turned off as it should be for slow responses
                        for j=1:size(data,1) % each sweep/episode
                            for i=1:size(data,2) % each channel within sweep
                                d1=squeeze(data(j,i,:));
                                % calculate the linear trend from first and last points
                                trendtm=si*double([1:numpointsinbaseline size(data,3)-numpointsinbaseline+1:size(data,3)]);
                                trendpts=([d1(1:numpointsinbaseline)' d1(end-numpointsinbaseline+1:end)' ]);
                                if earlydetrend
                                    trendtm=si*double([1:numpointsinbaseline]); % the order matters.  need to start with si as it is a double!
                                    trendpts=([d1(1:numpointsinbaseline)' ]);
                                end
                                [R,m,b]=regression(trendtm,trendpts);
                                trendx=(1:size(data,3))*si;
                                trendline=trendx*m+b; % now offset by subtracing mean of first pts
                                data(j,i,:)=d1-trendline';
                                %figure; plot(squeeze(data(j,i,1:numpointsinbaseline)));
                            end
                        end
                    end
                    Dataprefilt=data*polarity;
                    if stimIntensityVariable
                        % you don't want to do averaging, because
                        % Brielle's code does the stim intensity gathering
                        % and averaging for you!
                        averaging=false;
                        Answer.averaging=false;
                    end
                    if averaging
                        if quashingnoisy
                            v=var(data,0,3); %look at variance in each sweep and channel
                            m=mean(v');
                            v1=var(v');
                            m2=mean(mean(v));
                            s2=std(std(v));

                            for i=1:size(data,2) % each channel
                                dropped=find(v(:,i)>quashthreshold*1e-9);
                                kept=find(v(:,i)<quashthreshold*1e-9);
                                if dropped
                                    a=sprintf('Dropping episodes %s from channel %d',mat2str(dropped),i);
                                    disp(a);
                                end
                                mean1(1,i,:)=mean(data(kept,i,:));
                            end
                            Dataprefilt=mean1*polarity;
                        else
                            Dataprefilt = polarity*mean(data);
                        end
                    else
                        Dataprefilt=polarity*data;
                    end
                    aveData=[];
                    if filtering
                        fprintf('Filtering %d sweeps, each with %d channels, \n',size(data,1),nChannels);
                        for i=1:size(Dataprefilt,1)
                            % filtfilt2(d,hp,lp,Fs,varargin)
                            for ch=1:nChannels
                                aveData(i,ch,:) = filtfilt2(squeeze(Dataprefilt(i,ch,:)),hp,lp,Fs, 1);
                            end
                        end
                    else
                        aveData=Dataprefilt;
                    end

                    if alternating
                        kept=(1:int32(size(aveData,1)/2))*2; % i.e. 1,3,5, etc
                        aveData=aveData(kept,:,:);
                    end

                    if droppedEpisodes
                        data(droppedEpisodes,:,:)=[];
                    end

                    if resample>1
                        for k=1:size(aveData,1)
                            for l=1:size(aveData,2)
                                aveData1(k,l,:)=downsample(aveData(k,l,:),resample,floor(resample/2));
                            end
                        end
                        aveData=aveData1;
                        clear aveData1;
                        si=si*resample;
                        ts=(1:size(aveData,3))*si;
                        Fs= 1/si;
                    end
                    if TanyaAutoAnalysis
                        % do this here to use the trend normalization done
                        % in gui form
                        %Fs
                        %TanyaCSDanalysis(data,ts,Answer,stimdelaytdt,fnamepre)
                    end



                    %% plot LFP and CSD
                    parts=strsplit(fn,'/');
                    spath='';
                    for p=1:size(parts,2)-2
                        spath=[spath parts{p} '/'];
                    end
                    startdir=spath;

                    if subtract && f==1
                        aveData2=aveData;
                    end
                    if subtract && f==2
                        aveData=aveData2-aveData;
                    end
                    if ~subtract || (subtract && f==2)


                        if any(strcmp(Answer.analysisType ,{'InputOutput','TimeSeries'})) % if measuring
                            spacing=0.1;
                            csd=squeeze(csdcalc3(aveData,spacing));
                            displaySweeps=0;  % don't display the lfp/csd plots if generating input out curves
                            if 0
                                if ~stimIntensityVariable

                                    aveCSD = squeeze(mean(csd)); % when averaging traces, we don't need to average them again, because this time it would be across channels
                                    peakAndAreaData = calcPeakAndArea3(csd,Answer);

                                    fn = strcat(fpath, '/', fnamepre, '_PeakAndAreaData_',datestr(now, 'ddmmmyyyy'));
                                    save( fn, 'peakAndAreaData');
                                elseif stimIntensityVariable
                                end
                            end
                            clear aveCSD

                            dataEachStim = sepDataByStimVals(stimVals, csd);
                            dataEachStimLFP = sepDataByStimVals(stimVals, aveData);


                            if length(dataEachStim.stim)>1 % i.e. have an input/output data file with mult stim intensities
                                Answer.windowcalcplot=true;
                                for stim=1:size(dataEachStim.stim,2)
                                    aveCSD(stim).stim = dataEachStim.stim(stim);
                                    if size(dataEachStim.data,2)>1
                                        aveCSD(stim).data = squeeze(mean(dataEachStim.data(stim,:,:,:)));
                                        aveLFP(stim).data=squeeze(mean(dataEachStimLFP.data(stim,:,:,:)));
                                    else  %% already have the mean!!
                                        aveCSD(stim).data = squeeze((dataEachStim.data(stim,:,:,:)));
                                        aveLFP(stim).data=squeeze((dataEachStimLFP.data(stim,:,:,:)));
                                    end
                                    aveCSD(stim).peakAndArea= calcPeakAndArea3(aveCSD(stim).data,Answer);
                                    peakAndAreaSummary = aveCSD(stim).peakAndArea;
                                end
                                LFPstruct.stim=dataEachStimLFP.stim;

                            else
                                Answer.windowcalcplot=false;

                                for epi=1:size(csd,1)
                                    aveCSD(epi).stim = stimVals(epi); %dataEachStim.stim(1);
                                    aveCSD(epi).data = squeeze((dataEachStim.data(1,epi,:,:))); % no mean!
                                    aveLFP(epi).data=squeeze((dataEachStimLFP.data(:,epi,:,:)));
                                    aveCSD(epi).peakAndArea = calcPeakAndArea3(aveCSD(epi).data,Answer);
                                    peakAndAreaSummary = aveCSD(epi).peakAndArea;
                                end
                                LFPstruct.stim=stimVals; %dataEachStimLFP.stim;

                            end
                            LFPstruct.aveLFP=aveLFP;
                            LFPstruct.si=si;
                            LFPstruct.stimdelay=stimdelay;
                            LFPstruct.elapsed=elapsed;
                            LFPstruct.notes=notes;
                            %save peak and area data from each stim in a table with
                            %each column representing the quantification of each stim
                            %intensity
                            fn = strcat(fpath,'/',fnamepre, '_aveCSDeachStim_',datestr(now, 'ddmmmyyyy'));
                            %test if the file exist here and use an input from the user
                            if length(dataEachStim.stim)>0  && size(dataEachStim.data,2)>1

                                save( fn, 'aveCSD');
                                fn = strcat(fpath,'/',fnamepre, '_aveLFPeachStim_',datestr(now, 'ddmmmyyyy'));
                                save( fn, 'LFPstruct');
                            end
                            % the following collects all the measures for this
                            % particular tank/block file
                            resultsFields=fieldnames(aveCSD(1).peakAndArea);
                            measures=[]; % clear it out here
                            for i=1:size(aveCSD,2)
                                measures(i,:,:)=aveCSD(i).peakAndArea.measures(:,:);
                            end
                            % try to save only an array with all peakdata for each stim
                            peakData=[];
                            for i=1:size(aveCSD,2)
                                peakData(i,:)=measures (i,1,:);
                            end
                            fileName= strcat(fpath, '/', fnamepre, '_peakDataSummary_',datestr(now, 'ddmmmyyyy'));
                            save( fileName, 'peakData')
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        bc=Answer.bathChange; % bath change sweeps and desriptors                                    
                                        bc2=strsplit(bc,',');
                                                 ISI=mean(diff(elapsed));
                               
                                        for bc3=1:size(bc2,2)
                                            bc4=strsplit(bc2{bc3},':');
                                            bathswitchsweep(bc3)=str2num(bc4{1}); %Sweep where the drug is IN
                                            bathswitchtime(bc3)=bathswitchsweep(bc3)*ISI/60;
                                            bathswitchdesc{bc3}=bc4{2};
                                        end
                                   
                            if length(dataEachStim.stim)>=1
                                Answer.windowcalcplot=true;
                                %close all;
                                %%%%%%%%PLOT MEASUREMENTS%%%%%%%%%%%%%%%%%%%%%%%%
                                if size(measures,2)>1 % we only do these next two sets of plots for an intensity series
                                    for i=1:size(measures,2) % this code is now generic and will plot for all measures
                                        figure;plot((1:size(measures,1)),squeeze(measures(:,i,:)));
                                        title([fnamepre,' ',aveCSD(1).peakAndArea.measurenames{i}],'Interpreter','none');
                                        if length(dataEachStim.stim)>1
                                            xlabel('Stimulus (V, 1V/100uA)');
                                        else
                                            yl=ylim();
                                            hold on;
                                             for bc3=1:size(bc2,2)
                                                 plot([bathswitchsweep(bc3),bathswitchsweep(bc3)],yl,'--k');
                                                 text(bathswitchsweep(bc3),mean(yl),['  ' bathswitchdesc{bc3}]);
                                             end

                                      
                                            xlabel('Stimulus #');
    
                                        end
                                        legend(aveCSD(1).peakAndArea.descriptors);
                                    end
                                else Answer.windowcalcplot=false;
                                end
                                % the next code will plot individual channels responses
                                % across all intensities, for the channels listed in
                                % chanstoplot
                                zoomrow=find(contains(WindowTable(:,1),'Zoom'));
                                prestimtime1=WindowTable{zoomrow,2};
                                poststimtime1=WindowTable{zoomrow,3};
                                xzoom2=[stimdelay-prestimtime1 stimdelay+poststimtime1];
                                pltdata=[];
                                chanstoplot=[1,2,3,4,5,6,7];
                                %%%%%%%%%%%%%Plot channels %%%%%%%%%%%%%%
                                chansanalyzed=cell2num(WindowTable(:,5))-1;
                                
                                for chn=1:size(chanstoplot,2)
                                    thischan=chanstoplot(chn);
                                    for i=1:size(aveCSD,2) % this code is now generic and will plot for all measures
                                        pltdata(chn,i,:)=aveCSD(i).data(thischan,:);
                                    end
                                    figure;
                                    thischanan=find(chansanalyzed==thischan);
                                    lgnd=sprintfc('%.0fs',elapsed-elapsed(1));
                                    if length(dataEachStim.stim)>=1
                                        lgnd=sprintfc('%dV',dataEachStim.stim');
                                    end
                                    lgnd2={};
                                    if thischanan
                                        for roi=1:size(thischanan)
                                            startwin=WindowTable{thischanan(roi),2};
                                            endwin=WindowTable{thischanan(roi),3};

                                            if Answer.measurementsRelative
                                                startwin=startwin+Answer.stimdelay;
                                                endwin=endwin+Answer.stimdelay;
                                            end
                                            thisspan=int16([startwin,endwin]/si);
                                            if WindowTable{thischanan(roi),4}==-1
                                                thisval=min(min(pltdata(chn,:,thisspan(1):thisspan(2))));
                                            else
                                                thisval=max(max(pltdata(chn,:,thisspan(1):thisspan(2))));
                                            end
                                            plot([startwin,endwin]*1000,[thisval,thisval]*1.05,'LineWidth',3);
                                            lgnd2=[lgnd2; WindowTable{thischanan(roi),1}];
                                            hold on;
                                        end
                                        lgnd=[lgnd2;lgnd];
                                    end
                                    plot(ts*1000,squeeze(pltdata(chn,:,:))');
                                    %plot(ts*1000,squeeze(pltdata(thischan,1:2,:))');
                                    timeSeriesColorGradient= 1; % switch to turn off color gradient below

                                    if strcmp(Answer.analysisType,'TimeSeries') && timeSeriesColorGradient == 1 % assuming a timeseries of a single stim intensity, there will be more than 20 traces
                                        % generate and assign color triplets to lines for
                                        % smooth color transitions instead of random rainbow
                                        linecolormap = zeros(size(pltdata,2),3);
                                        mid_point = floor(size(pltdata,2)/2);
                                        linecolormap(:,1) = linspace(0,1,size(pltdata,2));
                                        linecolormap(1:mid_point,2) = linspace(1,0,mid_point);
                                        linecolormap(mid_point+1:end,2) = linspace(0,1,length(linecolormap)-mid_point);
                                        linecolormap(:,3) = linspace(1,0,size(pltdata,2));
                                        colororder(gca,linecolormap);
                                        colormap(linecolormap);

                                        %ISI=15;%interval between sweeps, Yes InterStimulusInterval, ISI
                                        ISI=mean(diff(elapsed));
                                        swptimes=(0:size(colormap,1)-1)/(60/ISI);
                                        maxtic=floor(max(swptimes));
                                        numtickestimate=5;  % this is just a guess that we want about 5 tics
                                        actualtics=floor(maxtic/numtickestimate);
                                        actualticspacing=floor(maxtic/numtickestimate);
                                        tics=sort([(0:actualticspacing:maxtic) bathswitchtime]); % you can add other tics here too
                                        ticleg=strsplit(num2str(tics));
                                        ticleg{1}=[ticleg{1} ' min'];
                                        for bc3=1:size(bc2,2)
                                            bathswitchtic=find(tics==bathswitchtime(bc3)); % and this code finds the added tic number that corresponds to THIS added tic, but will not work automatically for a second added tic
                                            ticleg{bathswitchtic}=bathswitchdesc{bc3};
                                        end
                                        colorbar('Ticks',tics/max(swptimes),'TickLabels',ticleg);
                                        clear linecolormap
                                        clear mid_point
                                    end

                                    autoscalept1=int16((stimdelay+.002)/si); % start autoscaling 2ms after stim pulse start
                                    autoscalept2=length(ts);
                                    as1=min(min(min(pltdata(chn,:,autoscalept1:autoscalept2))));
                                    as2=max(max(max(pltdata(chn,:,autoscalept1:autoscalept2))));
                                    ylim([as1 as2]*1.2);
                                    xlim([stimdelay-.001 ts(end)]*1000);
                                    legend(lgnd);
                                    xlabel('Time (ms)');
                                    ylabel('CSD (mV/mm^2)');
                                    title(sprintf('%s Channel %d',fnamepre,thischan),'Interpreter','none');
                                    if zooming ==1
                                        set(gca,'xlim',xzoom2*1000); % can also just say xlim([xzoom2]);
                                    end
                                end
                            end


                            %end
                        end
                        if any(strcmp(Answer.analysisType ,{'CSDswitch'})) % if measuring

                            switchparts = strsplit(Answer.switchsweep,',');
                            for s=1:size(switchparts,2)
                                tempLFP(s,:,:)=squeeze(mean(data(str2num(switchparts{s}),:,:),1));
                            end
                            thesesweeps=size(switchparts,2);
                            for s=1:size(switchparts,2)-1
                            tempLFP(s+thesesweeps,:,:)=tempLFP(s,:,:)-tempLFP(s+1,:,:); % control - switch
                            end
                            for s=1:size(tempLFP,1)
                                thisanswer=Answer;
                                if s<thesesweeps+1
                                    thisanswer.extranotes=['Swps:',switchparts{s}];
                                else
                                    thisanswer.extranotes=sprintf('Condition %d - Condition %d',s-thesesweeps-1,s-thesesweeps);
                                end
                                displaytdtsweeps(fn,tempLFP(s,:,:),ts,elapsed,stimdelay,1,thisanswer);

                            end
                            displaySweeps=0;
                        end
                        if plottingUnaveraged
                            %lgnd=sprintfc('%dV',dataEachStim.stim);
                            spacing=0.1;
                            csd=squeeze(csdcalc3(aveData,spacing));
                            chanstoplot=[1,2,3,4,5];
                            for chn=1:size(chanstoplot,2)
                                thischan=chanstoplot(chn);
                                for i=1:size(csd,1) % this code is now generic and will plot for all sweeps0
                                    pltdata(chn,i,:)=csd(i,thischan,:);
                                end
                                figure;
                                plot(ts*1000,squeeze(pltdata(chn,:,:))');
                                xlabel('Time (ms)');
                                ylabel('CSD (mV/mm^2)');
                                %legend(lgnd);
                                title(sprintf('%s Channel %d',fnamepre,chanstoplot(chn)),'Interpreter','none');
                            end
                        end
                        nplots=size(aveData,1);
                        if strcmp(Answer.analysisType ,'SimpleLFP')
                            displayall=1;
                            nplots=1;
                        end


                        swp=sprintf('Sweep_%03d',swpnums(1));
                        %if displayall
                        %   swp=sprintf('Sweeps_%03d-%03d',1,i);
                        %end
                        if averaging || displayall || ~displaySweeps                                continuous=diff(swpnums);
                            swp1='';
                            if averaging
                                swp1='Average_';
                            end
                            swp=[swp1 'Sweeps'];
                            if any(continuous(:)>1)
                                for s=1:size(swpnums,2)
                                    swp=[swp sprintf('_%d',swpnums(s)) ];
                                end
                                % i.e. non-continuous array
                            else
                                swp=sprintf('%s-%d-%d',swp,swpnums(1),swpnums(end));
                            end
                        end
                        gtitle = sprintf('%s/%s_%s',fpath,fnamepre,swp);
                        %                             if CSDPeakAnalysis
                        %                                 csdpeaks.elapsed=elapsed;
                        %                                 csdpeaks.episeconds=elapsed-elapsed(1);
                        %                                 save([gtitle '_CSDPeaks'],'csdpeaks');
                        %                             end
                        if auxiliaryAnalysis
                            auxAnalysis
                            %average_CSD

                        end
                        if displaySweeps
                            if exist('dataEachStim') && length(dataEachStim.stim)>1  && measuring
                                dataEachStim=sepDataByStimVals(stimVals,aveData);
                                for stim=1:size(dataEachStim.stim,2)
                                    aveData2(stim,:,:) = squeeze(mean(dataEachStim.data(stim,:,:,:)));
                                end
                                aveData=aveData2;
                                aveData2=[];
                                nplots=size(aveData,1);
                            end
                            for i =1:nplots
                                fignum=1;

                                if numel(inputfiles)>1 && ~subtract
                                    fignum=10+f;
                                end


                                swp=swpnums(i);
                                if averaging
                                    swp=0;
                                end

                                % if ~evoked
                                %    displaytdtsweeps(fn,aveData(i,:,:),ts,elapsed,'plottingcsd',plottingcsd,'zooming',zooming,'swp',swp); %11 5HT 13 for med
                                %else
                                %'plottingcsd',plottingcsd,'zooming', ...
                                %    zooming,'swp',swp,'displayoffset1',lfpgain,'displayoffset2', ...
                                %    csdgain,'colorscale', contourgain, 'plottingzero',plottingzero, ...
                                %    'fillingcsd',fillingcsd);
                                %end

                                % we could put in a conditional test to execute
                                % helper analysis program that would do whatever we
                                % want.  If we edit it outside of matlab editor,
                                % then we may even be able to do live updates of
                                % the analysis
                                % the following code creates a subtracted LFP MEA
                                % data structure, for looking at e.g. drug effects
                                %                         ctrl=mean(data(1:8,:,:));
                                %                         earlydnqx=mean(data(12:13,:,:));
                                %                         dnqxdependent=earlydnqx-ctrl;
                                %                         aveData=-dnqxdependent;

                                Answer.csdpeaks=csdpeaks;

                                if displayall
                                    displaytdtsweeps(fn,aveData,ts,elapsed,stimdelay,swp,Answer);
                                else
                                    displaytdtsweeps(fn,aveData(i,:,:),ts,elapsed,stimdelay,swp,Answer);
                                end
                                answer.csdpeaks=[] ;
                                if CSDPeakAnalysis
                                    done=0;
                                    fprintf('Click twice on CSD contour to get two X/Y points.\n');
                                    fprintf('Slope will be calculated.  Hit Esc key twice to finish.\n');
                                    datacursormode off;
                                    while ~done
                                        [x,y,b]=ginput(4);  % we will return four points!!
                                        %fprintf('%d %s',b,b);
                                        if b(1)==27
                                            done =1;
                                        else
                                            fprintf('Amplitude #1 %.1f, Amplitude #2 %.1f, difference: %.1f mV/mm\n',y(1),y(2),y(2)-y(1));
                                            fprintf('Time #1 %.2f, Time #2 %.2f, difference: %.2f ms\n',x(1)*1000,x(2)*1000,(x(2)-x(1))*1000);
                                            fprintf('Velocity: %.2f m/s from contour, %.2f m/s from CSD.\n', diff(y)*.0001/diff(x),-diff(y)*.0001/diff(x)/Answer.csdgain);
                                            summaryfile='/home/shared/TDT/callosum_summary.csv'
                                            sumfile=fopen(summaryfile,'at');  % a means append, add to the file, t means text file
                                            fprintf(sumfile,'%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n',fnamepre,swps,x(1)*1000,y(1),x(2)*1000,y(2),x(3)*1000,y(3),x(4)*1000,y(4));
                                            fclose(sumfile);
                                        end
                                    end
                                    fprintf('Done measuring slopes.\n');
                                end
                                if saving
                                    if 1 %~displayall || displayall && i == size(aveData,1)
                                        % save file in path one folder below the tsv folder


                                    end
                                    print('-fillpage',gtitle,'-dpdf')
                                end
                                %saveas (gcf,gtitle,'pdf');

                            end

                            hold off;
                        end
                    end
                    %
                    %cmd1=sprintf('psmerge -o%s.ps *eps ; ps2pdf %s.ps %s.pdf;',f,f,f);
                    % cmd1=sprintf('gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET  -sOutputFile=%s.pdf *PAGE* && rm *PAGE*;',f);
                    %cmd1=sprintf('gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER  -sFONTPATH=/usr/local/share/fonts/default/Type1 -sOutputFile=%s.pdf *eps;',fnamepre);
                    % system(cmd1);
                catch e
                    msg=string(e.message);
                    msgi=2;
                    for stk=1:size(e.stack,1)
                        msg(msgi)=['function ' e.stack(stk).name];
                        msgi=msgi+1;
                        msg(msgi)=['line ' num2str(e.stack(stk).line)];
                        msgi=msgi+1;
                    end
                    waitfor(msgbox(msg,'Error in tdtmua'));

                end
            end
        end
        if nomenu
            analyzing = false;
            notdone=false;
        end
    end
end
end







