clear; close all

ScrSeqs = Generate_Scrambling_Groups_Table;

for i = 1:size(ScrSeqs, 1)
    for j = i:size(ScrSeqs, 1)
        for shift = 1:15
            Res(i, j, shift) = sum(ScrSeqs(i,:) == circshift(ScrSeqs(j,:), shift-1), 'all');
        end
    end
end
