function PCCPCH_Bits = One_Ray_PCCPCH_Demodulation(Signal, ... 
Rake_Pattern, Frame_Offset, SC_Num, Flag_Draw) 
% Функция выполняет однолучевую демодуляцию всех кадров вещательного канала 
% имеющихся в Signal. 
%  
% Входные переменные: 
%   Signal       – комплексный массив, содержащий отсчеты исходного 
%                  сигнала; 
%   Rake_Pattern - rake-шаблона, структура, содержащая два поля данных: 
%     Correl     - значения КФ пилотного канала       для разных лучей; 
%     dfs        - значения оценок частотных отстроек для разных лучей; 
%   Frame_Offset – значение сдвига в FSignal до начала кадра; 
%   SC_Num       – номер скремблирующей последовательности; 
%   Flag_Draw    – флаг необходимости прорисовки корреляционной 
%                  кривой, Flag_Draw = true указывает на 
%                  необходимость прорисовки. 
% 
% Выходные переменные: 
%   PCCPCH_Bits - массив-строка (длина кратна 270), содержащий значения 
%                 бит всех кадров канала PCCPCH, считанных из Signal. 

% Параметры и константы
    % Длина кадра в отсчётах сигнала
        SamplesPerFrame = 5120 * 15;
    % Длина кадра в чипах
        ChipsPerFrame = 2560 * 15;
    % Длина слота в чипах
        ChipsPerSlot = 2560;
    % Число модуляционных символов канала управления в одном слоте
        PCCPCHSymbolsPerSlot = 9;
    % Число слотов в одном кадре
        SlotsPerFrame = 15;
    % Число бит канала управления в одном кадре
        BitsPerFrame = 270;
    % Коэффициент расширения
        SF = 256;

    % Скрэмблирующая последовательность
        ScrCode = Generate_Scrambling_Code(SC_Num) / sqrt(2);
    % Каналообразующие коды пилот-канала и канала управления
        ChCodePilot = Generate_Channelisation_Code(256, 0);
        ChCodeData  = Generate_Channelisation_Code(256, 1);

% Согласованная фильтрация сигнала
    FSignal = Matched_Filter(Signal, 0);

% Определение числа полных кадров, находящихся в записи
    NumFrames = floor(length(FSignal(Frame_Offset:end)) / SamplesPerFrame);

% Выбор чипов из сигнала и разбиение по кадрам
    Buf = FSignal((1:NumFrames*SamplesPerFrame)-1 + Frame_Offset);
    Buf = Buf(1:2:end);
    FramesChips = reshape(Buf, ChipsPerFrame, NumFrames);

% Покадровое дескрэмблирование
    Buf = repmat(ScrCode.', [1 NumFrames]);
    FrameChipsDeScr = FramesChips .* conj(Buf);

% Дерасширение сигнала
    % Память под модуляционные символы пилот-канала
        SymbolsPilot = zeros( ...
            PCCPCHSymbolsPerSlot, SlotsPerFrame, NumFrames);
    % Память под модуляционные символы канала управления
        SymbolsData = zeros( ...
            PCCPCHSymbolsPerSlot, SlotsPerFrame, NumFrames);

    for FrIdx = 1:NumFrames % Цикл по кадрам
        % Выбор чипов кадра и разделение по слотам
            Slots = reshape(FrameChipsDeScr(:, FrIdx), ...
                ChipsPerSlot, SlotsPerFrame);

        % Удаление первых 256 чипов из каждого слота, так как в них не
        % передаются данные общего канала управления
            Slots = Slots(256+1:end, :);

        for SlIdx = 1:SlotsPerFrame % Цикл по слотам
            % Разделение слота на группы по 256 чипов, соответствующие
            % расширенным модуляционным символам
                Chips = reshape(Slots(:, SlIdx), SF, []);

            % Процедура дерасширения символов данного слота
                SymbolsPilot(:, SlIdx, FrIdx) = (ChCodePilot * Chips).';
                SymbolsData (:, SlIdx, FrIdx) = (ChCodeData  * Chips).';
        end
    end

% Оценка канала и эквалайзинг
    % Оценка канала по символам пилот-канала
        mu = SymbolsPilot ./ (1 + 1j);

    % Эквалайзинг данных канала управления
        SymbolsDataEq = SymbolsData ./ mu;

% Демодуляция символов канала управления
    Buf = SymbolsDataEq(:);

    PCCPCH_Bits = nan(1, BitsPerFrame*NumFrames);
    for k = 1:BitsPerFrame*NumFrames/2
        if (real(Buf(k)) >= 0)
            PCCPCH_Bits(2*(k -1) + 1) = 0;
        else
            PCCPCH_Bits(2*(k -1) + 1) = 1;
        end
        if (imag(Buf(k)) >= 0)
            PCCPCH_Bits(2*k) = 0;
        else
            PCCPCH_Bits(2*k) = 1;
        end
    end

% Прорисовка результатов
    if Flag_Draw
        figure(Name='One_Ray_PCCPCH_Demodulation.m');
        subplot(2,2,1);
        plot(SymbolsPilot(:), '.');
        grid on; axis equal;
        title('Символы пилот-канала');

        subplot(2,2,2);
        plot(SymbolsData(:), '.');
        grid on; axis equal;
        title('Символы канала управления');

        subplot(2,2,[3 4]);
        plot(SymbolsDataEq(:), '.');
        grid on; axis equal;
        title({'Символы канала управления','после эквалайзинга'});
    end
