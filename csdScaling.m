function AnswerOut = csdScaling(AnswerIn)
defans = struct([]);
currentpos=0; %initialize
dlgcols=2;
simplewidth=50;
Options.ReadButton = 'off';
Options.SaveButton = 'off';
Options.ApplyButton = 'off';
[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Average sweeps', 'averaging',[]};
defans(1).averaging = AnswerIn.averaging;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Offset Baseline', 'baselineoffset',[]};
defans.baselineoffset = AnswerIn.baselineoffset;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'integer';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [1 100]; % percentage
prompt(currentpos,:)={'% swp for baseline [1-100]', 'baselinepct',[]};
defans.baselinepct = AnswerIn.baselinepct;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Linear Detrend', 'trendnormalizing',[]};
if ~isfield(AnswerIn,'trendnormalizing')
    AnswerIn.trendnormalizing=false;
end
defans.trendnormalizing = AnswerIn.trendnormalizing;


[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Filter', 'filtering',[]};
defans.filtering = AnswerIn.filtering;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.001 10000]; % percentage
prompt(currentpos,:)={'HP Filter Cutoff', 'hp',[]};
defans.hp = AnswerIn.hp;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.001 10000]; % percentage
prompt(currentpos,:)={'LP Filter Cutoff', 'lp',[]};
defans.lp = AnswerIn.lp;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'integer';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [1 1000]; % resample number
prompt(currentpos,:)={'downsample interval', 'resample',[]};
defans.resample = AnswerIn.resample;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.00001 10000]; % percentage
prompt(currentpos,:)={'Display Pre time (s)', 'prestimtime',[]};
defans.prestimtime = AnswerIn.prestimtime;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.00011 10000]; % percentage
prompt(currentpos,:)={'Display Post time (s)', 'poststimtime',[]};
defans.poststimtime = AnswerIn.poststimtime;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [-10000 10000]; % percentage
prompt(currentpos,:)={'LFP vertical gain (mV)', 'lfpgain',[]};
defans.lfpgain = AnswerIn.lfpgain;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [-10000 10000]; % percentage
prompt(currentpos,:)={'CSD vertical gain', 'csdgain',[]};
defans.csdgain = AnswerIn.csdgain;


[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'float';
formats(currentrow,currentcol).size = simplewidth;
formats(currentrow,currentcol).limits = [0.01 10000]; % percentage
prompt(currentpos,:)={'Contourplot max', 'contourgain',[]};
defans.contourgain = AnswerIn.contourgain;

 [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
            formats(currentrow,currentcol).type = 'table';
            formats(currentrow,currentcol).format = {'char','numeric','numeric','numeric' 'numeric'}; % table (= table in main dialog) / window (= table in separate dialog)
           % formats(currentrow,currentcol).items = {'Description' 'Win. start' 'Win. end' 'channel'};
            formats(currentrow,currentcol).size = [315 80];
            formats(currentrow,currentcol).limits = {110,50,50,25,25};
           % formats(currentrow,currentcol).span = [4 4];  % item is 2 field x 1 fields
            defans.WindowTable = AnswerIn.WindowTable;
            prompt(currentpos,:)={'', 'WindowTable',[]};
         

[Answer,Cancelled] = inputsdlgjh(prompt,'TDT Scaling',formats,defans,Options);

if Cancelled
    AnswerOut=AnswerIn;
else
    AnswerOut=mergestructures(AnswerIn,Answer);
end

            
