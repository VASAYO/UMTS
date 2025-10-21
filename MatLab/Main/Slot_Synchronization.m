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
Slots_Offsets = [];

% Параметры 
    % Период корреляционных максимумов в отсчётах
        CorrPeriod = 5120;
    % Число слотов, используемых для накопления
        AccumulationSize = 50;
    % Использовать когерентное накопление. В противном случае будет
    % использовано некогерентное
        useKoherent = 1;

% Генерация синхропоследовательности
    PSP = Generate_Primary_Synchronisation_Code;
    PSPZeros = upsample(PSP, 2);
    PSPZeros = PSPZeros(1:end-1);
    PSPZerosLen = length(PSPZeros);

% Корреляция сигнала с ПСП
    CorrRes = conv(FSignal, fliplr(conj(PSPZeros)), "valid");

% Прорисовка результата корреляции
    if Flag_Draw 
        plot(abs(CorrRes)); grid on;
        title('Корреляция сигнала с ПСП');
    end

% Шейпинг сигнала для накопления
    ShapedSignal = zeros(CorrPeriod+PSPZerosLen-1, AccumulationSize);

    for i = 1:AccumulationSize
        ShapedSignal(:, i) = ...
            FSignal((1:CorrPeriod+PSPZerosLen-1) + (i-1)*CorrPeriod).';
    end

% Кореляции с синхропоследовательностью
    CorrRes2 = zeros(CorrPeriod, AccumulationSize);

    for i = 1:AccumulationSize
        CorrRes2(:, i) = ...
            conv(ShapedSignal(:, i), fliplr(conj(PSPZeros)).', "valid");
    end

% Когерентное и некогерентное накопление результата
    KoherentRes = abs(sum(CorrRes2, 2));
    NonKoherentRes = sum(abs(CorrRes2), 2);

% Использовать результаты когерентного или некогерентного накопления при
% дальнейших действиях
    if useKoherent
        AccumulationRes = KoherentRes;
    else
        AccumulationRes = NonKoherentRes;
    end

% Прорисовка результата накопления
    if Flag_Draw 
        figure;
        subplot(2, 1, 1)
        plot(KoherentRes); grid on;
        title('Когерентное накопление');
        subplot(2, 1, 2)
        plot(NonKoherentRes); grid on;
        title('Некогерентное накопление');
        figure
        histogram(abs(KoherentRes)); figure
        histogram(abs(NonKoherentRes));
    end

% ДЗ:
    % 1. Определить порог
    % 2. Разобраться с видами накопления

    1