function F = extract_features(Im)
    % divide image into NxN regions
    N = 7;

    % bin of Uniform patterns: 58
    % bin of non-uniform patterns: 1
    BIN = 59;

    L = LBP(Im, 8, 1);
    F = zeros(N*N, BIN);
    row_step = size(L, 1) / N;
    col_step = size(L, 2) / N;
    for i = 1:N
        i1 = floor((i-1) * row_step) + 1;
        i2 = floor(i * row_step);
        for j = 1:N
            j1 = floor((j-1) * col_step) + 1;
            j2 = floor(j * col_step);
            patch = reshape(L(i1:i2, j1:j2), (i2-i1+1)*(j2-j1+1), 1);
            F((i-1)*N+j, :) = LBP_histoc(patch);
        end
    end

    F = reshape(F', N*N*BIN, 1);
end