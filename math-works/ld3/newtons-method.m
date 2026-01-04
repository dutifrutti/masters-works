clc;
%1 
    U = [ 0.00; 0.02; 0.04; 0.06; 0.08; 0.10; 0.12; 0.14];
    I = [ 1e-8; 1e-7; 2e-6; 1e-5; 2e-5; 1e-4; 2e-4; 5e-4]; 
%niutono-gauso
function f = diode(x,U,I)

    k = 1.38e-23;       
    e = 1.602e-19;

    I0 = x(1);
    T  = x(2);    
    % lygciu sistema f(I0,T)=0 su U(i) ir I(i) apimant visus taskus per
    % least squares ideja
    f = I - I0.*(exp(e.*U./(k.*T)) - 1); 
end
% Initial guess:
x0 = [1e-6, 300];
x = newtongauss(diode(x0,U,I),x0,U,I);
I0_ng = x(1);
T_ng = x(2)-273;

%Solve the system using fsolve:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%su defaultinem tolerancijom 27C 2Ae-6, arba su default tolerancijom bet
%pradiniu 263
options = optimset('TolFun',1e-12,'Display','iter');  % optional: shows iteration output
options.TolX = 1e-12;
[x_sol, fval] = fsolve(@(x) diode(x,U,I), x0, options);


% Extract best-fit parameters:
I0_est_fsolve = x_sol(1);
T_est_fsolve  = x_sol(2)-273;

fprintf('Newton-Gauss I0 = %.4g A\n', I0_ng);
fprintf('Newton-Gauss  T = %.4f C\n', T_ng);
fprintf('fsolve I0 = %.4g A\n', I0_est_fsolve);
fprintf('fsolve T  = %.4f C\n', T_est_fsolve);
% 
%  I_fit = I0_est_fsolve.*(exp((1.602e-19).*U./(1.38e-23.*T_est_fsolve)) - 1);
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure; hold on;
% plot(U, I, 'o', 'DisplayName','Data (solid line points)');
% plot(U, I_fit, '-r', 'DisplayName','Fitted curve');
% xlabel('Voltage U (V)');
% ylabel('Current I (A)');
% legend;
% grid on;

I_fit_ng = I0_ng .* (exp((e .* U) ./ (k .* (T_ng + 273))) - 1);
figure; 
plot(U, I, 'o');
plot(U, I_fit_ng, '-r', 'DisplayName', 'Newton Gaus'); % Newton-Gauss


function [x,fx,xx] = newtongauss(f,x0,U,I)

    k = 1.38e-23;       
    e = 1.602e-19;
   TolFun = eps; TolX = 1e-12; maxIter = 30;

    n = length(U);

    %fx = feval(f,x0);
    fx=f;
    fx0 = norm(fx);%tikrina kaip spejimas yra arti sprendimo, mazina divergacija keiciant y dydi
    xx(1,:) = x0(:).'; 
    for iter = 1:maxIter        
        % Current parameter values:
        I0 = x0(1);
        T  = x0(2);       
        % r = (I - I model)
        r = diode(x0,U,I);       
        %JACOBIAN J (size n×2) 
        J = zeros(n,2);
        for j = 1:n
            expTerm   = exp((U(j)*e)/(k*T));
            % dr/dI0 = - [exp(Ue/(kT)) - 1]
            J(j,1) = -( expTerm - 1 );          
            % dr/dT = derivative of -I0*(expTerm - 1) wrt T:
            %        => + I0 * expTerm * (U_data(j)*e/(k*T^2))
            J(j,2) = I0 * expTerm * ( (U(j)*e)/(k*T^2) );
        end
        %PARAMETER UPDATE
        % Solve normal equations: (J^T * J) * dp = - J^T * r
        %  J^T * J      *  delta  =  - J^T * f
        % (2xN)*(Nx2) = 2x2   *    (2x1)  =   (2xN)*(Nx1) = 2x1
        JT = J';
        dx = (JT*J)\(-JT*r);

    for l = 1: 3 %damping to avoid divergence %(2)
        dx = dx/2; %(3)
        xx(iter + 1,:) = xx(iter,:) + dx.';
        fx = diode(xx(iter+1,:),U,I);
        x0 = xx(iter+1,:);
        fxn = norm(fx);
        if fxn < fx0, break; end 
    end 
    if fxn < TolFun | norm(dx) < TolX, break; end
    fx0 = fxn;          
    end

x = xx(iter + 1,:);
if iter == maxIter, fprintf('The best in %d iterations\n',maxIter), end
end

function [x,fx,xx] = newtons(f,x0,TolX,MaxIter,varargin)
%newtons.m to solve a set of nonlinear eqs f1(x)=0, f2(x)=0,..
%input: f = 1^st-order vector ftn equivalent to a set of equations
% x0 = the initial guess of the solution
% TolX = the upper limit of |x(k) - x(k - 1)| % MaxIter = the maximum # of iteration
%output: x = the point which the algorithm has reached
% fx = f(x(last))
% xx = the history of x
h = 1e-4; TolFun = eps; EPS = 1e-6;
fx = feval(f,x0,varargin{:})
Nf = length(fx);
Nx = length(x0);
if Nf ~= Nx, error('Incompatible dimensions of f and x0!'); end
if nargin < 4, MaxIter = 100; end
if nargin < 3, TolX = EPS; end
xx(1,:) = x0(:).'; %Initialize the solution as the initial row vector
fx0 = norm(fx); %(1)
for k = 1: MaxIter
    dx = -jacob(f,xx(k,:),h,varargin{:})\fx(:);%/;%-[dfdx]?-1*fx
    %It represents the amount by which the current estimate (xx(k,:)) will be adjusted.
    %The function value (or residual) at the current estimate xx(k,:).
%fx is typically a vector, and fx(:) reshapes it into a column vector (important for consistent dimensions in the linear solve).
%h: A small step size or perturbation used for finite difference approximation of the Jacobian
    for l = 1: 3 %damping to avoid divergence %(2)
        dx = dx/2; %(3)
        xx(k + 1,:) = xx(k,:) + dx.';
        fx = feval(f,xx(k + 1,:),varargin{:}); fxn = norm(fx);
        if fxn < fx0, break; end %(4)
    end %(5)
    if fxn < TolFun | norm(dx) < TolX, break; end
    fx0 = fxn; %(6)
end
x = xx(k + 1,:);
if k == MaxIter, fprintf('The best in %d iterations\n',MaxIter), end
end

function g = jacob(f,x,h,varargin) %Jacobian of f(x)
if nargin < 3, h = 1e-4; end
h2 = 2*h; N = length(x); x = x(:).'; I = eye(N);
for n = 1:N
    g(:,n) = (feval(f,x + I(n,:)*h,varargin{:}) ...
    -feval(f,x - I(n,:)*h,varargin{:}))'/h2;
end

end



%http://www.ohiouniversityfaculty.com/youngt/IntNumMeth/lecture13.pdf