function [Flag_isOk, Data] = Check_CRC(InVect, CRC_Size)
% Функция выполняет проверку целостности пакета по заданному значению
% размера блока CRC.
%
% Входные переменные:
%   InVect    – массив-строка, длина которого д.б. больше CRC_Size,
%               первыми следуют полезные биты, далее биты CRC,
%               записанные в обратном порядке;
%   CRC_Size  – размер блока CRC, м.б. равен {24, 16, 12, 8};
%   Flag_isOk – флаг проверки целостности пакета, Flag_isOk = true,
%               если блок признан безошибочным, Flag_isOk = false
%               в противоположном случае.
%
% Выходные переменные:
%   Data - если Flag_isOk = true, то Data - массив-строка полезных данных,
%          иначе Data = [].

% Инициализация длины транспортного блока
    lenInVect = length(InVect);

% Проверка уловия превосходства длины InVect над CRC_Size
    if CRC_Size >= lenInVect
        error(['Длина транспортного блока с битами CRC ' ...
            'должна превосходить длину массива бит CRC']);
    end

% Инициализация блока CRC 
    switch CRC_Size
        case 0
            Flag_isOk = true;
            Data = InVect;
            return;
        case 8
            % SCRC8: D^8 + D^7 + D^4 + D^3 + D + 1
            g = [1 1 0 0 1 1 0 1 1]; 
        case 12
            % SCRC12: D^12 + D^11 + D^3 + D^2 + D + 1
            g = [1 1 0 0 0 0 0 0 0 0 1 1 1]; 
        case 16
            % SCRC16: D^16 + D^12 + D^5 + 1
            g = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]; 
        case 24
            % SCRC24: D^24 + D^23 + D^6 + D^5 + D + 1
            g = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1]; 
        otherwise
            error(['Некорректный размер блока CRC. Допустимые значения:' ...
                '0, 8, 12, 16, 24']);
    end

% Проверка целостности пакета
    % Перезапись CRC бит в прямой порядок
    InVect = [InVect(1:end-CRC_Size), fliplr(InVect(end-CRC_Size+1:end))];

    [~, Remainder] = Polynom_Division(InVect, g);

    if all(Remainder == 0) 
        Flag_isOk = true;
        Data = InVect(1:end-CRC_Size);
    else
        Flag_isOk = false;
        Data = [];
    end


function [Quotient, Remainder] = Polynom_Division(Dividend, Denominator)
% Функция выполняет деление полиномов при этом
% Dividend = Quotient * Denominator + Remainder.
%
% Все переменные – массивы-строки, содержащие значения коэффициентов
% стоящих при степенях полиномов, при этом первый по порядку элемент
% соответствует коэффициенту при старшей степени полинома.
%
% Входные переменные:
%   Dividend    – делимый полином;
%   Denominator – полином-делитель;
%
% Выходные переменные:
%   Quotient    – полином-частное от деления;
%   Remainder   – полином-остаток от деления.
%
% Пример: Dividend      = x^4 + x^3 + 1 = [1, 1, 0, 0, 1]
%         Denominator   = x^2 + 1       = [1, 0, 1]
%         Quotient      = x^2 + x + 1   = [1, 1, 1]
%         Remainder     = x             = [1, 0]

% Инициализация длин входных и выходных переменных
    LenDiv = length(Dividend);
    LenDen = length(Denominator);

    LenQuo = LenDiv - LenDen + 1;
    LenRem = LenDen - 1;

% Выделение памяти под Частное
    Quotient = zeros(1, LenQuo);

% Деление в GF(2)
    for k = 1 : LenQuo
        if Dividend(k) == 1
            Quotient(k) = 1;
            Poses = k + (0:LenDen - 1);
            Dividend(Poses) = mod(Dividend(Poses) - Denominator, 2);
        end
    end

% Инициализация остатка
    Remainder = Dividend((LenDiv - LenRem + 1) : LenDiv);





