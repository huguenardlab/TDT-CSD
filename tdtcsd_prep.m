function [fn,aveData,ts,elapsed,stimdelay,f,csd] = tdtcsd_prep(varargin)
% block store, which is an episode of predefined number of samples, with a
% pre trigger period.  then it will display all channels, in order from top
% to bottom and create one  graph for each sweep, along with CSD, if enabled

%%  here are the custom defaults, change here to modify output behavior

% N.B. FOR EVOKED RESPONSES THAT HAVE LARGE RESPONSES, ...
% turn trendnormalizing off
% .  JRH 3/22/2018
%startdir=',datestr(now, 'ddmmmyyyy')'; % starting directory to read files. Set to empty to use current directory

addpath('/home/shared/matlabscripts');
startdir='/home/shared/TDT/Projects/TDTrecordings/'; % starting directory to read files. Set to empty to use current directory
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
analysisType='PrepFiles';
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
useDirr=1;
%fn='/home/shared/TDT/Projects/TDTrecordings/SHANK3/20230105/run-1/';
while notdone
    useDirr=true;
    if exist('fn')
        inputfiles={fn};
        [~,~,ext]=fileparts(fn);
        Answer.fileType=ext(2:end);
    else
        if useDirr
            [filepath]=uigetdir([startdir],'Select Parent Folder to Crawl Through');
            if ~filepath
                display('Cancelled and done');
                return
            end
            fprintf('Finding all tev files in path %s\n',filepath);
            [~,~,inputfiles]=dirr([filepath '/*.tev' ],'name');
            fprintf('Done! %d files found\n',size(inputfiles,2));
            Answer.createMat=true;
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
currentpos=0;
        editing=1;
        if nomenu
            editing=0;
        end
        while editing


[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.00001 10000]; % percentage
prompt(currentpos,:)={'Display Pre time (s)', 'prestimtime',[]};
defans(1).prestimtime = Answer.prestimtime;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.00011 10000]; % percentage
prompt(currentpos,:)={'Display Post time (s)', 'poststimtime',[]};
defans.poststimtime = Answer.poststimtime;
            
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
                Cancelled=1;
            end
            if ~Cancelled && strcmp(Answer.DisplayParams,'PlotScaling')
                Answer=csdScaling(Answer);
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
   exts ='.tev';
            for f = 1:numel(inputfiles)
                try
                    [fn, fpath, fnamepre, ext] = fLoop(f,inputfiles,exts);
                    %% read episodes
                    Answer.dataid='SSwp';
                    Answer.channelmap=1;
                    Answer.stimid='EpcV';
                    Answer.mapping=mapping;
                    Answer.LogCSD=LogCSD;
                    if numel(inputfiles)>1
                        fprintf('Processing file %d of %d, %.1f%% done.\n',f,numel(inputfiles),round(f*100/numel(inputfiles),1));
                    end
                        [data,ts,elapsed,stimdelay,si,stimVals,notes]=tdtepisodes6(fpath,Answer); % here to look at lfp data
 
                catch e
                    msg=string(e.message);
                    msgi=2;
                    for stk=1:size(e.stack,1)
                        msg(msgi)=['function ' e.stack(stk).name];
                        msgi=msgi+1;
                        msg(msgi)=['line ' num2str(e.stack(stk).line)];
                        msgi=msgi+1;
                    end
                    %waitfor(msgbox(msg,'Error in tdtmua'));
                    fprintf('%s\n',msg);
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







