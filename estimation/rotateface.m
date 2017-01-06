function Cm = rotateface(Im, eye_left, eye_right)
    eye_dir = eye_right - eye_left;
    % translate left_eye to center
    center = floor([size(Im, 2); size(Im, 1)] / 2.0);
    translate_offset = center - eye_left;
    T = maketform('affine', [1 0 0; 0 1 0; translate_offset' 1]);
    Im = imtransform(Im, T, 'XData', [1-translate_offset(1) size(Im, 2)+translate_offset(1)], 'YData', [1-translate_offset(2) size(Im, 1)+translate_offset(2)]);
    % rotate original image around the left eye
    rotate_angle = atan2(eye_dir(2), eye_dir(1)) * 180/pi;
    Im = imrotate(Im, rotate_angle, 'bilinear', 'crop');
    % translate back to left_eye
    T = maketform('affine', [1 0 0; 0 1 0; -translate_offset' 1]);
    Cm = imtransform(Im, T, 'XData', [1+translate_offset(1) size(Im, 2)-translate_offset(1)], 'YData', [1+translate_offset(2) size(Im, 1)-translate_offset(2)]);
end