close all;

PSC = Generate_Primary_Synchronisation_Code();

f = (-60e3:1e3:60e3);
L = length(PSC);
lags = (-L+1:L-1);

corr1 = zeros(length(f), 511);
for i = 1:length(f)

corr1(i, :) = conv(PSC .* exp(1j*2*pi*f(i)*(0:255)./3.84e6), fliplr(conj([zeros(0,L-1), PSC, zeros(0,L-1)])));
end

surf(lags, f, (abs(corr1))); 
grid on;

Sechf0 = corr1(f == 0, :);
Secht0 = corr1(:, lags == 0);

figure;
plot(lags, abs(Sechf0))
grid on;
figure;
plot(f, 10*log10(abs(Secht0)/max(abs(Secht0))))
grid on;

%% Вторичная СП
close all;

PSC = Generate_Secondary_Synchronisation_Codes();
PSC = PSC(6,:);
SSC = Generate_Secondary_Synchronisation_Codes();
SSC = SSC(1,:);

f = (-60e3:1e3:60e3);
L = length(SSC);
lags = (-L+1:L-1);

corr1 = zeros(length(f), 511);
for i = 1:length(f)

corr1(i, :) = conv(SSC .* exp(1j*2*pi*f(i)*(0:255)./3.84e6), fliplr(conj([zeros(0,L-1), PSC, zeros(0,L-1)])));
end

surf(lags, f, (abs(corr1))); 
grid on;

Sechf0 = corr1(f == 0, :);
Secht0 = corr1(:, lags == 0);

figure;
plot(lags, abs(Sechf0))
grid on;
figure;
plot(f, 10*log10(abs(Secht0)/max(abs(Secht0))))
grid on;