clc;
close all;
%symbolinis kintamasis != paprastai skaitinei reiksmei, be syms f1..fn
%iskart grazintu skaiciu
%leidzia atvaizduoti tiksliai funkcijas, reiksmes gaunamas su subs, double
syms x;
f1 = @(x) (1 + x) ./ log(1 + x); % range 1:5
f2 = @(x) 1 ./ (1 + exp(x)); % -10:10
f3 = @(x) x ./ (1 + x.^2); % -10:10
f4 = @(x) x ./ (1 + x.^2); % 0:2
f5 = @(x) x ./ (1 + x.^3); % 0:2
f6 = @(x) 1 ./ (1 + x.^4); % -2:2

orders = [2, 3, 5, 7, 9];
ranges = {1:0.01:5, -10:0.1:10, -10:0.1:10, 0:0.01:2, 0:0.01:2, -2:0.01:2};
functions = {f1, f2, f3, f4, f5, f6};

    mse_lagrange = [];
    mse_newton = [];
    mse_spline = [];
    mse_pade = [];
    mse_chebyshev = [];
    max_err_lagrange = [];
    max_err_newton = [];
    max_err_spline = [];
    max_err_pade = [];
    max_err_chebyshev = [];

%subs istato reiksmes i funkcija, double pavercia skaitine
%reiksme(grafai,tolimesni skaiciavimai)

