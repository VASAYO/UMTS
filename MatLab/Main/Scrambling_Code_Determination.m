function SC_Num = Scrambling_Code_Determination(FSignal, ...
 Frame_Offset, SG, Flag_Draw)
% Функция выполняет процедуру определения номера скремблирующей
% последовательности.
%
% Входные переменные:
%   FSignal - комплексный массив, содержащий отсчеты фильтрованного
%             сигнала;
%   SG - номер скремблирующей группы.
%
% Выходные переменные:
%   SC_Num – номер скремблирующей последовательности.

% Генерация скрэмблирующих кодов по указанной скрэмблирующей
% последовательности
    ScrCodes = zeros(8, 38400);

% Генерация каналообразующего кода
    ChCode = Generate_Channelisation_Code(256, 0);

    for k = 0:7
        % Определение аргумента функции
            n = 16*8*SG + 16 * k;
            n = n/16;

        ScrCodes(k +1, :) = Generate_Scrambling_Code(n);
    end

% Выделение из сигнала отсчётов кадра
    FrameSamples = FSignal((1:38400*2) + Frame_Offset);

% Прореживание отсчётов кадра
    FrameChips = FrameSamples(1:2:end);

% Цикл по 8 скр. последовательностям
    Metrics = zeros(150, 8); 

    for ScrIdx = 1:8
        % Дескрэмблирование 
            FrameDeScr = FrameChips .* conj(ScrCodes(ScrIdx, :)) / sqrt(2);

        % Разделение по 256 чипов. Строчки - принятые расширенные 
        % модуляционные символы
            SymbolsSF = reshape(FrameDeScr, 256, 150).';

        for SymIdx = 1:150
            Metrics(SymIdx, ScrIdx) = ...
                sum(SymbolsSF(SymIdx, :) .* ChCode);
        end
    end

% Некогерентное накопление
    MetricsAcc = sum(abs(Metrics), 1);

% Определение номера скрэмблирующей последовательности
    [~, ind] = max(MetricsAcc);
    ind = ind -1;
    SC_Num = 16*8*SG + 16 * ind;
    SC_Num = SC_Num/16;

% Прорисовка результатов
    if Flag_Draw
        figure(Name='Scrambling_Code_Determination.m');
        stem(0:7, MetricsAcc);
        grid on;
    end
