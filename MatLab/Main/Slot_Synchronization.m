function Output = Slot_Synchronization(Input, flag)
%SLOT_SYNCHRONIZATION Summary of this function goes here
%   Detailed explanation goes here

% Число слотов для накопления сигнала
    N = 50;

% Генерация ПСП
    PSP = Generate_Primary_Synchronisation_Code;

% Вставка нулей
    PSPZeros = upsample(PSP, 2);

% Корреляция с ПСП
    corrRes = conv(Input, fliplr(conj(PSPZeros)));

% 
    InReshape = reshape(Input(1:5120*N), 5120, N);

    InReshape2 = [];

    for i = 1:N
        InReshape2(:, end+1) = Input((1:5120+511) + (i-1)*5120);
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