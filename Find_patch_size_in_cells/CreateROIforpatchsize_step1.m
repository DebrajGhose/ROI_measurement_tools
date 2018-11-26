%% figure out what the size of a patch is
clear all
close all

%% maybe put in some kind of condition so you stop the script once you are done with marking ROIs on cells

myROIs = {};
cellnumber = size(myROIs,2);
radius = 10;
filename = '2018115_patchsize_22715_2';

im1 = imread(['.\Data\',filename,'_w1DIC Confocal.TIF']);
im2 = imread('.\Data\2018115_patchsize_22715_2_w2Confocal 561.TIF',7);


im1 = imadjust(im1);
im2 = imadjust(im2);
dispimg = cat(3,im2,im1,zeros(size(im1,1))); %create 3d RGB image matrix that you can display later

while(1)
    image(dispimg);
    cellnumber = cellnumber + 1;
    donewithcells = input('Done marking all cells?','s');
    
    if donewithcells == 'y'
        break
    end
    
    if ~isempty(myROIs)
    for i = 1:size(myROIs,2)
            drawcircle('Position',myROIs{i},'Radius',radius);    
    end
    end
    
    circ = drawpoint;%circ = drawcircle('Center',[100,100],'Radius',10);
    
    while(1) %pause code to make changes to your ROI, give user option to proceed once they are satisfied
        m = input('Happy with ROI? ','s');
        if m == 'y'
            break
        end
    end
    
    %save your ROI here, maybe within a cell matrix?
    
    myROIs{cellnumber} = circ.Position;
    
end

save(filename,'myROIs');
