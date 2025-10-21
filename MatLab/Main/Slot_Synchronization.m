function Slots_Offsets = Slot_Synchronization(FSignal, Flag_Draw)
% Функция выполняет процедуру слотовой синхронизации.
%
% Входные переменные:
%   FSignal   - комплексный массив, содержащий отсчеты фильтрованного 
%               сигнала;
%   Flag_Draw – флаг необходимости прорисовки корреляционной
%               кривой, Flag_Draw = true указывает на
%               необходимость прорисовки.
%
% Выходные переменные:
%   Slots_Offsets – массив значений сдвигов в FSignal до начала слотов
%                   найденных сигналов базовых станций.

% Число слотов для накопления сигнала
    N = 50;

% Генерация ПСП
    PSP = Generate_Primary_Synchronisation_Code;

% Вставка нулей
    PSPZeros = upsample(PSP, 2);

% Корреляция с ПСП
    corrRes = conv(FSignal, fliplr(conj(PSPZeros)));

% 
    InReshape = reshape(FSignal(1:5120*N), 5120, N);

    InReshape2 = [];

    for i = 1:N
        InReshape2(:, end+1) = FSignal((1:5120+511) + (i-1)*5120);
    end

    corrRes2 = [];

    for i = 1:size(InReshape, 2)
        corrRes2(:, end+1) = conv(InReshape2(:, i), fliplr(conj(PSPZeros)), "valid");
    end

% Когерентное накопление
    Kog = abs(sum(corrRes2, 2));

% Некогерентное накопление
    NeKog = sum(abs(corrRes2), 2);


    plot(Kog); grid on; figure;
    plot(NeKog); grid on;

% ДЗ:
    % 1. Определить порог
    % 2. Разобраться с видами накопления

    1