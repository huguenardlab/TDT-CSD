function [fn,aveData,ts,elapsed,stimdelay,f,csd] = tdtcsd2(varargin)
% this will open a tdt file, and find all records of type "SSwp", which is
% block store, which is an episode of predefined number of samples, with a
% pre trigger period.  then it will display all channels, in order from top
% to bottom and create one  graph for each sweep, along with CSD, if enabled

%%  here are the custom defaults, change here to modify output behavior

% N.B. FOR EVOKED RESPONSES THAT HAVE LARGE RESPONSES, ...
% turn trendnormalizing off 
% .  JRH 3/22/2018
%startdir=',datestr(now, 'ddmmmyyyy')'; % starting directory to read files. Set to empty to use current directory
startdir='/home/shared/TDT/Projects/TDTrecordings/SHANK3/20210222/run-5'; % starting directory to read files. Set to empty to use current directory
baselineoffset=false; % calculate offset from first part of trace and the do DC offset to bring to zero
droppedChannels=[];
droppedEpisodes=[];
zeroedChannels = [];
% in this table is channel number is 0, then measure will ignore it
% this table lists,
% signalTitle,startOfMeasWindow,EndOfMeasWindo,polarity(-1 means look for
% in), channel number
% WindowTable= {'L2 PreSynSource' 0.007 0.009 1 2
%     'L3 PreSynSink' 0.007 0.009 -1 3
%     'L2 PostSynSink' 0.008 0.015 -1 2
%      'L3 PostSynSource' 0.008 0.015 1 3
%      'L5 PostSynSink' 0.009 0.3 -1 5
%      'Blanking' 0.0306 0.031 0 0
%      'Zoom' 0.001 0.005 0 0
%      'CSD Peak' 0.7 1 0 0};
 
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
useDirr=false;
nomenu=0;
TanyaAutoAnalysis=false;
LogCSD=false;
stimIntensityVariable = true; 
fileType='tev';
paramspath='Y:/matlabscripts/LFPparams/';
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
dlgcols=3;
Options.ReadButton = 'on';
Options.SaveButton = 'on';
Options.ApplyButton = 'on';
simplewidth=50; 
notdone=1;

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
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type='edit';
%             formats(currentrow,currentcol).format='text';
%             formats(currentrow,currentcol).size = 250;
%             prompt(currentpos,:)={'Directory', 'startdir',[]};
%             defans(1).startdir = startdir;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='list';
            formats(currentrow,currentcol).format='text';
            formats(currentrow,currentcol).style = 'radiobutton';
            formats(currentrow,currentcol).items = {'tev','openephys'};
            prompt(currentpos,:)={'File type', 'fileType',[]};
            defans(1).fileType = fileType;
            
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type='check';
%             prompt(currentpos,:)={'Invert Probe# Polarity', 'polarityswitch',[]};
%             defans.polarityswitch = polarityswitch;

           
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Display Sweeps', 'displaySweeps',[]};
            defans.displaySweeps = displaySweeps;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Average sweeps', 'averaging',[]};
            defans.averaging = averaging;
            
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Offset Baseline', 'baselineoffset',[]};
            defans.baselineoffset = baselineoffset;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'integer';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [1 100]; % percentage
            prompt(currentpos,:)={'% swp for baseline [1-100]', 'baselinepct',[]};
            defans.baselinepct = baselinepct;
            
            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Linear Detrend', 'trendnormalizing',[]};
            %defans.trendnormalizing = trendnormalizing;
            
            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Early Detrend', 'earlydetrend',[]};
            %defans.earlydetrend = earlydetrend;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'integer';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [1 1000]; % resample number
            prompt(currentpos,:)={'downsample interval', 'resample',[]};
            defans.resample = resample;
            

%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'integer';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 16]; % percentage
%             prompt(currentpos,:)={'First Channel', 'firstchan',[]};
%             defans.firstchan = firstchan;
%             
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'integer';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 16]; % percentage
%             prompt(currentpos,:)={'Last Channel', 'lastchan',[]};
%             defans.lastchan = lastchan;
            

