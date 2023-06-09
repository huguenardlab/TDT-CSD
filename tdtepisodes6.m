function [data,timepts,elapsed,stimdelay,si,stimvals,notes] = tdtepisodes6(fn,Answer)
% this will open a tdt file, and find all records of a certain type, for example, "SSwp", which is
% block store, which is an episode of predefined number of samples, with a
% pre trigger period.  then it will display all channels, in order from top
% to bottom and create one graph for each sweep.
%fn= (fn, '/home/shared/matlabscripts/mua',1);
rawEpiSuffix='-RawEpisodes';
[p1,f1,e1]=fileparts(fn);
if endsWith(fn,'tev')

    rawFile=[p1 '/' f1 rawEpiSuffix '.mat'];
    if isfile(rawFile)
        
        fprintf('Found episode file %s\n',[f1 rawEpiSuffix '.mat']);
            if Answer.overwrite
                fprintf('... but overwriting it\n');
            else
                fn=rawFile;
        e1='.mat';
            end
    else
    fn=fileparts(p1);
    fn=p1;
    end
end
directmatlabread=false;   

    if strcmp( e1,'.mat')
        load(fn);
        if Answer.prestimtime>LFPstruct.stimdelay || Answer.poststimtime>LFPstruct.si*size(LFPstruct.data,3)-LFPstruct.stimdelay
            fprintf('Reloading episodes from continuous wave data to capture -%.1f to %.1f ms\n',Answer.prestimtime*1000,Answer.poststimtime*1000);
        else

        directmatlabread=true;
        
        fnorig=fn;
        fn=p1;
        end
    end
    if directmatlabread
        fprintf('Loading sweeps from matlab file %s\n',f1');
   %load(fnorig);
   if isfield(LFPstruct,'data')
       data=LFPstruct.data;
   else
       data=LFPstruct.aveLFP.data;
   end
 allsweeps=size(data,1);
   
   fprintf('File %s has %d sweeps - %d channels\n',f1,size(data,1),size(data,2));
clear data;
%    fs=heads.stores.Raws.fs;
%   si=1/fs;
    
%        elapsed=1:size(data1.aveLFP,2);
        notes=LFPstruct.notes;
        si=LFPstruct.si;
        stimdelay=LFPstruct.stimdelay;        
        elapsed=LFPstruct.elapsed;                
 %       stimdelay=0.1; %assumes that is was saved in the version that combines multiple blocks together across stim intensities.
        stimvals=LFPstruct.stim;
        if isfield(LFPstruct,'aveLFP')
        for i=1:size(LFPstruct.aveLFP,2)
            data(i,:,:)=LFPstruct.aveLFP(i).data;
        end
          allsweeps=size(data,1);
        end
        if isfield(LFPstruct,'data')
            data=LFPstruct.data;
        end

        timepts=(1:size(data,3))*si;
    else
        if endsWith(fn,'tev') ||endsWith(fn,'mat')
            fn=fileparts(fn);
        end
heads = TDTbin2mat(fn, 'HEADERS', 1);
data=[];
stimdelay=[];
if isfield(heads.stores,'Wave')
    % this will read in wave data if it exists
%    a=strfind(fn,'/');
%    fn1=extractBefore(fn,a(end));  %get name of parent folder
%    b=strfind(fn1,'/');
%    fn2=extractAfter(fn1,b(end));  %get name of parent folder
%    fn3=[fn1 '/' fn2 '-sweeps-data'];
%    if isfile([fn3 '.mat'])
%        fprintf('\nSweep file %s exists. Loading it rather than TDT blocks.\n',[fn2 '-sweeps-data.mat']);
%        load([fn3 '.mat']);
%        if ischar(notes)
%           notes={notes};
%        end
%    else
%       
%        blocks=dir([fn1 '/Block*']);
%    dirFlags = [blocks.isdir];
%    subFolders = blocks(dirFlags);
%    nSubFolders=size(subFolders,1);
%    intensities=[1:nSubFolders];
%     intensitiesfilename=[fn1 '/Intensities.txt'];
%        if isfile(intensitiesfilename)
%            fid=fopen(intensitiesfilename);
%            formatSpec = '%f';
%            intensities=fscanf(fid,formatSpec);
%            fclose(fid);
%        end
   fs=heads.stores.Wave.fs;
   si=1/fs;
   prestim=Answer.prestimtime*1000; %100 ms
   poststim=Answer.poststimtime*1000; %1000 ms
   stimdelay=prestim/1000;
   notes=[];
%    stimscaler=1;
%    elapsed=[];
%    stimvals=[];curswp=0;
%    for block=1:nSubFolders
%        thisblock=[fn1 '/Block-' num2str(block)];
%        heads = TDTbin2mat(thisblock, 'HEADERS', 1);
%        swps=size(heads.stores.EpcV.offset,2);
%        epocs=TDTbin2mat(thisblock,'Type',2);
%        firstepitime=posixtime(datetime([epocs.info.date ' ' epocs.info.utcStartTime]));
%        if ~isempty(epocs.notes)
%            notes=[notes {['Block-' num2str(block) ': ']} epocs.notes ];
%        end
%       fprintf('block %d  ',block);
numpts=-1;   
finalswp=0;
swps=size(heads.stores.EpcV.offset,2);
numpts3=0;
swps1=Answer.swps;     
if Answer.createMat 
    swps1='all';
end
swpnums=validatevector(swps1,swps);  % this takes the string that contains sweep numbers, ranges, etc, and returns vector with sweeps specificied

for swp1=1:numel(swpnums) 
       swp=swpnums(swp1); %swps
       thisswp=TDTbin2mat(fn,'STORE','Wave','T1',heads.stores.EpcV.onset(swp)-(prestim-1)/1000,'T2',heads.stores.EpcV.onset(swp)+(poststim+1)/1000);
       % need to correct the tdt stim times, as they are off by one ms.
       %    stimsample=epocs.epocs.EpcV.onset(swp)*fs;
    %   firstsample=int32(stimsample-prestim/1000*fs);
     %  lastsample=int32(stimsample+poststim/1000*fs);
       numpts2=size(thisswp.streams.Wave.data,2);
       
    if swp1<2
        chans=size(thisswp.streams.Wave.data,1);
        fprintf('File %s has %d sweeps - %d channels\n',fn,swps,chans);
    end
       data1=thisswp.streams.Wave.data;
       if numpts3>0 && numpts3~=numpts2
           data1(numpts2+1:numpts3)=0;  % pad with zeros if the file was closed before the number of points for other tracess was collected
%           data1=padarray(data1,numpts3-numpts2,0);
       end
           
     %  fprintf('Block:%2d, Sweep:%3d Samples:%d ', block,swp,numpts2);
%        if numpts<0
%            numpts=numpts2;
%        end
%        if numpts2==numpts
%          finalswp=finalswp+1;
            expectedsamples=0.001*(prestim+poststim)/si;
            if size(data1,2) < expectedsamples
                pad=expectedsamples-size(data1,2);
                data1=[nan(size(data1,1),pad,1) data1(:,:)];
            end
         data(swp1,:,:)=data1; %thisswp.streams.Wave.data; %tdtdata1.streams.Raws.data(:,firstsample:lastsample);
         numpts3=numpts2;
      %   numpts=size(data,3);
       end
   
   timepts=(1:size(data,3))*si;
end

tdtdata=TDTbin2mat(fn,'TYPE',{'snips','epocs'});   

notes=tdtdata.notes;
if isfield(tdtdata.epocs,'Valu')
    ref=tdtdata.epocs.Valu.onset(1);
end
if isfield(tdtdata.epocs,'EpcV')
    ref=tdtdata.epocs.EpcV.onset(1);
end
if isempty(stimdelay)
stimdelay= ref-tdtdata.snips.SSwp.ts(1);
end
si=1/tdtdata.snips.SSwp.fs;
firstepitime=posixtime(datetime([ tdtdata.info.date ' ' tdtdata.info.utcStartTime]));
elapsed=sort(unique(tdtdata.snips.SSwp.ts))+firstepitime;
chans=sort(unique(tdtdata.snips.SSwp.chan));
numchans=size(chans,1);
totalsweeps=size(tdtdata.snips.SSwp.data,1);
realsweeps=totalsweeps/numchans;
timepts=(1:size(data,3))*si;
%need to put the channel map option back because file before 20190819 M1S2
%are without the map in TDT and also params for the stim are different
if isempty(data)
data=single(zeros(numchans,realsweeps,tdtdata.snips.SSwp.size-10));
for ch=1:numchans
    rows=find(tdtdata.snips.SSwp.chan==ch);
    data(ch,:,:)=tdtdata.snips.SSwp.data(rows,:);
end
data=permute(data,[2,1,3]);
         fprintf('File %s has %d sweeps - %d channels\n',fn,size(data,1),size(data,2));
 
end
timepts=(1:size(data,3))*si;
if Answer.mapping
channelmap = [6,3,2,5,4,7,8,1,16,13,9,10,12,15,14,11];
% channelmap=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];
%     channelmap=[8,6,4,2,7,5,3,1,15,13,11,9,16,14,12,10]; % ZIF-Clip Headstage to Acute Probe Adapter
%     channelmap=[16,14,12,10,8,6,4,2,1,3,5,7,9]; %ZIF-Clip  Headstage to Chronic Probe Adapter
%    channelmap=[6,3,1,2,5,4,7,8,9,10,13,12,15,16,14,11]; % a16x1
%     channelmap=[16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1];
    
    data=data(:,channelmap,:);
