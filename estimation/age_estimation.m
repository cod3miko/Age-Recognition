function output = age_estimation(pic_name, target_name)
    
    filename = target_name; %'age_vector.txt'
    fid = fopen(filename, 'w');
      
      rotate_face = eye_distance(pic_name);
      if rotate_face == 0
          output = 0;
          return;
      end
      %2:gray; 3:rgb
      if length(size(rotate_face)) == 3  %rpg
        img = rgb2gray(rotate_face); 
      else %2, gray
        img = rotate_face;
      end
      
      face_pic = facecut2(img);
      if face_pic == 0
        output = 0;
        return;
      end 
      
      fprintf(fid, '%s ', '0');
      
      features = extract_features(face_pic); %size: 531 * 1, length: 531
      for j = 1:length(features)
        fprintf(fid, '%d:%f ', j, features(j,1));
      end
      fprintf(fid, '\n');

    fclose(fid);
    
    output = 1;
    return;
end