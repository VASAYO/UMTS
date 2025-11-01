function Deinterleaved_Vect = Second_DeInterleaver(Interleaved_Vect)
% Функция выполняет процедуру обратную относительно процедуры второго
% перемежения.
%
% Входные переменные:
%   Interleaved_Vect – массив-строка перемеженных данных.
%
% Выходные переменные:
%   Deinterleaved_Vect – массив-строка деперемеженных данных.

    U = length(Interleaved_Vect);
    C = 30;
    order = [0 20 10 5 15 25 3 13 23 8 18 28 1 11 21 ...
                6 16 26 4 14 24 19 9 29 12 2 7 22 27 17] +1;
    indicies = 1:U;
    new_indicies = [];
    for j_block=1:C
        new_indicies = [new_indicies indicies(order(j_block):C:end)];
    end
    Deinterleaved_Vect(new_indicies) = Interleaved_Vect;
% % Инициализация переменных
%     % Число столбцов перемежителя 
%         C = 30;
% 
%     % Длина входной последовательности
%         U = length(Interleaved_Vect);
% 
%     % Число строк перемежителя 
%         R = ceil(U / C);
% 
%     % Исходные позиции столбцов
%         Perm = [0, 20, 10, 5, 15, 25, 3, 13, 23, 8, 18, 28,  ...
%             1, 11, 21, 6, 16, 26, 4, 14, 24, 19, 9, 29, 12, 2, 7,   ...
%             22, 27, 17]+1;
% 
%     % Выделение памяти под матрицу перемежителя 
%         Interleaver_Matrix = NaN(R, C);
% 
% % Заполнение матрицы 
%     CurrPos = 1;
% 
%     for CurrCol = 1 : C
%         for CurrRow = 1 : R
%             if CurrPos <= U
%                 Interleaver_Matrix(CurrRow, CurrCol) = ...
%                     Interleaved_Vect(CurrPos);
%                 CurrPos = CurrPos + 1;
%             end
%         end
%     end
% 
% % Восстановление исходного порядка столбцов
%     InvPerm = zeros(1, C);
% 
%     for i = 1 : C
%         InvPerm(i) = find(Perm == i);
%     end
% 
% % Обратная перестановка столбцов 
%     OrigMat = Interleaver_Matrix(:, InvPerm);
% 
% % Считывание данных, пропуская NaN
%     Deinterleaved_Vect = [];
% 
%     for CurrRow = 1 : R
%         for CurrCol = 1 : C
%             if ~isnan(OrigMat(CurrRow, CurrCol))
%                 Deinterleaved_Vect = ...
%                     [Deinterleaved_Vect, OrigMat(CurrRow, CurrCol)];
%             end
%         end
%     end
