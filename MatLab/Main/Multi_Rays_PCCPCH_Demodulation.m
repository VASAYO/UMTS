function PCCPCH_Bits = Multi_Rays_PCCPCH_Demodulation(Signal, ...
    Rake_Pattern, Frame_Offset, SC_Num, Flag_Draw)
% Функция выполняет многолучевую демодуляцию всех кадров вещательного
% канала, имеющихся в Signal.
%
% Входные переменные:
%   Signal       – комплексный массив, содержащий отсчеты исходного
%                  сигнала;
%   Rake_Pattern - rake-шаблона, структура, содержащая два поля данных:
%     Correl     - значения КФ пилотного канала для разных лучей;
%     dfs        - значения оценок частотных отстроек для разных лучей;
%   Frame_Offset – значение сдвига в FSignal до начала кадра;
%   SC_Num       – номер скремблирующей последовательности;
%   Flag_Draw    – флаг необходимости прорисовки корреляционной
%                  кривой, Flag_Draw = true указывает на
%                  необходимость прорисовки.
%
% Выходные переменные:
% PCCPCH_Bits - массив-строка (длина кратна 270), содержащий значения
%               бит всех кадров канала PCCPCH, считанных из Signal.

Fs = 3.84e6; % Частота дискретизации
Rd = 2; % Удвоение Fs
SF = 256; % Коэффициент расширения
N_SymsPerSlot = 10;
N_SlotsPerFrame = 15;

N_ChipsPerSlot = N_SymsPerSlot * SF; % 2560
N_SymsPerFrame = N_SymsPerSlot * N_SlotsPerFrame; % 150
N_ChipsPerFrame = N_ChipsPerSlot * N_SlotsPerFrame; % 38400

% Зададим, сколько максимум лучей обрабатывать
    N_Rays_Max = 2;

% Сдвинутый к началу кадра сигнал (весь)
    ShiftSignal = Signal(Frame_Offset+1 : 2 : end);
% Число принятых цельных кадров в записи
    N_Frames = floor(length(ShiftSignal) / N_ChipsPerFrame);

% Скремблирующий код
    Sn = Generate_Scrambling_Code(SC_Num);
% Размножим его, чтобы обрабатывать сразу всю запись
    Sns = repmat(Sn, 1,  N_Frames);
% Каналообразующий код пилотного канала
    ChCode4Pilot = Generate_Channelisation_Code(SF, 0);
% Каналообразующий код канала управления
    ChCode4Control = Generate_Channelisation_Code(SF, 1);

% Символы пилотного канала и канала управления
    ChPilot = zeros(1, N_SymsPerFrame * N_Frames);
    ChControl = zeros(1, N_SymsPerFrame * N_Frames);

% Массив с лучами, записанными по строкам
    Rays = zeros(N_Rays_Max, N_ChipsPerFrame * N_Frames);
% Амплитуда по rake-шаблону основного луча
    Ampl_MaxRay = max(Rake_Pattern.Correl(1,:));
% Установим порог амплитуды по rake-шаблону относительно основного луча
    Trashold = 0.1 * Ampl_MaxRay;
% Запишем подходящие лучи в массив
    i = 1; % Число обработанных лучей
    while(true)
        % Амплитуда максимального луча и его позиция
            [Ampl_MaxRay, idxMax] = max(Rake_Pattern.Correl(1,:));
        % Условие выполнения цикла
            if Ampl_MaxRay > Trashold && i <= N_Rays_Max
                % Частотная отстройка для текущего луча
                    df = Rake_Pattern.dfs(idxMax);
                % Сдвиг до текущего луча от начала кадра
                    Shift = Rake_Pattern.Correl(2,idxMax);
                % Согласованная фильтрация
                    FSignal = Matched_Filter(Signal, df);
                % Берём из записи все целые кадры данного луча и сохраняем
                    Rays(i,:) = FSignal(Frame_Offset + Shift + ...
                        (1 : 2 : N_ChipsPerFrame*Rd*N_Frames));
                % Удаляем из rake-шаблона текщий лучь и два его соседа
                    Rake_Pattern.Correl(1, idxMax - 1 : idxMax + 1) = 0;
                % Переходим к следующему лучу
                    i = i + 1;
            else
                % Выходим из цикла, сохраняем фактическое число
                % обработанных лучей
                    N_Rays = i - 1;
                    break
            end
    end
% Обрежем пустое место в массиве, если оно есть
    Rays = Rays(1 : N_Rays, :);