if 1
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'text';
            formats(currentrow,currentcol).size = simplewidth;            
            %formats(currentrow,currentcol).limits = [1 16]; % percentage
            prompt(currentpos,:)={'Channel List', 'chans',[]};
            defans.chans = chans;
end
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='edit';
            formats(currentrow,currentcol).format = 'text';
            formats(currentrow,currentcol).size = simplewidth;
            prompt(currentpos,:)={'Sweeps', 'swps',[]};
            defans.swps = swps;
            
            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Quash noisy swps from ave', 'quashingnoisy',[]};
            %defans.quashingnoisy = quashingnoisy;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Plot Unaveraged Stim', 'plottingUnaveraged',[]};% for one stim intensity
            defans.plottingUnaveraged = plottingUnaveraged;

           
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.1 10000]; % percentage
            prompt(currentpos,:)={'Threshold for quashing (uV)', 'quashthreshold',[]};
            defans.quashthreshold = quashthreshold;
                        
           
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Filter', 'filtering',[]};
            defans.filtering = filtering;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.001 10000]; % percentage
            prompt(currentpos,:)={'HP Filter Cutoff', 'hp',[]};
            defans.hp = hp;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.001 10000]; % percentage
            prompt(currentpos,:)={'LP Filter Cutoff', 'lp',[]};
            defans.lp = lp;
                    
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Zoom in', 'zooming',[]};
            defans.zooming = zooming;
            
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type='check';
%             prompt(currentpos,:)={'Use TDT stim. time', 'usetdtstimtime',[]};
%             defans.usetdtstimtime = usetdtstimtime;
% 
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.0001 10000]; % percentage
%             prompt(currentpos,:)={'Stim. delay (s)', 'stimdelay',[]};
%             defans.stimdelay = stimdelay;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.00001 10000]; % percentage
            prompt(currentpos,:)={'Display Pre time (s)', 'prestimtime',[]};
            defans.prestimtime = prestimtime;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.00011 10000]; % percentage
            prompt(currentpos,:)={'Display Post time (s)', 'poststimtime',[]};
            defans.poststimtime = poststimtime;
          
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [-10000 10000]; % percentage
            prompt(currentpos,:)={'LFP vertical gain (mV)', 'lfpgain',[]};
            defans.lfpgain = lfpgain;               
 
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Measure LFP/CSD', 'measuring',[]};
            defans.measuring = measuring;
            
           % [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Use Default Channels for Measurements', 'defaultmeaschannels',[]};
           % defans.defaultmeaschannels = defaultmeaschannels;
            
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 14]; % percentage
%             prompt(currentpos,:)={'L3 Presyn sink:', 'l3PresynSinkChannel',[]};
%             defans.l3PresynSinkChannel = l3PresynSinkChannel;
%             
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 14]; % percentage
%             prompt(currentpos,:)={'L2 Postsyn sink:', 'l2PostsynSinkChannel',[]};
%             defans.l2PostsynSinkChannel = l2PostsynSinkChannel;
%             
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 14]; % percentage
%             prompt(currentpos,:)={'L3 Postsyn source:', 'l3PostsynSourceChannel',[]};
%             defans.l3PostsynSourceChannel = l3PostsynSourceChannel;
%             
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [1 14]; % percentage
%             prompt(currentpos,:)={'L5 Postsyn sink:', 'l5PostsynSinkChannel',[]};
%             defans.l5PostsynSinkChannel = l5PostsynSinkChannel;            
%             
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.001 10000];
%             prompt(currentpos,:)={'Measurement time (s)', 'meas_time',[]};
%             defans.meas_time = meas_time;
%  
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.0001 10000];
%             prompt(currentpos,:)={'Measurement duration (s)', 'meas_dur',[]};
%             defans.meas_dur = meas_dur;

                  [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Show all traces', 'displayall',[]};
            defans.displayall = displayall;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Save PDF', 'saving',[]};
            defans.saving = saving;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Plot CSD', 'plottingcsd',[]};
            defans.plottingcsd = plottingcsd;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [-10000 10000]; % percentage
            prompt(currentpos,:)={'CSD vertical gain', 'csdgain',[]};
            defans.csdgain = csdgain;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.01 10000]; % percentage
            prompt(currentpos,:)={'Contourplot max', 'contourgain',[]};
            defans.contourgain = contourgain;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'integer';
            formats(currentrow,currentcol).size = simplewidth;
            prompt(currentpos,:)={'# Contours', 'numcsdsteps',[]};
            defans.numcsdsteps= numcsdsteps;
                        
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'edit';
            formats(currentrow,currentcol).format = 'float';
            formats(currentrow,currentcol).size = simplewidth;
            formats(currentrow,currentcol).limits = [0.01 10000];
            prompt(currentpos,:)={'Pause time per sweep (s)', 'pause_dur',[]};
            defans.pause_dur = pause_dur;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Plot zerolines CSD', 'plottingzero',[]};
            defans.plottingzero = plottingzero;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Fill CSD blue/red', 'fillingcsd',[]};
            defans.fillingcsd = fillingcsd;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Plot CSD contour', 'plottingcontour',[]};
            defans.plottingcontour = plottingcontour;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Blue/White/Red Contours', 'bluewhiteredmap',[]};
            defans.bluewhiteredmap = bluewhiteredmap;
            
      
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Vectorize PDF', 'vectorize',[]};
            defans.vectorize = vectorize;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Use Dirr', 'useDirr',[]};
            defans.useDirr = useDirr;

            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Tanya Analysis', 'TanyaAnalysis',[]};
            %defans.TanyaAnalysis = TanyaAnalysis;