end
if isfield(tdtdata.epocs,'Valu')
    stimvals=tdtdata.epocs.Valu.data;
end
if Answer.TanyaAutoAnalysis

%     channelmap=[6,3,1,2,5,4,7,8,9,10,13,12,15,16,14,11];
    channelmap=[16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1];
    data=data(:,channelmap,:);
    % the following assumes that stim intensity went through a series of
    % 1 to 5 volts, then repeated for length of file
    runs=int16(size(data,1)/5);
    stimvals=repmat([1:5],1,runs)'; % this does 1,2,3,4,5
    stimvals = repmat(1:1:5,5,1); stimvals=stimvals(:)';% this does 1,1,1,1,1,2,2,...
    
end
if isfield(tdtdata.epocs,'EpcV')
    stimvals=tdtdata.epocs.EpcV.data;
    % note new code added 01/14/2020 BF and JH, to actually read the values of
    % pulse from those recorded rather than those encoded, because TDT doesn't
    % get right every time!!!
    % this finds the actual values that TDT put out to the stimulator, and
    % actually represents as biphasic, as appropriate.
    tdtdata2=TDTbin2mat(fn,'STORE','Puls');    
    pulsedata=tdtdata2.streams.Puls.data;
    % first get rid of negative parts of the stim train to only find the
    % leading edge of each stim. Otherwise for biphasic you would get two
    % triggers, one at the start of the positive pulse, and another at the  end
    % of the negative pulse
    pulsedata(find(pulsedata<0))=NaN;
    diffpulsedata=diff(pulsedata);
    % this will work as long as pulse amplitude is ALWAYS greater than .2 V
    pulsestarts=find(diffpulsedata>.2);
    % first create empty stimvalue array, in case, we don't get as many as we
    % expect.
    stimvals=NaN(size(tdtdata.epocs.EpcV.onset,1),1);
    stimvals(1:size(pulsestarts,2))=pulsedata(pulsestarts+1);
  
