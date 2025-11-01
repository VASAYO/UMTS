function Rake_Pattern = Rake_Pattern_Calculation(Signal, FSignal, ... 
Frame_Offset, SC_Num, Flag_Draw) 
% Функция выполняет процедуру построения rake-шаблона. 
% 
% Входные переменные: 
%   Signal       – комплексный массив, содержащий отсчеты исходного 
%                  сигнала; 
%   FSignal      - комплексный массив, содержащий отсчеты фильтрованного 
%                  сигнала; 
%   Frame_Offset – значение сдвига в FSignal до начала кадра; 
%   SC_Num       – номер скремблирующей последовательности; 
%   Flag_Draw    – флаг необходимости прорисовки корреляционной 
%                  кривой, Flag_Draw = true указывает на 
%                  необходимость прорисовки. 
% 
% Выходные переменные:      
%   Rake_Pattern - rake-шаблона, структура, содержащая поля данных:
%     Correl     - значения КФ пилотного канала       для разных лучей; 
%     dfs        - значения оценок частотных отстроек для разных лучей в 
%                  единицах чиповой скорости;
%     dfsHz      - значения оценок частотных отстроек для разных лучей в
%                  Гц;
%   Rays_Offsets - сдвиги в FSignal до соответсвующих лучей.

% Массив со смещением до лучей
    Rays_Offsets = Frame_Offset + (-38:38);

% Инициализация результата
    Rake_Pattern.Correl       = zeros(1, length(Rays_Offsets));
    Rake_Pattern.dfs          = zeros(1, length(Rays_Offsets));
    Rake_Pattern.dfsHz        = zeros(1, length(Rays_Offsets));
    Rake_Pattern.Rays_Offsets = Rays_Offsets;

% Генерация скрэмблирующей последовательности
    ScrSeq = Generate_Scrambling_Code(SC_Num);
% Генерация каналообразующего кода
    ChCode = Generate_Channelisation_Code(256, 0);

for RayIdx = 1:length(Rake_Pattern.Correl) % Цикл по лучам
    % Получение модуляционных символов пилот-канала для данного луча
        Symbols = Get_Symbols_from_FSignal( ...
            FSignal, Rays_Offsets(RayIdx), ScrSeq, ChCode);
        
    % Оценка частотной отстройки
        [Rake_Pattern.dfs(RayIdx), Rake_Pattern.dfsHz(RayIdx)] = ...
            dfEstimate(Symbols, 2);

    % Согласованная фильтрация сигнала с учетом частотной отстройки
        FSignalTuned = Matched_Filter(Signal, Rake_Pattern.dfs(RayIdx));

    % Повторное получение модуляционных символов
        SymbolsTuned = Get_Symbols_from_FSignal( ...
            FSignalTuned, Rays_Offsets(RayIdx), ScrSeq, ChCode);

    % Когерентное накопление и запись результата
        Rake_Pattern.Correl(RayIdx) = abs(sum(SymbolsTuned));
end

% Прорисовка результата
    if Flag_Draw
        figure(Name='Rake_Pattern_Calculation.m');
        subplot(2, 1, 1);
        stem(Rays_Offsets, Rake_Pattern.Correl);
        xlabel('Сдвиги до лучей');
        ylabel('Значения КФ пилотного канала');
        grid on;
        xline(Frame_Offset);

        subplot(2, 1, 2);
        stem(Rays_Offsets, Rake_Pattern.dfsHz);
        xlabel('Сдвиги до лучей');
        ylabel('Частотные отстройки лучей, Гц');
        grid on;
        xline(Frame_Offset);
    end


% --- Функции ----------------------------------------------------------- %
function Symbols = Get_Symbols_from_FSignal( ...
    FSignal, Frame_Offset, ScrSeq, ChCode)
% Функция получает модуляционные символы общего пилот-канала из сигнала с
% выхода согласованного фильтра
%
% Входные параметры:
%   FSignal      - комплексный массив-строка, содержащий отсчеты 
%                  фильтрованного сигнала; 
%   Frame_Offset – значение сдвига в FSignal до начала кадра;
%   ScrSeq       - комплексный массив-строка, содержащий отсчёты
%                  скрэмблирующей последовательности;
%   ChCode       - комплексный массив-строка, содержащий отсчёты
%                  каналообразующего кода.
% 
% Выходные параметры: 
%   Symbols - комплексный массив-строка, содержащий модуляционные символы
%             общего пилот-канала.

% Выбор чипов
    Chips = FSignal((1:2:38400*2)-1 + Frame_Offset);
% Дескрэмблирование
    ChipsDeScr = Chips .* conj(ScrSeq) / sqrt(2);
% Шейпинг по расширенным модуляционным символам
    SymbolsSF = reshape(ChipsDeScr, 256, 150).';
% Процедура дерасширения модуляционных символов
    Symbols = SymbolsSF * ChCode.';


function [df, dfHz] = dfEstimate(Symbols, Method)
% Функция выполняет оценку частотной отстройки по последовательности
% модуляционных символов пилот-канала
%
% Входные параметры:
%   Symbols - комплексный массив, содержащий последовательность
%             модуляционных символов пилот-канала; 
%   Method  - значение, определяющее метод оценки частотной отстройки.
%             Может принимать значения 1 или 2.
% 
% Выходные параметры:
%   df   - частотная отстройка в единицах чиповой скорости (3.84e6 Гц).
%   dfHz - частотная отстройка в Гц.
%
% Методы оценки частотной отстройки:
%   Метод 1 - умножение каждой точки на сопряженную предыдущую, усреднение 
%             по 149 произведениям, после чего взятие angle() результата;
%   Метод 2 - умножение каждой точки на сопряженную предыдущую, взятие 
%             angle() от 149 произведений, после усреднение результата.

% Чиповая и символьная скорость
    RChip = 3.84e6;
    Rs    = RChip / 256;
    Ts    = 1/Rs;

switch Method
    case 1 % Метод 1
        SymDiff = Symbols(2:end) .* conj(Symbols(1:end-1));
        MeanRes = mean(SymDiff);
        dPhi    = angle(MeanRes);
        dfHz    = dPhi / (2*pi * Ts);
        df      = dfHz / RChip;

    case 2 % Метод 2
        SymDiff = Symbols(2:end) .* conj(Symbols(1:end-1));
        AngleRes = angle(SymDiff);
        dPhi    = mean(AngleRes);
        dfHz    = dPhi / (2*pi * Ts);
        df      = dfHz / RChip;

    otherwise
        error('Выберите корректный метод оценки частотной отстройки.');
end


% Домашнее задание:
%   - Сравнить методы оценки частотной отстройки при помощи моделирования;
%   [MatLab\Main\FrequencyDriftEstimation.m];
%   [MatLab\Main\dfEstimateResults.png];
%   - Определить подходящий алгоритм оценки частотной отстройки, дописать
%   функцию.
