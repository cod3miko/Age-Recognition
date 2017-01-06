function face_img = facecut2(im, pic_name)
  %input = 'test.jpg'; %'./data/pic.jpg';
  % read image from input file
  %rgb_im=imread(input);
  
  % load model and parameters, type 'help xx_initialize' for more details
  [DM,TM,option] = xx_initialize;
    % perform face alignment in one image.
    faces = DM{1}.fd_h.detect(im,'MinNeighbors',option.min_neighbors,'ScaleFactor',1.2,'MinSize',option.min_face_size);
    %imshow(im); hold on;
    %disp(size(im));
    if isempty(faces) %no face is detected
        face_img = 0;
        disp('no face detected');
        %disp(input);
        return ;
    else
      output = xx_track_detect(DM,TM,im,faces{1},option);
      if ~isempty(output.pred)
        %plot(output.pred(:,1),output.pred(:,2),'g*','markersize',4);
        left_bound = int16(min([output.pred(1,1), output.pred(20,1), output.pred(38,1)]));
        right_bound = int16(max([output.pred(10,1), output.pred(29,1), output.pred(38,1)]));
        low_bound = int16(max([output.pred(39,2), output.pred(40,2), output.pred(41,2), output.pred(42,2), output.pred(43,2)]));
        %guess
        up_bound = int16(min([(output.pred(3,2) - (output.pred(25,2) - output.pred(3,2))), (output.pred(8,2) - (output.pred(30,2) - output.pred(8,2)))]));
        %disp(right_bound);
        if up_bound < 1
            up_bound = 1;
        end
        left_cen_x = double(output.pred(20,1) + output.pred(23,1))/2 - left_bound;
        left_cen_y = double(output.pred(20,2) + output.pred(23,2))/2 - up_bound;
        right_cen_x = double(output.pred(26,1) + output.pred(29,1))/2 - left_bound;
        right_cen_y = double(output.pred(26,2) + output.pred(29,2))/2 - up_bound;
      else
          disp('output.pred is empty');
          %disp(input);
         face_img = 0;
         return;
      end
    end
    pic = im(up_bound:low_bound,left_bound:right_bound);
    %temp = regexp(pic_name, '/', 'split');
    %disp(['demo/cropface/' cell2mat(temp(3))]);
    face_img = cropface2(pic, [double(left_cen_x) ;double(left_cen_y)], [double(right_cen_x) ;double(right_cen_y)], [0.2;0.2], [210 ;210]);
        
    %imwrite(face_img ,['demo/cropface/' cell2mat(temp(3))]);
    %imshow(face_img);
    %hold off
end