end
    end
    if directmatlabread
        swpnums=validatevector(Answer.swps,allsweeps);  % this takes the string that contains sweep numbers, ranges, etc, and returns vector with sweeps specificied
        data=data(swpnums,:,:);
    end
    if Answer.createMat && ~directmatlabread
        LFPstruct.data=data;
        LFPstruct.si=si;
        LFPstruct.stim=stimvals;
        LFPstruct.stimdelay=stimdelay;
        LFPstruct.elapsed=elapsed;
        LFPstruct.notes=notes;
        fprintf('Saving Episodes as %s\n',rawFile);
        save(rawFile,'LFPstruct');
    end
    poststim1=LFPstruct.si*size(LFPstruct.data,3)-LFPstruct.stimdelay;
    if stimdelay>Answer.prestimtime || poststim1 >Answer.poststimtime
        firstpttime=stimdelay-Answer.prestimtime;
        
        lastpttime=Answer.prestimtime+Answer.poststimtime;
        firstpt=int16(firstpttime /LFPstruct.si);

        lastpt=int16((lastpttime+firstpttime) /LFPstruct.si);
        if firstpt<1
            firstpt=1;
        end
        if lastpt>size(data,3)
            lastpt=size(data,3);
        end
        data=data(:,:,firstpt:lastpt);
        timepts=(1:size(data,3))*si;
        stimdelay=Answer.prestimtime;
    end
    fprintf('Stimuli used: ');
    fprintf('%d ',unique(stimvals));
    fprintf('V\n');
end





