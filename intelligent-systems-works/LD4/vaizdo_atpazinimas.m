close all
clear all
clc
%% raidþiø pavyzdþiø nuskaitymas ir poþymiø skaièiavimas
%% read the image with hand-written characters
pavadinimas = 'train_numbers.png';
pozymiai_tinklo_mokymui = pozymiai_raidems_atpazinti(pavadinimas, 5);
%% Atpaþintuvo kûrimas
%% Development of character recognizer
% poþymiai ið celiø masyvo perkeliami á matricà
% take the features from cell-type variable and save into a matrix-type variable
P = cell2mat(pozymiai_tinklo_mokymui);
% sukuriama teisingø atsakymø matrica: 11 raidþiø, 8 eilutës mokymui
% create the matrices of correct answers for each line (number of matrices = number of symbol lines)
T = [eye(10), eye(10), eye(10), eye(10), eye(10)];
% sukuriamas SBF tinklas duotiems P ir T sàryðiams
% create an RBF network for classification with 13 neurons, and sigma = 1
tinklas = newrb(P,T,1e-3,1,30);

%% Tinklo patikra | Test of the network (recognizer)
% skaièiuojamas tinklo iðëjimas neþinomiems poþymiams
% estimate output of the network for unknown symbols (row, that were not used during training)


P2 = P(:,11:20);
Y2 = sim(tinklas, P2);
% ieðkoma, kuriame iðëjime gauta didþiausia reikðmë
% find which neural network output gives maximum value
[a2, b2] = max(Y2);
%% Rezultato atvaizdavimas
%% Visualize result
% apskaièiuosime raidþiø skaièiø - poþymiø P2 stulpeliø skaièiø
% calculate the total number of symbols in the row
skaitmenu_kiekis = size(P2,2);
% rezultatà saugosime kintamajame 'atsakymas'
% we will save the result in variable 'atsakymas'
atsakymas = [];
for k = 1:skaitmenu_kiekis
    switch b2(k)
        case 1
            % the symbol here should be the same as written first symbol in your image
            atsakymas = [atsakymas, '1'];
        case 2
            atsakymas = [atsakymas, '2'];
        case 3
            atsakymas = [atsakymas, '3'];
        case 4
            atsakymas = [atsakymas, '4'];
        case 5
            atsakymas = [atsakymas, '5'];
        case 6
            atsakymas = [atsakymas, '6'];
        case 7
            atsakymas = [atsakymas, '7'];
        case 8
            atsakymas = [atsakymas, '8'];
        case 9
            atsakymas = [atsakymas, '9'];
        case 10
            atsakymas = [atsakymas, '0'];
    end
end
% pateikime rezultatà komandiniame lange
% show the result in command window
disp(atsakymas)
% % figure(7), text(0.1,0.5,atsakymas,'FontSize',38)
%% þodþio "KADA" poþymiø iðskyrimas 
%% Extract features of the test image
pavadinimas = 'test_314.png';
pozymiai_patikrai = pozymiai_raidems_atpazinti(pavadinimas, 1);

%% Raidþiø atpaþinimas
%% Perform letter/symbol recognition
% poþymiai ið celiø masyvo perkeliami á matricà
% features from cell-variable are stored to matrix-variable
P2_314 = cell2mat(pozymiai_patikrai);
% skaièiuojamas tinklo iðëjimas neþinomiems poþymiams
% estimating neuran network output for newly estimated features
Y2 = sim(tinklas, P2_314);
% ieðkoma, kuriame iðëjime gauta didþiausia reikðmë
% searching which output gives maximum value
[a2, b2] = max(Y2);
%% Rezultato atvaizdavimas | Visualization of result
% apskaièiuosime raidþiø skaièiø - poþymiø P2 stulpeliø skaièiø
% calculating number of symbols - number of columns
skaitmenu_kiekis_314 = size(P2_314,2);
% rezultatà saugosime kintamajame 'atsakymas'
atsakymas = [];
for k = 1:skaitmenu_kiekis_314
    switch b2(k)
        case 1
            % the symbol here should be the same as written first symbol in your image
            atsakymas = [atsakymas, '1'];
        case 2
            atsakymas = [atsakymas, '2'];
        case 3
            atsakymas = [atsakymas, '3'];
        case 4
            atsakymas = [atsakymas, '4'];
        case 5
            atsakymas = [atsakymas, '5'];
        case 6
            atsakymas = [atsakymas, '6'];
        case 7
            atsakymas = [atsakymas, '7'];
        case 8
            atsakymas = [atsakymas, '8'];
        case 9
            atsakymas = [atsakymas, '9'];
        case 10
            atsakymas = [atsakymas, '0'];
    end
end
% pateikime rezultatà komandiniame lange
disp(atsakymas)
figure(8), text(0.1,0.5,atsakymas,'FontSize',38), axis off
%% þodþio "FIKCIJA" poþymiø iðskyrimas 
%% extract features for next/another test image
pavadinimas = 'test_420.png';
pozymiai_patikrai = pozymiai_raidems_atpazinti(pavadinimas, 1);

%% Raidþiø atpaþinimas
% poþymiai ið celiø masyvo perkeliami á matricà
P2_420 = cell2mat(pozymiai_patikrai);
% skaièiuojamas tinklo iðëjimas neþinomiems poþymiams
Y2 = sim(tinklas, P2_420);
% ieðkoma, kuriame iðëjime gauta didþiausia reikðmë
[a2, b2] = max(Y2);
%% Rezultato atvaizdavimas
% apskaièiuosime raidþiø skaièiø - poþymiø P2 stulpeliø skaièiø
skaitmenu_kiekis_420 = size(P2_420,2);
% rezultatà saugosime kintamajame 'atsakymas'
atsakymas = [];
for k = 1:skaitmenu_kiekis_420
    switch b2(k)
        case 1
            % the symbol here should be the same as written first symbol in your image
            atsakymas = [atsakymas, '1'];
        case 2
            atsakymas = [atsakymas, '2'];
        case 3
            atsakymas = [atsakymas, '3'];
        case 4
            atsakymas = [atsakymas, '4'];
        case 5
            atsakymas = [atsakymas, '5'];
        case 6
            atsakymas = [atsakymas, '6'];
        case 7
            atsakymas = [atsakymas, '7'];
        case 8
            atsakymas = [atsakymas, '8'];
        case 9
            atsakymas = [atsakymas, '9'];
        case 10
            atsakymas = [atsakymas, '0'];
    end
end
% pateikime rezultatà komandiniame lange
 disp(atsakymas)
figure(9), text(0.1,0.5,atsakymas,'FontSize',38), axis off

mlpRows = reshape(1:50, 10, 5);
mlpTestRow = mlpRows(:,3);
mlpTrainRow = setdiff(1:50, mlpTestRow);
Ptrain = P(:,mlpTrainRow);
Ttrain = T(:, mlpTrainRow);

mlp = feedforwardnet([20 15] );
mlp = train(mlp, P, T);
P2 = P(:, 11:20);                 
Y2 = mlp(P2); 
[a2, b2] = max(Y2);

digitsMap = '1234567890';
atsakymas = digitsMap(b2);

disp('MLP:');
disp(atsakymas);
% figure(101), text(0.1,0.5,atsakymas,'FontSize',38), axis off

Y2 = mlp(P2_314);
[a2, b2] = max(Y2);

atsakymas = digitsMap(b2);
disp('MLP preduction 314:');
disp(atsakymas);

Y2 = mlp(P2_420);
[a2, b2] = max(Y2);

atsakymas = digitsMap(b2);
disp('MLP preduction 420:');
disp(atsakymas);