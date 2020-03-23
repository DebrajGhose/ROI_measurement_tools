% use this to create ROIs for each cell.

clear all
close all
filename = 'MAX_rcc218_488_s4';
cellname = '_1';

frames = [ 1 30 ]; %Format is [initialframe , middleframes, finalframe]. These are critical frames at which you make changes to your ROI.
committime = [ 15 ];
framecount = 0; %keep track of how many frames we have gone through
ROI = {}; % ROI cell will contain ROI across all timepoints
intensitylimits = [100 500]; %set up intensity limits. If you want auto calibration, make it [ -Inf Inf ]

%% 1 Create ROIs

for num=frames
    framecount = framecount + 1; %increment framecount
    
    close all
    im = imread( [ filename , '.tif'],num) ;
    imagesc(im , intensitylimits ); colormap gray; axis square;set(gcf, 'Position', get(0, 'Screensize'));
    
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

maxx = 1; minx = 10000; maxy = 1; miny = 10000;

for ii = frames(1):frames(end)
    
    
    maxx = max(maxx,max(ROI{ii}(:,1))); minx = min(minx,min(ROI{ii}(:,1)));
    
    maxy = max( maxy , max(ROI{ii}(:,2))); miny = min(miny,min(ROI{ii}(:,2)));
    
end

for ii = frames(1):frames(end)
    
    im = imread( [ filename , '.tif'],ii) ;
    imagesc(im); colormap gray;axis square;
    axis([minx maxx miny maxy]);
    viewpolygon = drawpolygon([] ,'Position', ROI{ii});
    
    pause(0.1)
    
end

%% 4 - See what cells are already marked

filename = 'MAX_rcc218_488_s4';

im = imread( [ filename , '.tif'],1) ;
imagesc(im); colormap gray; axis square;set(gcf, 'Position', get(0, 'Screensize'));

for cc = 1:7 %number of cells quantified so far for a given file
   
     load(['ROI_',filename,'_',num2str(cc)],'ROI','frames')
     %viewpolygon = drawpolygon([] ,'Position', ROI{frames(1)});
     text(mean(ROI{frames(1)}(:,1)),mean(ROI{frames(1)}(:,2)),num2str(cc),'Color','w')
end

%% 5 - Calculate correlation

% find files starting with 'ROI' and use those to generate plots

allfiles = dir();
allcorrels = {};
allframes = {};
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
            
            filename( (end-jj) : end) = []; %extract filename of the TIF file you want to open
            
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
            
            allcorrels{1,numROIs} = correlframes;
            allcorrels{2,numROIs} = ROIfilename; %store file name here for recall later
            allframes{end+1} = frames;
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

%% 6 - Calculate CV (use this for the MAPK channel)

%use this to calculate CV of signal in the cell for each time point

allfiles = dir();
allcvs = {};
allframes = {};

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
            
            filename( (end-jj) : end) = []; %extract filename of the TIF file you want to open
            
            if 1 %use this to apply ROI to different channel
                cha = strfind(filename,'488');
                filename((cha):(cha+2))='561';
            end
            
            disp(ROIfilename); disp(filename);
            
           %% actual analysis happens here, once you have filenames and such
            
            load(ROIfilename);
            
            cvframes = [];
           
            for ii = frames(1):frames(end)
               
                figure
                im2 = imread( [ filename , '.tif'] , ii) ;
                imagesc(im2); colormap gray;
                viewpolygon = drawpolygon([] ,'Position', ROI{ii});
                BW = createMask(viewpolygon);
                cellintense = double(im2(BW));
                close
                cvframes = [ cvframes, std(cellintense(:))/mean(cellintense(:))  ];
                
                %pause(0.1)
            end
            
            allcvs{1,numROIs} = cvframes;
            allcvs{2,numROIs} = ROIfilename; %store file name here for recall later
            allframes{end+1} = frames;
            %{
            subplot(2,6,numROIs)
            
            plot(correlframes)
            hold on
            plot(movmean(correlframes,5))
            ylim([0 1]);
            %}
            
            save('AllCVs','allcvs','allframes')
            
        end
    end
