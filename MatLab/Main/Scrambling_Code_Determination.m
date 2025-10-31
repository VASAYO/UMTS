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

% Число чипов в одном кадре
    ChipsPerFrame = 38400;

% Генерация каналообразующего кода
    ChCode = Generate_Channelisation_Code(256, 0);

% Генерация 8 скрэмблирующих последовательностей, соответствующих данной
% скрэмблирующей группе
    ScrCodes = zeros(8, 38400);
    for k = 0:7
        % Определение аргумента функции
            n = 8*SG + k;

        ScrCodes(k +1, :) = Generate_Scrambling_Code(n);
    end

% Выбор из сигнала чипов кадра
    FrameChips = FSignal((1:2:ChipsPerFrame*2)-1 + Frame_Offset);

% Цикл по 8 скрэмблирующим последовательностям
    Metrics = zeros(8, 150); % Строки матрицы - массивы вычисленных 
                             % модуляционных символов с использованием
                             % соответствующих номеров скрэмблирующих
                             % последовательностей (8*SG, .., 8*SG+7)

    for ScrIdx = 1:8
        % Дескрэмблирование 
            ChipsDeScr = FrameChips .* conj(ScrCodes(ScrIdx, :)) / sqrt(2);

        % Разделение по 256 чипов. Столбцы - расширенные каналообразующим 
        % кодом модуляционные символы
            SymbolsSF = reshape(ChipsDeScr, 256, 150);

        for SymIdx = 1:150 % Цикл по дерасширению модуляционных символов 
                           % пилот-канала
            Metrics(ScrIdx, SymIdx) = ...
                sum(SymbolsSF(:, SymIdx) .* ChCode.');
        end
    end

% Некогерентное накопление для различных скр-щих последовательностей
    MetricsAcc = sum(abs(Metrics), 2);

% Определение номера скрэмблирующей последовательности
    [~, ind] = max(MetricsAcc);
    ind = ind -1;
    SC_Num = 8*SG + ind;

% Прорисовка результатов
    if Flag_Draw
        figure(Name='Scrambling_Code_Determination.m');
        stem(8*SG+(0:7), MetricsAcc);
        xlabel('Номер скрэмблирующей последовательности');
        ylabel('Результирующая метрика');
        grid on;
    end
