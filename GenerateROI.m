% use this to create ROIs for each cell. 

%% 1 - draw polygon for first timepoint

clear all
close all

framenumber1 = 1;
framenumber2 = 41;

filename = 'GhoseFRAP_17966_202_R3D';

im = imread( [ filename , '.tif'],framenumber1);
imagesc(im); colormap gray;
drawnow

el = drawpolyline;

%% 2 -  store first polygon in a matrix and draw polygon for last timepoint

elpos1 = el.Position;

close all

im = imread( [ filename , '.tif'],framenumber2) ;
imagesc(im); colormap gray;

el2 = drawpolyline([] ,'Position',elpos1);

%% 3 - store second polygon

elpos2 = el2.Position;

%% 4 - Morph polygon

ROI = {}; % ROI cell will contain ROI across all timepoints

ROI{framenumber1} = elpos1;

ROI{framenumber2} = elpos2;

deltapos = (elpos2-elpos1)/(framenumber2-framenumber1);

for i = framenumber1+1 : framenumber2-1 %apply linear transform to fill in shapes between initial and final timepoints
    
   ROI{i} = ROI{i-1} + deltapos; 
    
end

save(['ROI_',filename],'ROI');

% verify that this works

%{
for i = framenumber1:framenumber2
    
    im = imread( [ filename , '.tif'],i) ;
    imagesc(im); colormap gray;
    
    viewpolygon = drawpolygon([] ,'Position', ROI{i});
    pause(0.1)
    i
end

%}













