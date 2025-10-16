function Decoded_Vect = Convolutional_Decoder(Coded_Vect, Flag_isHalf) 
% Функция выполняет декодирование по алгоритму Витерби блока данных, 
% кодированного сверточным кодом. 
%  
% Входные переменные: 
%   Coded_Vect  – массив-строка кодированных данных;  
%   Flag_isHalf – флаг указывающий на то, какая скорость кодера  
%                 была использована при получении Coded_Vect:  
%                 Flag_isHalf = true  – 1/2,  
%                 Flag_isHalf = false – 1/3. 
% 
% Выходные переменные: 
%   Decoded_Vect – массив-строка декодированных данных.
%
% Использовать встроенные функции poly2trellis и vitdec.

% Описание кодера через poly2trellis
    ConstraintLength = 9;

    if Flag_isHalf
        trellis = poly2trellis(ConstraintLength, [561 753]);
    else
        trellis = poly2trellis(ConstraintLength, [557 663 711]);
    end

% Декодирование с использованием алгоритма Витерби
    Decoded_Vect = vitdec(Coded_Vect, trellis, 8, "term", "hard");

% Удаление 8 последних бит
    Decoded_Vect = Decoded_Vect(1:end-8);
