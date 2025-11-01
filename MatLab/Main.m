% Очистка динамической памяти и Command Window
    clc;
    clear;
    close all;
    
% Добавление путей
    path([cd, '\Signals'], path);
    path([cd, '\Common'], path);
    path([cd, '\Main'], path);
    
% Загрузка массива Signal с записью сигнала    
    % Beeline Megafon Megafon5 Megafon99 Megafon99_01 MTS   
    load('MTS');    % В кавычках указывается имя файла из
                    % которого будет считана запись сигнала
% Удаление отсчётов сигнала с артефактами
    Signal = Signal(7:end);
         
% Согласованная фильтрация сигнала    
    df = 0; % Пока что нет оснований выбрать другое значение частотной 
            % отстройки
    FSignal = Matched_Filter(Signal, 0);

% Слотовая синхронизация - поиск базовых станций (БС)
    Slots_Offsets = Slot_Synchronization(FSignal, 0);
    
% Для каждой найденной БС проводим следующие процедуры обработки
    if ~isempty(Slots_Offsets)
        % Создадим переменную для хранения транспортных блоков вещательного
        % канала найденных БС
            BCCHs = cell(length(Slots_Offsets), 1);

        for k = 1:1 %length(Slots_Offsets) % Для каждой БС
            % Кадровая синхронизация    
                [Frame_Offset, SG] = Frame_Synchronization(FSignal, ...
                    Slots_Offsets(1, k), 0);

            % Определение номера скремблирующей последовательности    
                SC_Num = Scrambling_Code_Determination(FSignal, ...
                    Frame_Offset, SG, 0);

            % Построение rake-шаблона
                Rake_Pattern = Rake_Pattern_Calculation(Signal, ...
                    FSignal, Frame_Offset, SC_Num, 0);

            % % Демодуляция вещательного канала
            %     PCCPCH_Bits = One_Ray_PCCPCH_Demodulation(Signal, ...
            %         Rake_Pattern, Frame_Offset, SC_Num, true);
            % % Декодирование транспортных блоков вещательного канала
            %     [Flag_isOk, BCCH] = Decode_BCCH(PCCPCH_Bits);
            %     display(Flag_isOk);
            % % Сохранение полученных данных
            %     BCCHs{k, 1} = BCCH;
        end
    end

% Сообщение о завершении работы
    fprintf('%s Обработка завершена.\n', datestr(now));
    
% Удаление путей
%     rmpath([cd, '\Signals']);
%     rmpath([cd, '\Common']);
%     rmpath([cd, '\Main']);