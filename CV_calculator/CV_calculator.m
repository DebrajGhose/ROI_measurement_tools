% use this to create ROIs for each cell.

clear all
close all
filename = 'Stablized MAX_488_s1';
cellname = '_1';

frames = [1 28 64]; %Format is [initialframe , middleframes, finalframe]. These are critical frames at which you make changes to your ROI.
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

%% 3 - Preview morphing shape if you want to

for ii = frames(1):frames(end)
    
    im = imread( [ filename , '.tif'],ii) ;
    imagesc(im); colormap gray;
    
    viewpolygon = drawpolygon([] ,'Position', ROI{ii});
    pause(0.1)
    
end

%% 4 - Calculate CV

%load your ROIs here

filename = 'Stablized MAX_488_s1';

for cc = 1:1
    
    load(['ROI_',filename,'_',num2str(cc)],'ROI','frames');
    
    CV = [];
    
    for ii = frames(1):frames(end)
        
        im = imread( [ filename , '.tif'] , ii) ;
        imagesc(im); colormap gray;
        
        viewpolygon = drawpolygon([] ,'Position', ROI{ii});
        BW = createMask(viewpolygon);
        
        %imagesc(BW)
        
        cellintens = double(im(BW));
        
        CV = [ CV , var(cellintens)/mean(cellintens)]; %Calculate CV
        
        %pause(0.1)
    end
    
    subplot(2,2,1)
    
    plot(CV)
    
end


