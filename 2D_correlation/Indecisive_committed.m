% use this to create ROIs for each cell.

clear all
close all
filename = 'Stablized MAX_488_s3';
cellname = '_3';

frames = [ 1 27 ]; %Format is [initialframe , middleframes, finalframe]. These are critical frames at which you make changes to your ROI.
committime = [];
framecount = 0; %keep track of how many frames we have gone through
ROI = {}; % ROI cell will contain ROI across all timepoints

%% 1 Create ROIs

for num=frames
    framecount = framecount + 1; %increment framecount
    
    close all
    im = imread( [ filename , '.tif'],num) ;
    imagesc(im); colormap gray; axis square;set(gcf, 'Position', get(0, 'Screensize'));
    axis square
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

save(['ROI_',filename,cellname],'ROI','frames','committime');

%% 3 - Preview morphing shape if you want to

for ii = frames(1):frames(end)
    
    im = imread( [ filename , '.tif'],ii) ;
    imagesc(im); colormap gray;axis square;
    
    viewpolygon = drawpolygon([] ,'Position', ROI{ii});
    pause(0.1)
    
end

%% 4 - See what cells are already marked

filename = 'Stablized MAX_488_s2';

im = imread( [ filename , '.tif'],1) ;
imagesc(im); colormap gray; axis square;set(gcf, 'Position', get(0, 'Screensize'));

for cc = 1:5 %number of cells quantified so far for a given file
   
     load(['ROI_',filename,'_',num2str(cc)],'ROI','frames')
     %viewpolygon = drawpolygon([] ,'Position', ROI{frames(1)});
     text(mean(ROI{frames(1)}(:,1)),mean(ROI{frames(1)}(:,2)),num2str(cc),'Color','w')
end

%% 5 - Calculate correlation

% find files starting with 'ROI' and use those to generate plots

allfiles = dir();
allcorrels = {};
allframes = [];
allcommits = [];

numROIs = 0; %number of ROIs
for ii = 1:size(allfiles,1)

    if numel(allfiles(ii).name)>3 %make sure number of characters in file name is large enough
       
        if strcmp( allfiles(ii).name(1:3) , 'ROI' )
        
            numROIs = numROIs + 1;
            
            
            
            ROIfilename = allfiles(ii).name; %Keep track of this so you can load up the ROI later.
            filename = allfiles(ii).name(5:end); %get image file name for a given ROI
            remfrom = 'dummy'; jj = 0;
            while ~strcmp(remfrom,'_') % I want to remove indexing to extract the file name. To do this, I remove the indexing. To remove indexing, I simply count backwards from the last character in the filename till I hit the first underscore, and then I remove everything that comes after the underscore. 
            jj = jj + 1;
            remfrom = allfiles(ii).name(end-jj);
            end
            
            filename( (end-jj) : end) = [];
            
            if 0 %use this to apply ROI to different channel
                cha = strfind(filename,'488');
                filename((cha):(cha+2))='561';
            end
            
            disp(ROIfilename); disp(filename);
            
            %% actual analysis happens here, once you have filenames and such
            
            load(ROIfilename);
            
            correlframes = [];
           
            
            for ii = (frames(1)+1):frames(end)
                
                % first frame
                figure
                im1 = imread( [ filename , '.tif'] , ii-1) ;
                imagesc(im1); colormap gray;
                viewpolygon = drawpolygon([] ,'Position', ROI{ii});
                BW = createMask(viewpolygon);
                cellintens1 = double(im1(BW));
                close
                
                % second frame
                figure
                im2 = imread( [ filename , '.tif'] , ii) ;
                imagesc(im2); colormap gray;
                viewpolygon = drawpolygon([] ,'Position', ROI{ii});
                BW = createMask(viewpolygon);
                cellintens2 = double(im2(BW));
                close
                correlframes = [ correlframes, corr(cellintens1,cellintens2) ];
                
                %pause(0.1)
            end
            
            allcorrels{numROIs} = correlframes;
            allframes = [ allframes ; frames ];
            allcommits = [ allcommits ; committime ];
            %{
            subplot(2,6,numROIs)
            
            plot(correlframes)
            hold on
            plot(movmean(correlframes,5))
            ylim([0 1]);
            %}
            
            save('AllCorrelations','allcorrels','allframes','allcommits')
            
        end
    end
end



%% 6 - Plot things with the correlations you obtained

load('AllCorrelations.mat')

mythreshhold = 0.8; %set a threshhold you want to put in the graph
movingwindowaverage = 5;

sgolaywindow = 5;
sgolayorder = 1;


for ii = 1:size(allcorrels,2)

    plotthis = allcorrels{ii};
    timeaxis = [allframes(ii,1):(allframes(ii,2)-1)];
    
    
    subplot( 3,5 , ii  )

    plot(timeaxis,plotthis);
    hold on
    plot(timeaxis,movmean(plotthis,movingwindowaverage)) %window averaging
    
    %plot(timeaxis,sgolayfilt(plotthis,sgolayorder,sgolaywindow)) %sgolay filtering
    
    
    
    plot([ allframes(ii,1) , (allframes(ii,2)-1) ] , [mythreshhold mythreshhold]);
 
    plot([ allcommits(ii) allcommits(ii)  ],[ 0 1 ]);
    
    
    xlabel('Timepoints')
    ylabel('Corrmatch')
end

