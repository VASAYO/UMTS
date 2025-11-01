function Deinterleaved_Vect = First_DeInterleaver(Interleaved_Vect, TTI)
% Функция выполняет процедуру обратную относительно процедуры первого
% перемежения.
%
% Входные переменные:
% Interleaved_Vect – массив-строка перемеженных данных;
% TTI – длительность интервала передачи блока данных
% в единицах кадров, м.б. равна 1, 2, 4, 8.
%
% Выходные переменные:
% Deinterleaved_Vect – массив-строка деперемеженных данных.

X = length(Interleaved_Vect);

switch TTI
    case 1
        C = 1;
        Index = 0 +1;
    case 2
        C = 2;
        Index = [0 1] +1;
    case 4
        C = 4;
        Index = [0 2 1 3] +1;
    case 8 
        C = 8;
        Index = [0 4 2 6 1 5 3 7] +1;
end

R = X/C;

IndexMatrix = reshape((1:X), C, R)';
IndexMatrix(:,:) = IndexMatrix(:, Index);
IndexInterleav = reshape(IndexMatrix, 1, X);
Deinterleaved_Vect(IndexInterleav) = Interleaved_Vect;
end