function AnswerOut = csdPlotDetails(AnswerIn)
defans = struct([]);
currentpos=0; %initialize
dlgcols=2;
simplewidth=50;
Options.ReadButton = 'off';
Options.SaveButton = 'off';
Options.ApplyButton = 'off';

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Zoom in', 'zooming',[]};
defans(1).zooming = AnswerIn.zooming;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Plot zerolines CSD', 'plottingzero',[]};
defans.plottingzero = AnswerIn.plottingzero;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Fill CSD blue/red', 'fillingcsd',[]};
defans.fillingcsd = AnswerIn.fillingcsd;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Plot CSD contour', 'plottingcontour',[]};
defans.plottingcontour = AnswerIn.plottingcontour;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'integer';
formats(currentrow,currentcol).size = simplewidth;
prompt(currentpos,:)={'# Contours', 'numcsdsteps',[]};
defans.numcsdsteps= AnswerIn.numcsdsteps;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Blue/White/Red Contours', 'bluewhiteredmap',[]};
defans.bluewhiteredmap = AnswerIn.bluewhiteredmap;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Vectorize PDF', 'vectorize',[]};
defans.vectorize = AnswerIn.vectorize;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Save PDF', 'saving',[]};
defans.saving = AnswerIn.saving;

[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Clear All Plots', 'clearplots',[]};
defans.clearplots = AnswerIn.clearplots;

if ~isfield(AnswerIn,'createMat')
    AnswerIn.createMat=true;
end
[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type='check';
prompt(currentpos,:)={'Create raw MAT file', 'createMat',[]};
defans.createMat = AnswerIn.createMat;

if ~isfield(AnswerIn,'switchsweep')
    AnswerIn.switchsweep='1:10,13,88:89';
end
[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'text';
formats(currentrow,currentcol).size = 100;
prompt(currentpos,:)={'Switch Sweeps', 'switchsweep',[]};
defans.switchsweep= AnswerIn.switchsweep;

if ~isfield(AnswerIn,'bathChange')
    AnswerIn.bathChange='5:iGluRX';
end
[currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgcols);
formats(currentrow,currentcol).type = 'edit';
formats(currentrow,currentcol).format = 'text';
formats(currentrow,currentcol).size = 100;
prompt(currentpos,:)={'Bath Change Swp:Cond.', 'bathChange',[]};
defans.bathChange= AnswerIn.bathChange;

[Answer,Cancelled] = inputsdlgjh(prompt,'Plot Details',formats,defans,Options);
if Cancelled
    AnswerOut=AnswerIn;
else
    AnswerOut=mergestructures(AnswerIn,Answer);
end

