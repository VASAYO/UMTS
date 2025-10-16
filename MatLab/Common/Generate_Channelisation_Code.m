function Ch = Generate_Channelisation_Code(SF, k)

% Число уровней дерева
    n = log2(SF)+1;

CurrLevel = [];
LastLevel = 1;


% Цикл
    for i = 1:n-1
        CurrLevel = zeros(2^i);

        for j = 1:size(LastLevel, 1)

            CurrLevel(2*j-1, :) = [LastLevel(j, :), LastLevel(j, :)];
            CurrLevel(2*j, :) = [LastLevel(j, :), -LastLevel(j, :)];

        end

        LastLevel = CurrLevel;
    end

Ch = CurrLevel(k+1, :);
