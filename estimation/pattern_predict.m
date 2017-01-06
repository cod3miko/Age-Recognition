function pattern_predict(video, mean_1, mean_2, mean_3, scale1, scale2, scale3)
input = video;
disp('Initializing tracker...');
[DM,TM,option] = xx_initialize;

% check input
if exist(input,'file') == 2 % if it is a file
  cap = cv.VideoCapture(input);
  frame_w = cap.get('FrameWidth');
  frame_h = cap.get('FrameHeight');
else
  error('Input file not exist');
end

% create a figure to draw upon
S.fh = figure('units','pixels',...
              'position',[100 50 frame_w frame_h],...
              'menubar','none',...
              'name','INTRAFACE_TRACKER',...              
              'numbertitle','off',...
              'resize','off',...
              'renderer','painters');

% create axes
S.ax = axes('units','pixels',...  
            'position',[1 1 frame_w frame_h],...
            'drawmode','fast');

drawed = false; % nor draw anything yet
output.pred = [];    % prediction set to null enabling detection
linel  = 60;    % head pose axis line length
loc    = [70 70]; % where to draw head pose

S.im_h = imshow(zeros(frame_h,frame_w,3,'uint8'));
hold on;

%% tracking and detection
% a while loop is used because OpenCV's 'get_number_frames' has a bug.
while true
  tic;
  %mode = 0(default) : landmark on face is green  due to the it doesn't
  %cross the standard line
  %mode =1 : landmark on face is changed to red to show that taeget is
  %probably lying in the video
  mode = 0;
  
  im = cap.read;
  
  if isempty(im), 
    warning('EOF'); 
    break ;
  end
  
  %% get the information from tracking 
  
  % main function for tracking. previous prediction is used as an input to
  % initialize the tracker for the next frame.
  output = xx_track_detect(DM,TM,im,output.pred,option);
   if ~isempty(output.pred)
    d_1 = pdist2([output.pred(1,1) output.pred(1,2)], [output.pred(20,1) output.pred(20,2)]);
   
    d_2 = pdist2([output.pred(10,1) output.pred(10,2)], [output.pred(29,1) output.pred(29,2)]);

    %distance of upper lip and bottom lip
    d_3 = pdist2([output.pred(35,1) output.pred(35,2)], [output.pred(41,1) output.pred(41,2)]);
    
    if (d_1*scale1) < mean_1 && ((d_2*scale2) < mean_2 || (d_3*scale3) < mean_3)
       mode = 1;
    end
   end
  
  set(S.im_h,'cdata',im); % update frame
  %te = toc;
  if isempty(output.pred) % if lost/no face, delete all drawings
    if drawed, delete_handlers(); end
  else % else update all drawings
    update_GUI();
  end
  drawnow;
end

close;


%%
    % private function for deleting drawing handlers
    function delete_handlers() 
      delete(S.pts_h); %delete(S.time_h);
      delete(S.hh{1}); delete(S.hh{2}); delete(S.hh{3});
      drawed = false;
    end
    % helper function for drawing head pose
    function p2D = projpose(pose,l)
      po = [0,0,0; l,0,0; 0,l,0; 0,0,l];
      p2D = po*pose.rot(1:2,:)';
    end
  
    % private function for updating/creating drawing
    function update_GUI()
    
      if drawed % faster to update than to creat new drawings
        % update head pose
        p2D  = projpose(output.pose,linel); 
        set(S.hh{1},'xdata',[p2D(1,1) p2D(2,1)]+loc(1),'ydata',[p2D(1,2) p2D(2,2)]+loc(2));
        set(S.hh{2},'xdata',[p2D(1,1) p2D(3,1)]+loc(1),'ydata',[p2D(1,2) p2D(3,2)]+loc(2));
        set(S.hh{3},'xdata',[p2D(1,1) p2D(4,1)]+loc(1),'ydata',[p2D(1,2) p2D(4,2)]+loc(2));
        % update tracked points
        set(S.pts_h, 'xdata', output.pred(:,1), 'ydata',output.pred(:,2));
        % update frame/second
        %set(S.time_h, 'string', sprintf('%d FPS',uint8(1/te)));
      else
        p2D  = projpose(output.pose,linel);
        % create head pose drawing
        S.hh{1}=line([p2D(1,1) p2D(2,1)]+loc(1),[p2D(1,2) p2D(2,2)]+loc(2));
        set(S.hh{1},'Color','r','LineWidth',2);
        
        S.hh{2}=line([p2D(1,1) p2D(3,1)]+loc(1),[p2D(1,2) p2D(3,2)]+loc(2));
        set(S.hh{2},'Color','g','LineWidth',2);
        
        S.hh{3}=line([p2D(1,1) p2D(4,1)]+loc(1),[p2D(1,2) p2D(4,2)]+loc(2));
        set(S.hh{3},'Color','b','LineWidth',2);

        
        %% main work
        % create tracked points drawing
        if mode == 0
            S.pts_h   = plot(output.pred(:,1), output.pred(:,2), 'g*', 'markersize',2);
        else
            S.pts_h   = plot(output.pred(:,1), output.pred(:,2), 'r*', 'markersize',2);
        end 
        % create frame/second drawing
        %S.time_h  = text(frame_w-100,50,sprintf('%d FPS',uint8(1/te)),'fontsize',20,'color','m');
        drawed = true;
      end
    end

end



