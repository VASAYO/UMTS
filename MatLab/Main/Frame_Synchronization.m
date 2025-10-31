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

% Длительность слота в отсчётах
    SlotLen = 5120;

% Генерация вторичных синхропоследовательностей
    SSC = Generate_Secondary_Synchronisation_Codes;
% Генерация таблицы с номерами скрэмблирующих групп
    ScrTable = Generate_Scrambling_Groups_Table;

% Выбор из сигнала отсчётов первых 15 вторичных синхропоследовательностей
    SSCSamples = zeros(15, 256);

    for idx = 1:15
        SSCSamples(idx, :) = ...
            FSignal((1:2:2*256)-1 + Slot_Offset + (idx-1)*SlotLen);
    end

% Корреляция каждой из 15 принятых последовательностей с 16 эталонными
    CorrVals = zeros(15, 16);

    for rx_idx = 1:15
        for ref_idx = 1:16
            CorrVals(rx_idx, ref_idx) = ...
                sum(SSCSamples(rx_idx, :) .* conj(SSC(ref_idx, :)));
        end
    end
    clear ref_idx rx_idx;

% Расчёт корреляционной метрики для каждой скрэмблирующей группы и для всех
% вариантов циклического сдвига
    Metrics = zeros(64, 15); % Строки соответствуют номеру 
                             % скрэмблирующей группы (0..63), а столбцы - 
                             % циклическим сдвигам
                             % соответствующей скр-щей группы (0..14)

    for scr_idx = 0:63 % Цикл по номерам скрэмблирующих групп
        for sht_idx = 0:14 % Цикл по циклическим сдвигам

            % Текущия скрэмблирующая группа с циклическим сдвигом
                Scr_shft = circshift(ScrTable(scr_idx +1, :), sht_idx);

            % Вычисление метрики
                for sum_idx = 1:15
                    Metrics(scr_idx +1, sht_idx +1) = ...
                        Metrics(scr_idx +1, sht_idx +1) ...
                                    + ...
                        CorrVals(sum_idx, Scr_shft(sum_idx));
                end
        end
    end

% Определение номера скрэмблирующей группы по номеру строчки Metrics
    Buf = max(abs(Metrics), [], 2);
    [~, SG] = max(Buf);
    SG = SG-1;

% Кадровая синхронизация
    Buf = max(abs(Metrics), [], 1);
    [~, Shift] = max(Buf);
    Shift = Shift-1;

    Frame_Offset = Slot_Offset + Shift*SlotLen;


% Прорисовка результатов
    if Flag_Draw
        figure(Name='Frame_Synchronization.m');

        surf(0:14, 0:63, abs(Metrics));

        % Подписи
            title({'Корреляционные метрики для', ...
                ['Slot\_Offset = ', num2str(Slot_Offset)]} ...
            );
            xlabel('Циклический сдвиг');
            ylabel('Номер скрэмблирующей группы');
    end
