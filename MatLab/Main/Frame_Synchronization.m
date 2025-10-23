function [Frame_Offset, SG] = Frame_Synchronization(FSignal, ... 
Slot_Offset, Flag_Draw)
% Функция выполняет процедуру кадровой синхронизации. 
% 
% Входные переменные: 
%   FSignal     - комплексный массив, содержащий отсчеты фильтрованного  
%                 сигнала; 
%   Slot_Offset – значение сдвига в FSignal до начала слота сигнала 
%                 базовой станций; 
%   Flag_Draw   – флаг необходимости прорисовки корреляционной 
%                 кривой, Flag_Draw = true указывает на 
%                 необходимость прорисовки; 
% 
% Выходные переменные: 
%   
%   Frame_Offset – значение сдвига в FSignal до начала кадра; 
%   SG           - номер скремблирующей группы.
Frame_Offset = [];

% Генерация вторичных синхропоследовательностей
    SSC = Generate_Secondary_Synchronisation_Codes.';
% Генерация таблицы с номерами скрэмблирующих групп
    ScrTable = Generate_Scrambling_Groups_Table;


% Прореживание сигнала и слотовая синхронизация 
    Chips = FSignal(Slot_Offset:2:end).';

% Выбор из сигнала отсчётов первых 15 вторичных синхропоследовательностей
    SSCSamples = zeros(256, 15);

    for i = 1:15
        SSCSamples(:, i) = Chips((1:256) + (i-1)*2560).';

        SSCSamples(:, i) = FSignal((1:2:2*256) + Slot_Offset-1 + (i-1)*5120);
    end

% Определение номера каждой вторичной синхропоследовательности
    SSCNumbers = zeros(1, 15);

    if Flag_Draw
        figure;
    end

    for i = 1:15
        CorrVals = zeros(1, 16);
        for j = 1:16
            CorrVals(j) = sum(SSCSamples(:, i) .* conj(SSC(:, j)));
        end

        % Прорисовка
            if Flag_Draw
                subplot(5, 3, i);
                plot(abs(CorrVals));
                grid on;
                title(i);
            end

        [~, SSCNumbers(i)] = max(CorrVals);
    end

% Определение номера скрэмблирующей группы и циклического сдвига
    HammingResults = zeros(64, 15);

    % Цикл по скрэмблирующим группам
        for i = 1:64
            % Цикл по циклическим сдвигам
                for j = 0:14
                    HammingResults(i, j+1) = sum(circshift(SSCNumbers, j) == ScrTable(i, :));
                end
        end


        [~, ind] = max(HammingResults, [], "all");

    % Номер скрэмблирующей группы
        SG = mod(ind, 64) - 1;

    % Cдвиг
        Shift = floor(ind/64) + 1;
        
% ДЗ: 
%   - Алгоритм, основанный на мягких решениях. 