%                    [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type='check';
%             prompt(currentpos,:)={'Multiple Stim Intensities', 'stimIntensityVariable',[]};
%             defans.stimIntensityVariable = stimIntensityVariable;

     
            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Log value for CSD', 'LogCSD',[]};
            %defans.LogCSD = LogCSD;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Apply Channel Map', 'mapping',[]};
            defans.mapping = mapping;

            %[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            %formats(currentrow,currentcol).type='check';
            %prompt(currentpos,:)={'Blank sweeps without stim', 'blankSweeps',[]};
            %defans.blankSweeps = blankSweeps;
            
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.01 10000];     
%             prompt(currentpos,:)={'Blank start (ms)', 'stimStart',[]};
%             defans.stimStart = stimStart;
% 
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.01 10000];     
%             prompt(currentpos,:)={'Blank end (ms)', 'stimEnd',[]};
%             defans.stimEnd = stimEnd;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Multiple Stim Intensities', 'stimIntensityVariable',[]};
            defans.stimIntensityVariable = stimIntensityVariable;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Plot Each Trace Meas', 'plotEachMeasure',[]};
            defans.plotEachMeasure = plotEachMeasure;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Auxiliary Analysis', 'auxiliaryAnalysis',[]};
            defans.auxiliaryAnalysis = auxiliaryAnalysis;

            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
             formats(currentrow,currentcol).type = 'edit';
             formats(currentrow,currentcol).format = 'float';
             formats(currentrow,currentcol).size = simplewidth;
             formats(currentrow,currentcol).limits = [0.01 0.99]; % pretrigger Time+stim duration
             prompt(currentpos,:)={'% Width Calculation', 'widthPercent',[]};
             defans.widthPercent = widthPercent;

            
