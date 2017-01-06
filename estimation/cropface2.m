function Cm = cropface(Im, eye_left, eye_right, offset_pct, dest_sz)
    offset = floor(offset_pct .* dest_sz);
    eye_dir = eye_right - eye_left;
    eye_dist = sqrt(sum(eye_dir.^2));
    eye_ref_width = dest_sz(1) - 2.0*offset(1);
    eye_scale = eye_dist / eye_ref_width;
    
    % translate left_eye to center
    %%center = floor([size(Im, 2); size(Im, 1)] / 2.0);
    %%translate_offset = center - eye_left;
    %%T = maketform('affine', [1 0 0; 0 1 0; translate_offset' 1]);
    %%Im = imtransform(Im, T, 'XData', [1-translate_offset(1) size(Im, 2)+translate_offset(1)], 'YData', [1-translate_offset(2) size(Im, 1)+translate_offset(2)]);
    % rotate original image around the left eye
    %%rotate_angle = atan2(eye_dir(2), eye_dir(1)) * 180/pi;
    %%Im = imrotate(Im, rotate_angle, 'bilinear', 'crop');
    % translate back to left_eye
    %%T = maketform('affine', [1 0 0; 0 1 0; -translate_offset' 1]);
    %%Im = imtransform(Im, T, 'XData', [1+translate_offset(1) size(Im, 2)-translate_offset(1)], 'YData', [1+translate_offset(2) size(Im, 1)-translate_offset(2)]);


    % crop the rotated image
    crop_xy = -floor(eye_left - eye_scale*offset);
    crop_sz = floor(dest_sz*eye_scale);
    crop_rat = eye_scale*offset ./ eye_left;
    crop_size = floor([crop_rat(2) crop_rat(1)] .* size(Im));
    Im = imresize(Im, crop_size);

    %Im = Im(crop_xy(2):final_sz(2), crop_xy(1):final_sz(1));
    Cm = imresize(Im, dest_sz');
end