function [Flag_isOk, BCCH] = Decode_BCCH(Coded_BCCH) 
% Функция выполняет по-2-ух-кадровое декодирование данных вещательного 
% канала. 
% 
% Входные переменные: 
%   Coded_BCCH - массив-строка (длина кратна 270), содержащий значения 
%                бит всех считанных кадров канала BCCH. 
% 
% Выходные переменные: 
%   BCCH      – массив с количеством строк, равным количеству декодирован- 
%               ых транспортных блоков BCCH, и количеством столбцов 246; 
%   Flag_isOk - указывает на то, был ли успешно декодирован хотя бы один 
%               транспортный блок BCCH.

% Инициализация результата
    BCCH = [];

% Параметры
    % Число блоков по 270 бит
        Num270Blocks = length(Coded_BCCH) / 270;

% Выбираем и обрабатываем блоки по 540 бит, каждый раз смещаясь на 270
% бит вперед
    for Pos = 1:Num270Blocks-1
        % Выбираем очередной блок бит длиной 540
            CurrentBlock = Coded_BCCH((1:540) + (Pos-1)*270);

        % Процедура декодирования
            [Flag_isCRCOk, Buf] = Decode_Single_Block540(CurrentBlock);

        % Если CRC сошлось, сохраняем декодированные данные 
            if Flag_isCRCOk
                BCCH(end+1, :) = Buf;
            end
    end

% Определяем значение Flag_isOk
    if numel(BCCH) > 0
        Flag_isOk = true;
    else
        Flag_isOk = false;
    end


function [Flag_isOk, BCCH] = Decode_Single_Block540(Block540)
% Функция декодировния блока длиной 540 бит
%
% Входные парамтеры:
%   Block540 - массив бит длиной 540;
%
% Выходные параметры:
%   Flag_isOk - флаг, указывающий, сошлось ли CRC при декодировании;
%   BCCH      - массив-столбец длиной 246, содержащий биты после 
%               декодирования. Если Flag_isOk = false, то BCCH = [].

% Разбиваем блок на менее крупные блоки по 270 бит
    Blocks270 = reshape(Block540, 270, 2); % Блоки по 270 бит
                                           % расположены по
                                           % столбцам
% Деперемежение блоков по 270
    Blocks270DeInt = zeros(size(Blocks270));
    Blocks270DeInt(:, 1) = Second_DeInterleaver(Blocks270(:, 1)')';
    Blocks270DeInt(:, 2) = Second_DeInterleaver(Blocks270(:, 2)')';

% Объединение деперемежённых блоков
    Block540 = Blocks270DeInt(:)';

% Повторное деперемежение
    Block540DeInt = First_DeInterleaver(Block540, 2);

% Декодирование алгоритмом Витерби
    DecodedBlock = Convolutional_Decoder(Block540DeInt, 1);

% Отбрасывание хвоста и проверка CRC
    [Flag_isOk, BCCH] = Check_CRC(DecodedBlock, 16);