end


%% 7 - Plot things with the correlations you obtained

close all

figure('Name','Correlation plots'); set(gcf, 'Renderer', 'Painters' );

load('AllCorrelations.mat')

timeinterval = 2; %interval in minutes between timepoints
mythreshold = 0.78; %set a threshhold you want to put in the graph
testhresholds = [0:0.01:1];
movingwindowaverage = 5;

falseposterr = 2; % range (in timepoints) over which you can forgive a false positive
falsenegterr = -2; %range (in timepoints) over which you can forgive a false negative

allneg = []; %false negative is when the signal never reaches the threshold or it reaches the threshold too late
allpos = []; %false postive is if the signal hits the threshold too early

for threshold = testhresholds
    
    
    falseneg = 0;
    falsepos = 0;
    
    for ii = 1:size(allcorrels,2)
        
        coi = allcorrels{1,ii}; %correlation of interest
        meancoi = movmean(coi,movingwindowaverage); %find mean trace by window averaging
        
        timeaxis = [ allframes{ii}(1):(allframes{ii}(numel(allframes{ii}))-1) ]*timeinterval;
        
        adjustby = timeaxis(1); %how much you want to adjust timeaxis by
        
         if max(meancoi(:)) < threshold, falseneg = falseneg + 1; end %calculate if false negative or not
       
        if ~isempty(allcommits) && max(meancoi)>threshold  %calculate difference between manually called commit and commit called by code
            
            codecommit = (find(meancoi>threshold,1) - 1)*timeinterval; %find commit by code. The -1 is to make it 0 indexed
            diffincall = (allcommits(ii)*timeinterval-adjustby) - (codecommit); %difference between calling by eye vs code
            
            if diffincall > falseposterr*timeinterval, falsepos = falsepos + 1; end
            
            if diffincall < falsenegterr*timeinterval, falseneg = falseneg + 1; end
            
        end
        
        
        if threshold == mythreshold %plot outputs for one of the thresholds
            
            subplot( 7 , 8 , ii  )
            hold on
            
            plot(timeaxis-adjustby,coi); %make time start at 0
            plot(timeaxis-adjustby,meancoi) %window averaging
            plot([ 0 80 ] , [threshold threshold]);
            
            if ~isempty(allcommits) % plot manually called commit time by eye
                plot([ allcommits(ii)*timeinterval-adjustby ,  allcommits(ii)*timeinterval-adjustby  ],[ 0 1 ]);
            end
            
            if ~isempty(allcommits) && max(meancoi)>threshold  %calculate difference between manually called commit and commit called by code
                plot([ codecommit ,  codecommit  ],[ 0 1 ] , '--');
                text(50 , 0.5 , [ 'Diff:', num2str(diffincall) , ' min']  , 'Color' , [0 0.3 0.1] , 'FontSize', 10 )
                if diffincall > falseposterr*timeinterval
                    text(50 , 0.5 , [ 'Diff:', num2str(diffincall) , ' min']  , 'Color' , [1 0 0] , 'FontSize', 10 ); %mark false positive with red
                end
                
                if diffincall < falsenegterr*timeinterval
                     text(50 , 0.5 , [ 'Diff:', num2str(diffincall) , ' min']  , 'Color' , [0 0 1] , 'FontSize', 10 ); %mark false negatives with blue
                end
                
            end
            
            title(allcorrels{2,ii} ,'Interpreter','Latex','FontSize', 6 , 'Color' , [0 0.2 0.1])
            
            xlabel('Time (minutes)')
            ylabel('Correlation')
            
            ylim([0 1]);
            xlim([0 105]);
            
            %axis square
            
        end
        
    end
    
    
    allpos = [allpos , falsepos];
    allneg = [allneg , falseneg];
    
end

figure('Name','Error plot'); set(gcf, 'Renderer', 'Painters' );

scatter(testhresholds,allpos,20,'r');
hold on
scatter(testhresholds,allneg,20,'b');
scatter(testhresholds,allneg+allpos,7,'g')