%             [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
%             formats(currentrow,currentcol).type = 'edit';
%             formats(currentrow,currentcol).format = 'float';
%             formats(currentrow,currentcol).size = simplewidth;
%             formats(currentrow,currentcol).limits = [0.001 10000]; % pretrigger Time+stim duration
%             prompt(currentpos,:)={'CSD delay (ms)', 'AfterStim',[]};
%             defans.AfterStim = AfterStim;
%             
%             prompt(end+1,:) = {'Time Window','Table',[]};
%             rowName={'L3 PreSynSink'; 'L2 PreSynSource'; 'L3 PostSynSource';'L5 PostSynSink'}
%             colName= {'Description','Win. start' ,'Win. end' ,'channel'};
%             timeWindow=rand(8,2)
%             uit = uitable('Data',timeWindow, 'ColumnName', colName,'RowName',rowName);
%            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'CSD Peak analysis', 'CSDPeakAnalysis',[]};
            defans.CSDPeakAnalysis = CSDPeakAnalysis;
 
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'TanyaAutoAnalysis', 'TanyaAutoAnalysis',[]};
            defans.TanyaAutoAnalysis = TanyaAutoAnalysis;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type='check';
            prompt(currentpos,:)={'Windows Relative to stim', 'measurementsRelative',[]};
            defans.measurementsRelative = measurementsRelative;
            
            [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'table';
            formats(currentrow,currentcol).format = {'char','numeric','numeric','numeric' 'numeric'}; % table (= table in main dialog) / window (= table in separate dialog)
           % formats(currentrow,currentcol).items = {'Description' 'Win. start' 'Win. end' 'channel'};
            formats(currentrow,currentcol).size = [315 40];
            formats(currentrow,currentcol).limits = {110,50,50,25,25};
           % formats(currentrow,currentcol).span = [4 4];  % item is 2 field x 1 fields
            defans.WindowTable = WindowTable;
            prompt(currentpos,:)={'', 'WindowTable',[]};
                [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
                formats(currentrow,currentcol).type='check';
                prompt(currentpos,:)={'Clear All Plots', 'clearplots',[]};
                defans.clearplots = clearplots;
         
            
            defanswer.subtract=false
            
            if size(inputfiles,2)>0 % kluge fix for now.  should really only show this
                
                [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
                formats(currentrow,currentcol).type='check';
                prompt(currentpos,:)={'Algebraic subtraction', 'subtract',[]};
                defans.subtract = subtract;
            else
                defans.subtract=false;
            end
            
            if analyzing
                [Answer,Cancelled] = inputsdlgjh(prompt,sprintf('Options for MUA - %d channels - %d sweeps - %s',size(data,2),size(data,1),startdir),formats,defans,Options);
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
              
                    
                    [data,ts,elapsed,stimdelay,si,stimVals,notes]=tdtepisodes5(fileparts(fn),Answer); % here to look at lfp data
                    Answer.notes=notes;
                    if isnan(stimVals(end)) 
                       data = data(1:(end -1),:,:); 
                    end
                    stimdelay=stimdelay+.001; % TDT generated stimuli are off by 1 ms
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
                    %postStimDelay= 0.0025;
                    %stimInd = find(ts(1,:)>stimdelay+postStimDelay,1,'first');
                    %endInd =  find(ts >= 0.060, 1, 'first');
                    nChannels = size(data,2);
                    nChannelsCSD = nChannels-2;
                   
                    
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
                               % X=[ones(size(trendtm)); trendtm];
                               % beta=regress(trendpts',X');
                               % s=sprintf('swp %d chan %d R %d m %d b %d m2 %d b2 %d',j,i,R,m,b,beta(1),beta(2));
                               % disp(s);
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
                        
%                     if measuring
%                         spacing=0.1;
%                         dyyl=squeeze(csdcalc3(data,spacing));
%                         poststimsample=178;
%                         for sw1=1:size(dyyl,1)
%                             for ch1=1:size(dyyl,2)
%                                 [pks(ch1,sw1,1:2),pktimes(ch1,sw1,1:2)]=findpeaks(-squeeze(dyyl(sw1,ch1,poststimsample:end)),'MinPeakProminence',.01,'Npeaks',2);
%                             end
%                         end
%                         dyyl2=squeeze(mean(dyyl));
%                         for ch1=1:size(dyyl2,1)
%                             [pks2(ch1,1:2),pktimes2(ch1,1:2)]=findpeaks(-(dyyl2(ch1,poststimsample:end)),'MinPeakProminence',.01,'Npeaks',2);
%                         end
%                         meas_samp=int32(meas_time/si);
%                         meas_samp2=int32((meas_time+meas_dur)/si);
%                         meas1=mean(data(:,:,meas_samp:meas_samp2),3);
%                         meas2=mean(dyyl(:,:,meas_samp:meas_samp2),3);
%                         fid = fopen([spath fnamepre '_lfp.csv'], 'w' );
%                         fprintf( fid, '"%s"\n',fn );                        
%                         for jj = 1 : size(meas1,1) % the below correction deals with assumes GMT to PDT
%                             fprintf( fid, '"%s",%ld', datetime(elapsed(jj)-60*60*7,'ConvertFrom','posixtime'),int32(elapsed(jj)-elapsed(1)));
%                             for kk=1:size(meas1,2)
%                                 fprintf( fid, ',%d', meas1(jj,kk));
%                             end
%                             fprintf( fid, '\n');
%                         end
%                         fclose( fid );
%                         if plottingcsd
%                         fid = fopen([spath fnamepre '_csd.csv'], 'w' );
%                         fprintf( fid, '"%s"\n',fn );                                                
%                         for jj = 1 : size(meas2,1)
%                             fprintf( fid, '"%s",%i', datetime(elapsed(jj)-60*60*7,'ConvertFrom','posixtime'),int32(elapsed(jj)));
%                             for kk=1:size(meas2,2)
%                                 fprintf( fid, ',%d', meas2(jj,kk));
%                             end
%                             fprintf( fid, '\n');
%                         end
%                         fclose( fid );
%                         end
                    %end

 if measuring
            spacing=0.1;
            csd=squeeze(csdcalc3(aveData,spacing));
   
            
            if ~stimIntensityVariable
                
                aveCSD = squeeze(mean(csd)); % when averaging traces, we don't need to average them again, because this time it would be across channels
                peakAndAreaData = calcPeakAndArea3(csd,Answer);

                fn = strcat(fpath, '/', fnamepre, '_PeakAndAreaData_',datestr(now, 'ddmmmyyyy'));
                save( fn, 'peakAndAreaData');
            elseif stimIntensityVariable
                clear aveCSD
                dataEachStim = sepDataByStimVals(stimVals, csd);
                dataEachStimLFP = sepDataByStimVals(stimVals, aveData);
                % we can choose subsets of traces, by first extracting the
                % data to temp variable like tempvar=dataEachStim.data
%                 d1=dataEachStim.data;
%                 size(d1)
%                 d2=d1(:,1:5,:,:);
%                 size(d2)
%                 dataEachStim.data=d2;
                %length(fieldnames(dataEachStim));
                %stimValsAvailable = unique(stimVals);
                %close all;
                %%%%%
%                 d1=dataEachStim.data;
%                 baseline=mean(d1(:,1:5,:,:),2);
%                 ttx=mean(d1(:,11:13,:,:),2);
%                 dnqxswitch=d1(:,17,:,:);
%                 ttxSensitive=ttx-dnqx;
%                 dataEachStim.data=ttxSensitive;
%                    y=linspace(1,100,2441);
%                   baseline=squeeze(baseline);
%                   ttxSensitive=squeeze(ttxSensitive);
%                    figure; plot(y,squeeze(ttxSensitive(:,4,:))')
%                     thischan=2;
%                     xlabel('Time (ms)');
%                     ylabel('CSD (mV/mm^2)');
%                     title(sprintf('SHANK3_TTXSensitive_''%s Channel %d',fnamepre,thischan),'Interpreter','none');
                    
if length(dataEachStim.stim)>1
    Answer.windowcalcplot=true;
for stim=1:size(dataEachStim.stim,2)
               aveCSD(stim).stim = dataEachStim.stim(stim);
               aveCSD(stim).data = squeeze(mean(dataEachStim.data(stim,:,:,:)));
               aveLFP(stim).data=squeeze(mean(dataEachStimLFP.data(stim,:,:,:)));               
               aveCSD(stim).peakAndArea= calcPeakAndArea3(aveCSD(stim).data,Answer);
               peakAndAreaSummary = aveCSD(stim).peakAndArea;
end
LFPstruct.aveLFP=aveLFP;
LFPstruct.si=si;
LFPstruct.stimdelay=stimdelay;
LFPstruct.elapsed=elapsed;
LFPstruct.notes=notes;
LFPstruct.stim=dataEachStimLFP.stim;
else
    Answer.windowcalcplot=false;
    
for epi=1:size(csd,1)
               aveCSD(epi).stim = dataEachStim.stim(1);
               aveCSD(epi).data = squeeze((dataEachStim.data(1,epi,:,:))); % no mean!
               aveCSD(epi).peakAndArea = calcPeakAndArea3(aveCSD(epi).data,Answer);
               peakAndAreaSummary = aveCSD(epi).peakAndArea;
end
end
                %save peak and area data from each stim in a table with
                %each column representing the quantification of each stim
                %intensity
                %fn = strcat(fnamepre, '_PeakAndAreaData');
                %save( fn, 'peakAndAreaSummary');
                
                %save structure that contains each ave trace, the stim
                %intensity and the peak and area quantification
                fn = strcat(fpath,'/',fnamepre, '_aveCSDeachStim_',datestr(now, 'ddmmmyyyy'));
                
                %test if the file exist here and use an input from the user
    if length(dataEachStim.stim)>1            
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
                 peakData(i,:)=measures (i,1,:)
             end
             fileName= strcat(fpath, '/', fnamepre, '_peakDataSummary_',datestr(now, 'ddmmmyyyy'));
             save( fileName, 'peakData')
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             
             if length(dataEachStim.stim)>=1
             Answer.windowcalcplot=true;
             %close all;
                %%%%%%%%PLOT MEASUREMENTS%%%%%%%%%%%%%%%%%%%%%%%%
                 if size(measures,2)>1 % we only do these next two sets of plots for an intensity series
                    for i=1:size(measures,2) % this code is now generic and will plot for all measures
                     figure;plot(squeeze(measures(:,i,:)));
                    title([fnamepre,' ',aveCSD(1).peakAndArea.measurenames{i}],'Interpreter','none');
                     if length(dataEachStim.stim)>1
                        xlabel('Stimulus (V, 1V/100uA)');
                    else
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
                %chanstoplot=[14]; for corpus callosum d
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
                    
                    if size(pltdata,2) > 20 && timeSeriesColorGradient == 1 % assuming a timeseries of a single stim intensity, there will be more than 20 traces
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
                    %colorbar;
                    %colorbar.Label.String = 'Number of sweeps';
                    %colorbar('Ticks',[-5,-2,1,4,7],'TickLabels',{'1','10','20','30','40'})
                    
                    ISI=15;%interval between sweeps, Yes InterStimulusInterval, ISI
                  swptimes=(0:size(colormap,1)-1)/(60/ISI);
                  maxtic=floor(max(swptimes))
                    numtickestimate=5;  % this is just a guess that we want about 5 tics
                    actualtics=floor(maxtic/numtickestimate);
                    actualticspacing=floor(maxtic/numtickestimate)
                    bathswitchsweep=5;%Sweep where the drug is IN
                    bathswitchtime=bathswitchsweep*ISI/60;
                    
                    tics=sort([(0:actualticspacing:maxtic) bathswitchtime]); % you can add other tics here too
                    bathswitchtic=find(tics==bathswitchtime); % and this code finds the added tic number that corresponds to THIS added tic, but will not work automatically for a second added tic
                    
                    ticleg=strsplit(num2str(tics));
                    ticleg{1}=[ticleg{1} ' min'];
                    ticleg{bathswitchtic}='Add IGluX';
                    colorbar('Ticks',tics/max(swptimes),'TickLabels',ticleg);
                    clear linecolormap
                    clear mid_point
                    end
                
                autoscalept1=int16((stimdelay+.002)/si); % start autoscaling 2ms after stim pulse start
                autoscalept2=length(ts);
                as1=min(min(min(pltdata(chn,:,autoscalept1:autoscalept2))));
                as2=max(max(max(pltdata(chn,:,autoscalept1:autoscalept2))));
                ylim([as1 as2]*1.1);
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
          
       
            end
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
                    if Answer.displayall >0
                        nplots=1;
                    end
                    
                    
%                      if CSDPeakAnalysis
%                   Answer.aven=10;
%                   csdpeaks=findcsdpeaks(aveData,Answer);
%                   %figure;
%                   %plot(csdpeaks.pks(:,14,1)); % first pk chan 14, all sweeps
%                   %hold on
%                    %         plot(csdpeaks.pks(:,14,2)); % second pk chan 14
%                   
%                      end
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
%                         fg=figure(fignum);
%                         if vectorize
%                             fg.Renderer='Painters'; %This forces matlab to save as a vector file,
%                         else
%                             fg.Renderer='OpenGL';
%                         end
%                         %retaining all the resolution.  The file is much much larger then, and
                        %slower to render, but can be imported into illustrator or Coreldraw.
                        %close all;
                        
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







