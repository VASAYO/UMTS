function Slots_Offsets = Slot_Synchronization(FSignal, Flag_Draw)
% Функция выполняет процедуру слотовой синхронизации.
%
% Входные переменные:
%   FSignal   - комплексный массив, содержащий отсчеты фильтрованного 
%               сигнала;
%   Flag_Draw – флаг необходимости прорисовки корреляционной
%               кривой, Flag_Draw = true указывает на
%               необходимость прорисовки.
%
% Выходные переменные:
%   Slots_Offsets – массив значений сдвигов в FSignal до начала слотов
%                   найденных сигналов базовых станций.

% Параметры 
    % Длительность слота в отсчётах
        SlotLen = 5120;
    % Число слотов, используемых для накопления
        AccumulateSlots = 15;
    % Число отсчётов, которые будут занулены слева и справа от
    % корреляционного максимума при обнаружении базовой станции
        OmitLeft = 38;
        OmitRight = 38;
    % Максимальное число обрабатываемых базовых станций
        MaxBS = 8;
    % Порог в единицах среднего значения результата накопления
        Threshold = 3.8; % Соответствует Pлт = 1e-5;

% Генерация синхропоследовательности и добавление нулей
    PSP = Generate_Primary_Synchronisation_Code;
    PSPZeros = upsample(PSP, 2);
    PSPZeros = PSPZeros(1:end-1);
    PSPZerosLen = length(PSPZeros);

% Выбор отсчётов сигнала для корреляции
    CorrSignal = FSignal(1:SlotLen*AccumulateSlots + PSPZerosLen-1);

% Корреляция с синхропоследовательностью
    CorrRes = conv(CorrSignal, fliplr(conj(PSPZeros)), "valid");

% Шейпинг сигнала для накопления
    CorrResShaped = reshape(CorrRes, SlotLen, AccumulateSlots);

% Когерентное накопление результата
    AccumRes = abs(sum(CorrResShaped, 2));

% Нормировка на среднее значение
    AccumRes = AccumRes / mean(AccumRes);

% Обрабатываем корреляционные максимумы, превышающие порог
    Slots_Offsets = [];
    Processing = AccumRes;
    foundBS = 0;

    while (sum(Processing >= Threshold) > 0) && (foundBS < MaxBS)
        % Выбор самого высокого максимума
            [~, Slots_Offsets(end+1)] = max(Processing);
            
        % Зануление выбранного максимума и его окрестностей
            % Определение границ зоны зануления
                if Slots_Offsets(end) - OmitLeft/2 < 1
                    Pos1 = 1;
                else 
                    Pos1 = Slots_Offsets(end) - OmitLeft/2;
                end
                if Slots_Offsets(end) + OmitRight/2 > SlotLen
                    Pos2 = SlotLen;
                else 
                    Pos2 = Slots_Offsets(end) + OmitRight/2;
                end

            Processing(Pos1:Pos2) = 0;

        foundBS = foundBS + 1;
    end

% Вычитаем 1 из всех элементов результирующего массива чтобы получить
% корректный результат (т.е. сколько первых отсчётов сигнала надо 
% пропустить, чтобы синхронизироваться со слотами той или иной базовой 
% станции)
    Slots_Offsets = Slots_Offsets - 1;

% Прорисовка результата накопления
    if Flag_Draw 
        figure(Name='Slot_Synchronization.m');
        plot(AccumRes); grid on;
        xlim([1 5120])
        yline(Threshold);
        title('Когерентное накопление');
    end

% - Ограничение количества обнаруженных базовых станций. Максимальная число
%   обнаруженных базовых станций: 7-8  [done];
% - Нормировка корреляционной кривой на ср. значение и порог в единицах ср. 
%   значения [done];
% - Ассиметричное зануление окрестностей максимума (20+1+40) 
%   [оставлена система 38+1+38];

% Домашнее задание:
%   - Исследовать зависимость порога от вероятности ложной тревоги 
%   [".\MatLab\Main\FalseAlarm.m"];
%   [".\MatLab\Main\FalseAlarmResults\Зависимость Pлт от величины порога.png"];
