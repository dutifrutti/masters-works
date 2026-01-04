tau = 0.1; % Laiko konstanta
dt = 0.001; % Laiko žingsnis
t1 = 0:dt:0.5;  
t2 = 0.5:dt:1; 

Uin1 = 1; %  t = [0, 0.5]
Uin2 = 0; %  t = [0.5, 1]
Uout = zeros(size([t1 t2])); % Output 
Uout(1) = 0; % Uout(0) = 0

% Euler's  t = [0, 0.5]
for i = 1:length(t1)-1
    dUout_dt = (Uin1 - Uout(i)) / tau; % Diferencialine lygtis
    Uout(i+1) = Uout(i) + dUout_dt * dt; % Euler žingsnis
end

% Euler's  t = [0.5, 1]
Uout(length(t1)) = 1; % Uout(0.5) = 1

for i = length(t1):(length(t1) - 1 + length(t2) - 1)
    dUout_dt = (Uin2 - Uout(i)) / tau; 
    Uout(i+1) = Uout(i) + dUout_dt * dt; 
end
% Sudeda abu masyvus
t = [t1 t2];

syms U(tt)
% t = [0, 0.5]
eq1 = diff(U, tt) == (1/tau)*Uin1 - (1/tau)*U;
cond1 = U(0) == 0;
U_dsolve1 = dsolve(eq1,cond1);
% t = [0.5, 1]
eq2 = diff(U, tt) == (1/tau)*Uin2 - (1/tau)*U;
cond2 = U(0.5) == 1;
U_dsolve2 = dsolve(eq2,cond2);

%istatom t
U_dsolve1_t = double(subs(U_dsolve1, t1));
U_doslve2_t = double(subs(U_dsolve2, t2));
U_dsolve = [U_dsolve1_t U_doslve2_t];

U_in = ones(size(t));    
U_in(t > 0.5) = 0;

figure;
hold on;
plot(t, U_dsolve, 'r-', 'LineWidth', 3, 'DisplayName', 'dsolve');
plot(t, Uout, 'b-','LineWidth', 1, 'DisplayName', 'Euler');
plot(t, U_in, '--');
xlabel('t (s)');
ylabel('U_out(t)');
grid on;
