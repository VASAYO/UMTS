% Сравнение методов оценки частотной отстройки по последовательности
% модуляционных символов
% 
% Исходные данные: 
%   - 150 одинаковых модуляционных символов;
%   - канал с АБГШ;
%   - максимальная частотная отстройка до 3700 Гц.
% 
% Метод 1: умножение каждой точки на сопряженную предыдущую, усреднение по
%          149 произведениям, после чего взятие angle() от результата;
% 
% Метод 2: умножение каждой точки на сопряженную предыдущую, взятие angle()
%          от 149 произведений, после чего усреднение результата.

clc; clear;
close all;

% Параметры моделирования
    % Массив значений ОСШ на бит, дБ
        EsNoVals = 0:20;
    % Номер метода
        Method = 1;
    % Отстройка частоты, Гц
        dfVals = [0 3700];
    % Символьная скорость в UMTS при SF = 256, Гц
        Rs = 3.84e6 / 256;
    % Число итераций
        NumIter = 1e5;
    % Символы
        Symbols = ones(150, 1);

% Массив значений оценок
    dfEstVals = zeros(NumIter, length(EsNoVals), length(dfVals));

for dfIdx = 1:length(dfVals) % Цикл по частотным отстройкам
    df = dfVals(dfIdx);

    for snrIdx = 1:length(EsNoVals) % Цикл по значениям ОСШ
        EsNo = EsNoVals(snrIdx);

        for IterIdx = 1:NumIter % Накопление статистики
            % Добавление АБГШ
                % Генерация комплексного шума
                    No = 1 / 10^(EsNo/10);
                    Noise = randn(length(Symbols), 2) * [1; 1j];
                    Noise = Noise * sqrt(No/2);
                NSymbols = Symbols + Noise;
            % Добавление частотной отстройки
                Rx = NSymbols .* exp(1j*2*pi*df * (0:length(NSymbols)-1)' /Rs);
        
            switch Method % Оценка частотной отстройки
                case 1 % Метод 1
                    RxDiff = Rx(2:end) .* conj(Rx(1:end-1));
                    MeanRes = mean(RxDiff);
                    dPhi = angle(MeanRes);
                    dfEstVals(IterIdx, snrIdx, dfIdx) = dPhi * Rs / (2*pi);
        
                case 2 % Метод 2
                    RxDiff = Rx(2:end) .* conj(Rx(1:end-1));
                    AngleRes = angle(RxDiff);
                    dPhi = mean(AngleRes);
                    dfEstVals(IterIdx, snrIdx, dfIdx) = dPhi * Rs / (2*pi);
        
                otherwise
                    error('Выберите корректный метод оценки');
            end
        end
    end
end

% Дисперсия и СКО оценки
    VarVals = squeeze(var(dfEstVals));
    StdVals = sqrt(VarVals);

% Выводы по результатам моделирования:
%   - В самом худшем случае (df = 3700 Гц) метод 2 начинает разваливаться
%     при EsNo <= 11 дБ; в лучшем (df = 0 Гц) - при EsNo <= 9 дБ;
%   - Метод 1 стабилен при любых значениях частотной отсройки, однако в
%     среднем его дисперсия выше.