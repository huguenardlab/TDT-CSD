function [currentrow,currentcol,currentpos]=calcdlgpos(currentpos,dlgrows)
%% calculates row and position from index position, given number of rows
currentpos=currentpos+1;
currentrow=ceil((currentpos/dlgrows));
currentcol=mod(currentpos-1,dlgrows)+1;
end