%for i = 1:length(functions)
    i=1;
    f = functions{i};
    x_og = ranges{i};
    y_og = f(x_og);
    figure;
    hold on;
    plot(x_og, y_og, 'k', 'LineWidth', 3, 'DisplayName', 'Original Function');

    for order = orders
        %n eiles interpoliacijai/aproksimacijai reikalingai n+1 taskai
        %(order)
        %taskai interpoliacijai
        n = order + 1;
        %tolygus taskai
        x_values = linspace(min(x_og), max(x_og), n);
        %Čebysovo mazgai [-1:1] intervale; k=0 ar k=1 patogu pasirinkt
        %pagal programavimo kalba 
        
        k = [1:n];
        theta = (2 * k - 1) * pi / (2 * n); %kampai
        xn = cos(theta); 
        %Čebysovo mazgai pagal ranges{i} intervala
        a = min(x_og); b = max(x_og);
        chebyNodes = ((b-a)*xn +a + b)/2;     
        y = f(x_values);
        
        scatter(x_values, y, 50, 'DisplayName', ['Interpolation points', num2str(order)]);
 
        %Lagrange
        lagrange = lagrangeapprox(x_values,y,order);
        y_lagrange = polyval(lagrange, x_og);
        mse_lagrange = [mse_lagrange, mean((y_og - y_lagrange).^2)];
        max_err_lagrange = [max_err_lagrange, max(abs(y_og - y_lagrange))];
        plot(x_og, y_lagrange, 'LineWidth', 1, 'DisplayName', ['Lagrange Order ', num2str(order)]);

        %Newton
        newton = newtonapprox(x_values,y,order);
        y_newton = polyval(newton, x_og);
        mse_newton = [mse_newton, mean((y_og - y_newton).^2)];
        max_err_newton = [max_err_newton, max(abs(y_og - y_newton))];
        plot(x_og, y_newton, '--', 'LineWidth', 1, 'DisplayName', ['Newton Order ', num2str(order)]);
        
        Ych = f(chebyNodes);
        %Chebyshev
        cheby = chebyshev(order,a,b,Ych,theta);
        y_cheby = polyval(cheby,x_og);
        mse_chebyshev = [mse_chebyshev, mean((y_og - y_cheby).^2)];
        max_err_chebyshev = [max_err_chebyshev, max(abs(y_og - y_cheby))];
        plot(x_og, y_cheby, '--', 'LineWidth', 1, 'DisplayName', ['Chebyshev Order ', num2str(order)]);
        scatter(chebyNodes, Ych, 50, 'filled', 'DisplayName', ['Chebyshev Nodes Order ', num2str(order)]);
        
        %Pade
        [taylor_coef,pade_decimal,pade_rational, num, den] = padeapprox(f,x_og,order);
        y_pade = double(subs(pade_rational, x, x_og));
        mse_pade = [mse_pade, mean((y_og - y_pade).^2)];
        max_err_pade = [max_err_pade, max(abs(y_og - y_pade))];
        plot(x_og, y_pade, '-.', 'LineWidth', 1, 'DisplayName', ['Pade Order ', num2str(order)]);

        %Splines
        y_spline = spline (x_values,y,x_og);
        mse_spline = [mse_spline, mean((y_og - y_spline).^2)];
        max_err_spline = [max_err_spline, max(abs(y_og - y_spline))];
        plot(x_og, y_spline, 'LineWidth', 1, 'DisplayName', ['Spline Order ', num2str(order)]);
        
    end
    
    %MSE
    figure;
    hold on;
    grid on;
    title(['Mean Square Error ', num2str(i)]);
    xlabel('Approximation Order');
    ylabel('Mean Square Error');
    plot(orders, mse_lagrange, '-o', 'LineWidth', 1.5, 'DisplayName', 'Lagrange');
    plot(orders, mse_newton, '-s', 'LineWidth', 1.5, 'DisplayName', 'Newton');
    plot(orders, mse_chebyshev, '-x', 'LineWidth', 1.5, 'DisplayName', 'Chebyshev');
    plot(orders, mse_pade, '-d', 'LineWidth', 1.5, 'DisplayName', 'Pade');
    plot(orders, mse_spline, '-^', 'LineWidth', 1.5, 'DisplayName', 'Spline');    
    legend;
    hold off;

   % Plot Max Err
    figure;
    hold on;
    grid on;
    title(['Maximum Error', num2str(i)]);
    xlabel('Approximation Order');
    ylabel('Maximum Error');
    plot(orders, max_err_lagrange, '-o', 'LineWidth', 1.5, 'DisplayName', 'Lagrange');
    plot(orders, max_err_newton, '-s', 'LineWidth', 1.5, 'DisplayName', 'Newton');
    plot(orders, max_err_spline, '-^', 'LineWidth', 1.5, 'DisplayName', 'Spline');
    plot(orders, max_err_pade, '-d', 'LineWidth', 1.5, 'DisplayName', 'Pade');
    plot(orders, max_err_chebyshev, '-x', 'LineWidth', 1.5, 'DisplayName', 'Chebyshev');
    legend;
    hold off;

 % syms z;
 % f7 = (1 + z) / log(1 + z);
 % taylor_expansion = taylor(f7, z, 'ExpansionPoint', 3, 'Order', 10);
 % taylor_coeffs = sym2poly(taylor_expansion)
 % [num, den] = pade(taylor_coeffs, M, N);
 % pade_numeric = @(z) polyval(num, z) ./ polyval(den, z);
 % pade_vals = pade_numeric(x);

% p
disp("Lagranzo koeficientai");
lagrange
disp("Niutono koeficientai");
newton
disp("Čebysevo koeficientai");
cheby
disp("Tayloro koeficientai");
taylor_coef
disp("Pade racionalioji funkcija")
pade_decimal

%double(subs(pade_rational,x,x_values))
%Lagranzo daugianaris savo taske = 1 ; l1 = 1, l2 = 1 , l=n-1
function l=lagrangeapprox(x,y,N)
l = 0;
    for m = 1:N + 1
    P = 1;
        for k = 1:N + 1
            if k ~= m, P = conv(P,[1 -x(k)])/(x(m)-x(k)); end       
        end
    l = l + y(m)*P;     
    end
end

function newton = newtonapprox(x,y,N)
DD = zeros(N + 1,N + 1);
DD(1:N + 1,1) = y';
for k = 2:N + 1
    for m = 1: N + 2 - k %Divided Difference Table
        DD(m,k) = (DD(m + 1,k - 1) - DD(m,k - 1))/(x(m + k - 1)- x(m));
    end
