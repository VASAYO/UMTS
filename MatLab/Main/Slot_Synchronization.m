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
    % Ширина окрестности максимума, которая будет занулена (отсчёты слева +
    % отсчёты справа). Д.б. чётным числом
        OmitWidth = 38*2;
    % Максимальное число обрабатываемых базовых станций
        MaxBS = 8;
    % Порог в единицах среднего значения результата накопления
        Threshold = 3.8; % Соответствует Pлт = 1e-5;

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

% Когерентное накопление и нормировка результата на среднее значение
    KoherentRes = abs(sum(CorrRes2, 2));
    KoherentRes = KoherentRes / mean(KoherentRes);

% Обрабатываем корреляционные максимумы, превышающие порог
    Slots_Offsets = [];
    Processing = KoherentRes;
    foundBS = 0;

    while (sum(Processing >= Threshold) > 0) && (foundBS < MaxBS)
        % Выбор самого высокого максимума
            [~, Slots_Offsets(end+1)] = max(Processing);
            
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

            Processing(Pos1:Pos2) = 0;

        foundBS = foundBS + 1;
    end

% Прорисовка результата накопления
    if Flag_Draw 
        figure;
        plot(KoherentRes); grid on;
        yline(Threshold)
        title('Когерентное накопление');
    end

% - Ограничение количества обнаруженных базовых станций. Максимальная число
%   обнаруженных базовых станций: 7-8  [done];
% - Нормировка корреляционной кривой на ср. значение и порог в единицах ср. 
%   значения [done];
% - Ассиметричное зануление окрестностей максимума (20+1+40) 
%   [оставлена система 38+1+38];

% Домашнее задание:
%   - Исследовать зависимость порога от вероятности ложной тревоги 
%   [".\MatLab\Main\FalseAlarm.m"];
%   [".\MatLab\Main\FalseAlarmResults\Зависимость Pлт от величины порога.png"];
