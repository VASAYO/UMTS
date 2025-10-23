% Исследование зависимости вероятности ложной тревоги (ЛТ) от уровня порога
% в задаче обнаружения базовых станций UMTS

clc; clear;
close all;

addpath([cd, '\..\Common']);


%% Параметры моделирования
% Массив значений порога в единицах среднего значения результата накопления
    ThresholdVals = 1:0.2:4;
% Минимальное число ложных тревог для накопления статистики
    MinFA = 1e4;
% Имя файла для сохранения результатов
    ResFileName = 'Results_thr_1_upto_4_step_02_MinFA_1e4';

%% Моделирование 
% Определение вероятности ЛТ в зависимости от порога
    ValsFAP = zeros(size(ThresholdVals));

    for thr_idx = 1:length(ThresholdVals) % Цикл по значениям порога
        % Счётчик ложных тревог
            CountFA = 0;
        % Счётчик испытаний
            CountExp = 0;

        % Накопление статистики
            while CountFA < MinFA   
                % Генерация шума и согласованная фильтрация
                    Noise = (randn(84450, 2) * [1; 1j]).';
                    FNoise = Matched_Filter(Noise, 0);

                % Прогон целевой функции
                    NumFAIter = Step(FNoise, ThresholdVals(thr_idx));

                % Обновление счётчиков
                    CountFA = CountFA + NumFAIter;
                    CountExp = CountExp + 5120;
            end

        % Расчёт вероятности ЛТ для данного значения порога
            ValsFAP(thr_idx) = CountFA / CountExp;
    end

%% Обработка результатов
% Сохранение результатов в файл
    if ~exist([cd, '\FalseAlarmResults'], "dir")
        mkdir([cd, '\FalseAlarmResults']);
    end

    save(['FalseAlarmResults\', ResFileName, '.mat'], ...
        "ValsFAP", "ThresholdVals");

    figure;
    semilogy(ThresholdVals, ValsFAP, '-+'); grid minor;

%% --------------------------------------------------------------------- %%
function NumFalseAlarms = Step(FSignal, Threshold)
% Параметры 
    % Период корреляционных максимумов в отсчётах
        CorrPeriod = 5120;
    % Число слотов, используемых для накопления
        AccumulationSize = 15;

% Генерация синхропоследовательности
    PSP = Generate_Primary_Synchronisation_Code;
    PSPZeros = upsample(PSP, 2);
    PSPZeros = PSPZeros(1:end-1);
    PSPZerosLen = length(PSPZeros);

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

% Определение числа ложных срабатываний как количества отсчётов,
% превышающих порог
    NumFalseAlarms = sum(KoherentRes >= Threshold);
end