end
a = DD(1,:); %Eq.(3.2.6)
newton = a(N+1); %Begin with Eq.(3.2.7)
for k = N:-1:1 %Eq.(3.2.7)
    newton = [newton a(k)] - [0 newton*x(k)]; %n(x)*(x - x(k - 1))+a_k - 1
end
end

function c = chebyshev(N,a,b,y,theta)
% (x,y) = Chebyshev nodes
%jeigu a & b neduoti, a,b = [-1;1]
if nargin == 2, a = -1; b = 1; end

d(1) = y*ones(N + 1,1)/(N+1); %pirmas Čebyševo koef. avg(y)
for m = 2: N + 1 %aukstesnes eiles koef
    cos_mth = cos((m-1)*theta); %cos(θx) daugianariai
    d(m) = y*cos_mth'*2/(N + 1); %Eq.(3.3.6b)
end
%daugianario konstravimas
xn = [2 -(a + b)]/(b - a); %the inverse of (3.3.1b)
T_0 = 1; T_1 = xn; %Eq.(3.3.3b) pirmieji du Čebysevo daugianariai
c = d(1)*[0 T_0] +d(2)*T_1; %Eq.(3.3.5)
%rekursiskai pridedami aukstesnes eiles daugianariai
for m = 3: N + 1
    tmp = T_1;
    T_1 = 2*conv(xn,T_1) -[0 0 T_0]; %Eq.(3.3.3a)
    T_0 = tmp;
    c = [0 c] + d(m)*T_1; %Eq.(3.3.5)
end
end

function [taylor_coef,pade_decimal,pade_rational, num, den] = padeapprox(f,range,order)
    if mod(order, 2) == 0
        M = order / 2; % M = N
        N = order / 2;
    else
        M = floor(order / 2); % M < N, lyg tai tiksliau su racionaliom funkcijom
        N = ceil(order / 2);
    end 

  expansionpoint=max((range)+min(range)) / 2;
  a(1) = feval(f,expansionpoint);
  h = .01; tmp = 1;
    for i = 1:M + N
        tmp = tmp*i*h; %i!h^i
        dix = difapx(i,[-i i])*feval(f,expansionpoint+[-i:i]*h)'; %derivative
        a(i + 1) = dix/tmp; %Taylor series coefficient
    end
    taylor_coef=a;

for m = 1:N
    n = 1:N; 
    A(m,n) = a(M + 1 + m - n);
    b(m) = -a(M + 1 + m);
end

d = A\b'; %Eq.(3.4.4b)
for m = 1: M + 1
    mm = min(m - 1,N);
    q(m) = a(m:-1:m - mm)*[1; d(1:mm)]; %Eq.(3.4.4a)
end
num = q(M + 1:-1:1)/d(N); den = [d(N:-1:1)' 1]/d(N);
syms x;

pade_rational = poly2sym(num, x) / poly2sym(den, x);
pade_decimal = vpa(pade_rational, 5) ;


end








%aproksimuoja isvestines??
%daznu atveju funkcija nera zinoma, todel isvestines apskaiciuojamas
%skaitine reiksme (computed numerically)
%aukstesnio laipsnio isvestines apskaiciuoti sudetina ir kainuoja daug
%resursu. sprendimas - skaitinis diferencijavimas

function [c,err,eoh,A,b] = difapx(N,points)
%difapx.m to get the difference approximation for the Nth derivative
l = max(points);
L = abs(points(1)-points(2))+ 1;
if L < N + 1, error('More points are needed!'); end
for n = 1: L
A(1,n) = 1;
for m = 2:L + 2, A(m,n) = A(m - 1,n)*l/(m - 1); end %Eq.(5.3.5)
l = l-1;
end
b = zeros(L,1); b(N + 1) = 1;
c =(A(1:L,:)\b)'; %coefficients of difference approximation formula
err = A(L + 1,:)*c'; eoh = L-N; %coefficient & order of error term
if abs(err) < eps, err = A(L + 2,:)*c'; eoh = L - N + 1; end
if points(1) < points(2), c = fliplr(c); end
end