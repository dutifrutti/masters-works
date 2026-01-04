% 1
function1 = @(x) x.^3 - 2*x; 
x0_1 = 1;            
f1_1 = 1.0; 
f1_2 = 6.0; 

%  2
function2 = @(x) sin(x);    
x0_2 = pi/3;         
f2_1 = 0.5; 
f2_2 = -0.8660254037; 

% 3
function3 = @(x) exp(x);    
x0_3 = 0;            
f3_1 = 1.0; 
f3_2 = 1.0; 

functions = {function1, function2, function3};
x0_s       = [x0_1, x0_2, x0_3];
dfdx1s      = [f1_1, f2_1, f3_1];
dfdx2s      = [f1_2, f2_2, f3_2];
i=1;
y = functions{i};
x01 = x0_s(i);
dfdx1 = dfdx1s(i);
dfdx2 = dfdx2s(i);

hs = [0.1, 0.01];
%% 1
% Skaitiniu isvestiniu paklaidos

for i = 1:length(hs)
    h = hs(i);

    f0 = y(x01)                    % f x0
    f1 = y(x01 + h);                % f x0 + h
    f_1 = y(x01 - h);               % f x0 - h
    f2 = y(x01 + 2*h);              % f x0 + 2h
    f_2 = y(x01 - 2*h);             % f x0 - 2h
    
    % pirmos isvestines aproksimacija
    f1_order2 = (f1 - f_1) / (2*h);  % antro laipsnio central difference
    f1_order4 = (-f2 + 8*f1 - 8*f_1 + f_2) / (12*h); % ketvirto

    %antros isvestines aproksimacija
    f2_order2 = (f1 - 2*f0 + f_1) / (h^2); 
    f2_order4 = (-f2 + 16*f1 - 30*f0 + 16*f_1 - f_2) / (12*h^2); 

    % paklaidos 1
    errors_first_derivative(i, 1) = abs(f1_order2 - dfdx1);
    errors_first_derivative(i, 2) = abs(f1_order4 - dfdx1);

    % paklaidos 2
    errors_second_derivative(i, 1) = abs(f2_order2 - dfdx2);
    errors_second_derivative(i, 2) = abs(f2_order4 - dfdx2);
end
disp('Pirmos isvestines paklaidos:');
disp(array2table(errors_first_derivative, 'VariableNames', {'Order2', 'Order4'}, 'RowNames', {'h=0.1', 'h=0.01'}));

disp('Antros isvestines paklaidos:');
disp(array2table(errors_second_derivative, 'VariableNames', {'Order2', 'Order4'}, 'RowNames', {'h=0.1', 'h=0.01'}));

%% 2
% 1
x = [0.8, 0.9, 1.0, 1.1, 1.2];      
y = [-1.0880, -1.0710, -1.0000, -0.8690, -0.6720];
h1 = x(2) - x(1);

dfdx11 = ( y(3+1) - y(3-1) ) / (2*h1);

dfdx12 = ( -y(3+2) + 8*y(3+1) - 8*y(3-1) + y(3-2) ) / (12*h1);

dfdx21 = ( y(3 + 1) - 2 * y(3) + y(3 - 1) ) / (h1^2);
dfdx22 = (-y(3 + 2) + 16*y(3 + 1) - 30*y(3) + 16*y(3 - 1) - y(3 - 2)) / (12 * h1^2);

disp(['Pirma isvestine O2: ', num2str(dfdx11)]);
disp(['Pirma isvestine O4: ', num2str(dfdx12)]);
disp(['Antra isvestine O2: ', num2str(dfdx21)]);
disp(['Antra isvestine O4: ', num2str(dfdx22)]);
% x^3 - 2x
l = run_lagranp(x,y);

x01= x(3);
    f0 = polyval(l,x01);                  % f x0
    f1 = polyval(l,(x01 + h1));                % f x0 + h
    f_1 = polyval(l,(x01 - h1));               % f x0 - h
    f2 = polyval(l,(x01 + 2*h1));              % f x0 + 2h
    f_2 = polyval(l,(x01 - 2*h1));             % f x0 - 2h
    
    % pirmos isvestines aproksimacija
    f1_order2 = (f1 - f_1) / (2*h1);  % antro laipsnio central difference
    f1_order4 = (-f2 + 8*f1 - 8*f_1 + f_2) / (12*h1); % ketvirto

    %antros isvestines aproksimacija
    f2_order2 = (f1 - 2*f0 + f_1) / (h1^2); 
    f2_order4 = (-f2 + 16*f1 - 30*f0 + 16*f_1 - f_2) / (12*h1^2); 
disp(['Pirma isvestine L2: ', num2str(f1_order2)]);
disp(['Pirma isvestine L4: ', num2str(f1_order4)]);
disp(['Antra isvestine L2: ', num2str(f2_order2)]);
disp(['Antra isvestine L4: ', num2str(f2_order4)]);
