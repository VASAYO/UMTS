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

% 1. Цикл по кадрам;
% 2. Внутри цикла: дескр-ние, дерасширение для пилота и для вещательного
%    канала. 
% 3. Получаем 135 * Nкадров мод-ных символов для вскх базовых станций;
% 4. Работаем по главному лучу.

% Генерация скр-щей последовательности
    ScrCode = Generate_Scrambling_Code(SC_Num) / sqrt(2);
% Генерация каналообразующего кода общего пилот канала
    ChCodeCPICH  = Generate_Channelisation_Code(256, 0);
% Генерация каналообразующего кода P-CCPCH
    ChCodePCCPCH = Generate_Channelisation_Code(256, 1);

% Число слотов в одном кадре 
    SlotsPerFrame = 15;
% Длина кадра в отсчётах сигнала с выхода СФ
    FrameLen = 2560*SlotsPerFrame * 2;
% Число бит в одном кадре канала PCCPCH
    BitsPerFrame = 270;

% Согласованная фильтрация сигнала
    FSignal = Matched_Filter(Signal, 0);

% Число кадров в записи
    NumFrames = floor(length(FSignal(Frame_Offset:end)) / FrameLen);

% Инициализация результата
    PCCPCH_Bits = zeros(1, BitsPerFrame*NumFrames);

% Массив модуляционных символов пилот-канала, канала управления до и после
% эквалайзинга
    SymbolsCPICH    = zeros(9, 15, NumFrames);
    SymbolsPCCPCH   = zeros(9, 15, NumFrames);
    SymbolsPCCPCHEq = zeros(9, 15, NumFrames);

% Покадровая обработка PCCPCH
    for FrIdx = 1:NumFrames % Цикл по кадрам
        % Выбор чипов текущего кадра
            FrameChips = FSignal((1:2:38400*2)-1 + Frame_Offset + (FrIdx-1)*FrameLen);

        % Дескрэмблирование
            FrameChipsDeScr = FrameChips .* conj(ScrCode);

        for SlotIdx = 1:SlotsPerFrame % Цикл по слотам обрабатываемого 
                                      % кадра
            % Выделение чипов текущего слота
                SlotChips = FrameChips((1:2560) + (SlotIdx-1)*2560);
            % Удаление 256 первых чипов слота, в течение которых данные не
            % передаются
                PCCPCHChips = SlotChips(256+1:end);

            for SymbIdx = 1:9 % Цикл по символам PCCPCH текущего слота
                % Выделение чипов текущего символа
                    SymbChips = PCCPCHChips((1:256) + (SymbIdx-1)*256);

                % Дерасширение символа пилот-канала
                    PilotSymb = sum(SymbChips .* ChCodeCPICH);
                    SymbolsCPICH(SymbIdx, SlotIdx, FrIdx) = PilotSymb;
                % Дерасширение символа PCCPCH
                    PCCPCHSymb = sum(SymbChips .* ChCodePCCPCH);
                    SymbolsPCCPCH(SymbIdx, SlotIdx, FrIdx) = PCCPCHSymb;

                % Оценка канала
                    mu = PilotSymb / (1+1j);

                % Эквалайзинг
                    PCCPCHSymbEq = PCCPCHSymb / mu;
                    SymbolsPCCPCHEq(SymbIdx, SlotIdx, FrIdx) = PCCPCHSymbEq;

                % Демодуляция символа   
                    Bits = pskdemod(PCCPCHSymbEq, 4, pi/4, "gray", ...
                        "OutputType","bit").';

                % Запись результата в переменную
                    PCCPCH_Bits((FrIdx-1)*270 + (SlotIdx-1)*18 + (SymbIdx-1)*2 + (1:2)) = Bits;
            end
        end
    end

1;