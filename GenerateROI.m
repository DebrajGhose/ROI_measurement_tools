% use this to create ROIs for each cell.

clear all
close all

filename = 'Stablized C1-rcc103_s3-1';
cellname = '_1';

frames = [1 22 37];
framecount = 0; %keep track of how many frames we have gone through
ROI = {}; % ROI cell will contain ROI across all timepoints

%% 1 Create ROIs

for num=frames
    framecount = framecount + 1; %increment framecount
    
    close all
    im = imread( [ filename , '.tif'],num) ;
    imagesc(im); colormap gray;
    
    if framecount == 1 %for first frame, simply create a polygon
        el = drawpolygon;
        
        while(1) %pause code to make changes to your ROI, give user option to proceed once they are satisfied
            m = input('Happy with ROI? ','s');
            if m == 'y'
                break
            end
        end
        
    else % for subsequent frames, show polygon from previous frame
        
        el = drawpolygon([] ,'Position',ROI{frames(framecount-1)});
        
        while(1) %pause code to make changes to your ROI, give user option to proceed once they are satisfied
            m = input('Happy with ROI? ','s');
            if m == 'y'
                break
            end
        end
    end
    
    ROI{num} = el.Position; %store polygon in ROI cell array
    
end

%% 2 - Morph polygon%
%This is done to gradually change the polygon drawn at the first timepoint
%to the polygon drawn in the last timepoint. Useful for cells that move or
%rotate over the course of the movie.

for num = 1:numel(frames)-1
    
    deltapos = (ROI{frames(num+1)}-ROI{frames(num)})/(frames(num+1)-frames(num));
    
    for t = frames(num)+1 : frames(num+1)-1 %apply linear transform to fill in shapes between initial and final timepoints
        
        ROI{t} = ROI{t-1} + deltapos;
        
    end
    
end

save(['ROI_',filename,cellname],'ROI','frames');

% verify that this works

%{
for i = frames(1):frames(end)
    
    im = imread( [ filename , '.tif'],i) ;
    imagesc(im); colormap gray;
    
    viewpolygon = drawpolyline([] ,'Position', ROI{i});
    pause(0.1)
    i
end

%}













