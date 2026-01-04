%sukuriame duotu duomenu transponuotas (column vector) matricas
t_C = [13 14 17 18 19 15 13 31 32 29 27]';
t_F = [55 58 63 65 66 59 56 87 90 85 81]';

%sukuriame parametru kintamuosius
n = length(t_F); %dydis pagal duomenu kieki
F = [t_F, ones(n,1)]; %[t_F, 1] antras stulpelis skirtas atsizvelgt i triuksma k2
b = t_C;
%P = 1000 * eye(2); %kovariacijos (kintamuju skirtumo) matrica 
P_values = [1, 10, 100, 1000, 10000];
%x = [0; 0];%k1 k2 
k1 = zeros(length(n), 1);
k2 = zeros(length(n), 1);
%P_values = zeros(length(n), 1);
%kintamieji grafikui
%RLSE
for p = 1:length(P_values) %atliekamas RLSE su skirtingom pradinem P reiksmem
   P = P_values(p) * eye(2);
   
   x = [0; 0];
    for i= 1:n
    Fi=F(i,:); %del geresnio skaitomumo
    
    %gain vector apskaiciavimas, nusako koki svori tures koeficientai k1 k2
    K=P*Fi' / (Fi * P * Fi' + 1);
    
    %atnaujiname parametru ivercius
    x=x + K*(b(i) - Fi * x);
    %atnaujinama stiprinimo(kovariacijos?) matrica
    P=P-K*Fi*P;
    
    end

    k1(p) = x(1);
    k2(p) = x(2);
    fprintf('x ivertis taikant RLSE = %f\n\t\t\t\t\t\t %f\n',x(1),x(2));
end
% k2 netikslus, paieskot kodel
k1

k_pinv= pinv(F)*b;
fprintf('x ivertis taikant pinv() = %f\n\t\t\t\t\t\t %f\n',k_pinv(1),k_pinv(2));

k1_t=5/9;
k2_t=-17-(7/9);
fprintf('k tikrieji = %f\n\t\t\t\t\t\t %f\n',k1_t,k2_t);
%RLSE kiek tikslesnis, su pareguota P matrica galima pasiekt dar geresniu
%rezultatu

% k1,k2 ir P priklausomybes atvaizdavimas
figure;
plot(P_values, k1, '-o', 'DisplayName', 'k1');
hold on;
plot(P_values, k2, '-o', 'DisplayName', 'k2');
hold off;

grid on;
xlabel('Pradiniai P duomenys');
ylabel('Iverciai');
title('k1 k2 ir P priklausomybe');
legend;















%RLSE>LSE del vis atnaujinimo ivercio, reikalauja maziau atminties talpint
%duomenis


