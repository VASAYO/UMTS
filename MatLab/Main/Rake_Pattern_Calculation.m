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
%   Rake_Pattern - rake-шаблона, структура, содержащая два поля данных: 
%     Correl     - значения КФ пилотного канала       для разных лучей; 
%     dfs        - значения оценок частотных отстроек для разных лучей в 
%                  единицах чиповой скорости. 

% Массив со смещением до лучей
    RayOffsets = Frame_Offset + (-38:38);

% Инициализация результата
    Rake_Pattern.Correl = zeros(length(RayOffsets), 1);
    Rake_Pattern.dfs = zeros(length(RayOffsets), 1);

% Генерация скрэмблирующего кода
    ScrCode = Generate_Scrambling_Code(SC_Num);
% Генерация каналообразующего кода
    ChCode = Generate_Channelisation_Code(256, 0);

% Цикл по лучам
    for RayIdx = 1:length(Rake_Pattern.Correl)
        % Выбор чипов кадра
            FrameChips = FSignal((1:2:38400*2)-1 + RayOffsets(RayIdx));

        % Дескрэмблирование
            FrameChipsDeScr = FrameChips .* conj(ScrCode) / sqrt(2);

        % Шейпинг по расширенным модуляционным символам
            SymbolsSF = reshape(FrameChipsDeScr, 256, 150).';

        % Вычисление символов пилот-канала
            Symbols = zeros(150, 1);
            
            for SymIdx = 1:150
                Symbols(SymIdx) = sum(SymbolsSF(SymIdx, :) .* ChCode);
            end
            
        % Оценка частотной отстройки
            Buf = Symbols(2:end) .* conj(Symbols(1:end-1));
            BufMean = mean(Buf);
            dphi = angle(BufMean);

            % Отстройка в Гц
                dfHz = dphi * (3.84e6 / 256) / (2*pi);
            % В единицах символьной скорости
                Rake_Pattern.dfs(RayIdx) = dfHz / (3.84e6 / 256);

        % Устранение частотной отстройки
            SymbolsTuned = Symbols .* ... 
                exp(-1j*2*pi*Rake_Pattern.dfs(RayIdx) * ...
                    (0:length(Symbols)-1)'/ (3.84e6 / 256) ...
                );

        % Когерентное накопление и запись результата
            Rake_Pattern.Correl(RayIdx) = abs(sum(SymbolsTuned));
    end

% Прорисовка результата
    if Flag_Draw
        figure(Name='Rake_Pattern_Calculation.m');
        plot(-38:38, Rake_Pattern.Correl);
        grid on;
    end


% Домашнее задание:
%   - Сравнить методы оценки частотной отстройки при помощи моделирования;
%   [MatLab\Main\FrequencyDriftEstimation.m];
%   [MatLab\Main\dfEstimateResults.png];
%   - Определить подходящий алгоритм оценки частотной отстройки, дописать
%   функцию.
