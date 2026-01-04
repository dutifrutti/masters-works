
f = @(x) x.^3 - 2*x;
a = 0;
b = 2;

I = 0;
N_values = [4, 8];

for i = 1:length(N_values)
    N = N_values(i);
    h = (b - a) / N;
    x = linspace(a, b, N + 1);
    y = f(x);
    
    % Trapezoidal method
    I_trap = (h/2) * (y(1) + 2*sum(y(2:end-1)) + y(end));
    errors_trapezoidal(i) = abs(I_trap - I);
    
    % Simpson's
    % N lyginis, min 3 taskai
    if mod(N, 2) == 0
        I_simp = (h/3) * (y(1) + 4*sum(y(2:2:end-1)) + 2*sum(y(3:2:end-2)) + y(end));
        errors_simpson(i) = abs(I_simp - I);
    else
        errors_simpson(i) = NaN; 
    end
    
    % Romberg
    r = Romberg(f,a,b,0.0005);
    I_romberg = r(1);
    errors_romberg(i) = abs(I_romberg - I);
end

disp('Integraciju paklaidos:');
disp(table(N_values', errors_trapezoidal', errors_simpson', errors_romberg', ...
    'VariableNames', {'N', 'Trapeciju', 'Simpson', 'Romberg'}));


f = @(x) sin(x) ./ x;
a = 0.001; %kad nebutu dalybos is 0
b = 100;   
IGL = 20;

% Symbolic 
 I = integral(f, a, b)

N = 200; % Number of intervals
h = (b - a) / N; % Step size
x = linspace(a, b, N+1);
y = f(x);
% Simpson
I_simpsons = (h/3) * (y(1) + 4*sum(y(2:2:end-1)) + 2*sum(y(3:2:end-2)) + y(end));

% Adaptive quad
INTf = Adaptive_Simpsons(f,a,b,1e-4);
I_adapt = INTf(1);
I_quad = quad(f, a, b, 1e-4);
I_quadl = quadl(f, a, b, 1e-4);

% Gauss-Legendre
%I_gauss_legendre = integral(f, a, b, 'RelTol', 1e-4, 'AbsTol', 1e-4)
I_gausslegendre = Gauss_Legendre (f, a, b, IGL);

error_simpsons = abs(I_simpsons - I);
error_adapt = abs(I_adapt - I);
error_quad = abs(I_quad - I);
error_quadl = abs(I_quadl - I);
error_gauss_legendre = abs(I_gausslegendre - I);

disp('Paklaidos:');
disp(table({'Simpson', 'Adaptyvi kvadratūra', 'quad()', 'quadl()', 'Gauss-Legendre'}', ...
    [I_simpsons; I_adapt; I_quad; I_quadl; I_gausslegendre], ...
    [error_simpsons; error_adapt; error_quad; error_quadl; error_gauss_legendre]));