legend('False Positives','False Negatives','Both Errors')

%% 8 - Plot CV data

load('AllCorrelations.mat','allcommits')
load('AllCVs.mat')

movingwindowaverage = 5;
meanthresh = 0.005; stdthresh = -0.005;
cutout = 5;  %data points you want to throw out; you want to ignore the intial signal right after cytokinesis. So, find the max and remove 5 timepoints from there.

figure %plot unprocessed data

for ii = 1:size(allcvs,2)
    
    coi = allcvs{1,ii};
    committime = allcommits(ii);
    timeaxis = [ allframes{ii}(1):allframes{ii}(numel(allframes{ii})) ];
    
    subplot( 5 , 10 , 2*ii-1 ) %plot the unprocessed signal
    
    plot(timeaxis,coi)
    title(allcvs{2,ii},'Interpreter','Latex')
    
    xlabel('Timepoint'); ylabel('CV');
    
end
 legend('CV');

figure %plot processed data

for ii = 1:size(allcvs,2)

    coi = allcvs{1,ii};
    committime = allcommits(ii);
    timeaxis = [ allframes{ii}(1):allframes{ii}(numel(allframes{ii})) ];
    
    [coi,committime,timeaxis] = cleanmaxcutnormalize(coi,committime,timeaxis,cutout); %normalize and flip signal, cut out 5 timepoints after the peak MAPK activity 
    
    
    subplot( 5 , 10 , 2*ii-1 ) %plot the processed signal
    
    plot(timeaxis,coi,'g'); %plot signal
    hold on
    windowmean = movmean(coi,movingwindowaverage); %smooth signal
    windowstd = movstd(coi,movingwindowaverage);
    
    plot(timeaxis,windowmean,'r') %window averaging
    plot(timeaxis,windowstd,'b') %window averaging
    
    if ~isempty(allcommits), plot([ allcommits(ii) allcommits(ii)  ],[ 0 0.4 ],'m'); end %mark commitment point
    
    title(allcvs{2,ii},'Interpreter','Latex')
    
    %plot(timeaxis,sgolayfilt(plotthis,sgolayorder,sgolaywindow)) %sgolay filtering
    
    xlabel('Timepoints')
    ylabel('CVs')
    
    subplot( 5 , 10 ,2*ii) %plot the rate of change and flag calls
    hold on
    slopemean = diff(windowmean); % find slopes for mean and std
    slopestd = diff(windowstd);
    
    plot(timeaxis(1:(end-1)) , slopemean , 'r'  ); % plot slope of mean and std
    plot(timeaxis(1:(end-1)) , slopestd , 'b' );
    
    binslopemean = (slopemean>meanthresh); %find when mean and std cross threshhold
    binslopestd = (slopestd<stdthresh);
    
    andslopes = binslopemean & binslopestd;
    plot(timeaxis(1:(end-1)),andslopes*0.03,'k','LineWidth', 2); %plot flag
    
    if ~isempty(allcommits)
    plot([ allcommits(ii) allcommits(ii)  ],[ 0 1 ]*0.03,'m');
    
    end
    
    %axis square
end

  subplot( 5 , 10 , 2*ii-1 ) %plot the processed signal

legend('Raw',['Smoothed (',num2str(movingwindowaverage) , ')'], 'Std' );



  subplot( 5 , 10 , 2*ii ) %plot the processed signal

legend('Diff(mean)' , 'Diff(std)' , 'Flag');

set(gcf, 'Renderer', 'Painters' );

%% Function to process raw CV data

function [mycellspro,committime,timeaxis] = cleanmaxcutnormalize(mycellspro,committime,timeaxis,cutout)

[M,I] = max(mycellspro);

normcell = 1 - mycellspro/M; %normalize matrix by dividing by max and then flip by subtracting from 1

mycellspro = normcell((I+cutout):end); %copy normalized and cut data into new matrix

timeaxis = timeaxis((I+cutout):end);



committime = committime((I+cutout):end);



end