% Дисперсии и ОСШ лучей
    D_Noise = zeros(1, N_Rays);
    SNRs = zeros(1, N_Rays);
% Количество символов во всех кадрах без синхроканалов
    N_SymsPerFrames = (N_SymsPerFrame - N_SlotsPerFrame) * N_Frames;
% Суммарный сигнал
    SumRaysSyms = zeros(1, N_SymsPerFrames);
for i = 1 : N_Rays % Для каждого луча

    % Процедура дескремблирования
        DeScrFrames = Rays(i, :) .* conj(Sns);

    % Процедура, обратная процедуре каналообразования (дерасширение)
        idx1 = 1; % Номер символа сквозь кадры (1..150*N_Frames)
        for j = 1 : SF : length(DeScrFrames) - SF + 1 % Для каждого символа
            ChPilot(idx1) = sum(DeScrFrames(j : j+SF-1) .* ChCode4Pilot);
            ChControl(idx1) = sum(DeScrFrames(j : j+SF-1) .* ChCode4Control);
            idx1 = idx1 + 1; % Переходим к следующему символу
        end

    % Делим символы канала управления на комплексный коэффициент передачи, 
    % оценённый по пилотному каналу
        ChControlSyms_WithSCh = ChControl ./ ChPilot * (1+1i);

    % Избавляемся от синхроканалов
        ChControlSyms = ...
            zeros(1, N_SymsPerFrames);
        i1 = 1; % Индекс для целевого массива
        % Идём по каждому слоту исходного сигнала (с синхроканалами)
        for i2 = 1 : 10 : length(ChControlSyms_WithSCh)
            % Из начала каждого слота убираем 1-ый символ, 9 оставляем
                ChControlSyms(i1 : i1+8) = ...
                    ChControlSyms_WithSCh(i2+1 : i2+9);
                i1 = i1 + 9; % Двигаемся к следующему слоту
        end

    % Отрисовка сигнального созвездия
        if Flag_Draw
            scatterplot(ChControlSyms);
            title(['Лучь ', num2str(i)]);
        end

    % Оценим ОСШ и дисперсию, сохраним результат в массив ко всем лучам
        [SNRs(i), D_Noise(i)] = SNR_Estimate(ChControlSyms);
    
    % Добавляем текущий луч в сумму
        SumRaysSyms = SumRaysSyms + ChControlSyms / D_Noise(i);
end

% Нормируем сумму
    SumRaysSyms = SumRaysSyms / sum(1./D_Noise);
    
% Отрисовка сигнального созвездия
    if Flag_Draw
        scatterplot(SumRaysSyms);
        title('Суммарный сигнал');
    end

% Оценим ОСШ и дисперсию суммарного сигнала
    [SNR_Sum, ~] = SNR_Estimate(SumRaysSyms);
    
% Вывод результата
    if Flag_Draw
        disp('Оценка ОСШ:');
        for i = 1 : length(SNRs)
            disp(['Лучь ', num2str(i), ': SNR = ', num2str(SNRs(i)), ' дБ']);
        end
        disp(['Сумма ОСШ лучей: SNR = ', num2str(sum(SNRs)), ' дБ']);
        disp(['ОСШ суммы лучей: SNR = ', num2str(SNR_Sum), ' дБ']);
    end

% Демодуляция, '-' -> 1, '+' -> 0
    PCCPCH_Bits = zeros(1, 2 * length(SumRaysSyms));
    PCCPCH_Bits(1:2:end) = (-sign(real(SumRaysSyms)) + 1) / 2;
    PCCPCH_Bits(2:2:end) = (-sign(imag(SumRaysSyms)) + 1) / 2;
    PCCPCH_Bits(PCCPCH_Bits ~= 0 & PCCPCH_Bits ~= 1) = 0;

end

function [SNRat, D_Noise] = SNR_Estimate(SigSyms)
    % Амплитуда символа
        AmplSym = mean(abs(SigSyms)) / sqrt(2);
    % Удалим шум
        WithoutNois = ...
            AmplSym * (sign(real(SigSyms)) + 1i * sign(imag(SigSyms)));
    %     scatterplot(WithoutNois);
    % Выделим шум
        Noise = SigSyms - WithoutNois;
    %     scatterplot(Noise);
    % Дисперсия шума
        D_Noise = var(Noise);
    % ОСШ в разах
        SNRat = mean(abs(SigSyms).^2) / D_Noise;
    % Переведём ОСШ в дБ
        SNRat = 10*log10(SNRat);
end
