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

% Параметры 
    % Период корреляционных максимумов в отсчётах
        CorrPeriod = 5120;
    % Число слотов, используемых для накопления
        AccumulationSize = 15;
    % Использовать когерентное накопление. В противном случае будет
    % использовано некогерентное
        useKoherent = 1;
    % Ширина окрестности максимума, которая будет занулена. Чётное число
        OmitWidth = 48;

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

% Когерентное накопление результата
    KoherentRes = abs(sum(CorrRes2, 2));

% Прорисовка результата накопления
    if Flag_Draw 
        figure;
        plot(KoherentRes); grid on;
        title('Когерентное накопление');
    end

% Определяем порог различения базовых станций от шума
    Threshold = 1;

% Обрабатываем все корреляционные максимумы, превышающие порог
    Slots_Offsets = [];

    while sum(KoherentRes >= Threshold) > 0
        % Выбор самого высокого максимума
            [~, Slots_Offsets(end+1)] = max(KoherentRes);
            
        % Зануление выбранного максимума и его окрестностей
            % Определение границ зоны зануления
                if Slots_Offsets(end) - OmitWidth/2 < 1
                    Pos1 = 1;
                else 
                    Pos1 = Slots_Offsets(end) - OmitWidth/2;
                end
                if Slots_Offsets(end) + OmitWidth/2 > CorrPeriod
                    Pos2 = CorrPeriod;
                else 
                    Pos2 = Slots_Offsets(end) + OmitWidth/2;
                end

            KoherentRes(Pos1:Pos2) = 0;
    end
