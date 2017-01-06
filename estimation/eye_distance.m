function im = eye_distance(input)
  %input = 'test.jpg'; %'./data/pic.jpg';
  % read image from input file
  img=imread(input); 
  
  % load model and parameters, type 'help xx_initialize' for more details
  [DM,TM,option] = xx_initialize;
    % perform face alignment in one image.
    faces = DM{1}.fd_h.detect(img,'MinNeighbors',option.min_neighbors,'ScaleFactor',1.2,'MinSize',option.min_face_size);
    %imshow(im); hold on;
    if isempty(faces) 
       im = 0;
    else
          output = xx_track_detect(DM,TM,img,faces{1},option);
          if ~isempty(output.pred)
             left_cen_x = double(output.pred(20,1) + output.pred(23,1))/2;
             left_cen_y = double(output.pred(20,2) + output.pred(23,2))/2;
             right_cen_x = double(output.pred(26,1) + output.pred(29,1))/2;
             right_cen_y = double(output.pred(26,2) + output.pred(29,2))/2;
             
             im = rotateface(img, [left_cen_x;left_cen_y],[right_cen_x;right_cen_y]);
             %imshow(rgb2gray(im));
          else
             im = 0;
          end
     end

end