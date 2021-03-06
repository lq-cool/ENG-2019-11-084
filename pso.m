function output = pso(input)
%PSO is a parallel implementation of the Particle Swarm Optimization algorithm.
%
% Author : Iannick Gagnon (iannick.gagnon.1@ens.etsmtl.ca)
%
% Date   : November 27th 2019

%% Input checks

% CHECK input field names
expected_fieldnames = {'fun';                 ...
                       'nb_dim';              ...
                       'initial_positions';   ...
                       'lower_bound';         ...
                       'upper_bound';         ...
                       'w';                   ...
                       'c1';                  ...
                       'c2';                  ...
                       'nb_particles';        ...
                       'max_iter';            ...
                       'known_best_fitness';  ...
                       'tol';                 ...
                       'positions_hist_flag'};
                  
% Make sure that the INPUT variable contains all of the required parameters
input_fieldnames = fieldnames(input);
assert(all(strcmpi(expected_fieldnames, input_fieldnames)), 'ERROR: Missing input(s)');

% Transform structure fields-values into workspace variables
for i = 1 : numel(expected_fieldnames)
    evalc([input_fieldnames{i} ' = input.' input_fieldnames{i}]);
end

% Make sure the objective function is a function_handle object
assert(isa(fun, 'function_handle'), 'ERROR: Objective function must be of function_handle type')

% Make sure the number of dimensions is greater than zero
assert(nb_dim > 0, 'ERROR: Objective function dimensions must be > 0');

% Make sure the lower bound is less than the upper bound
assert(lower_bound < upper_bound, 'ERROR: The lower bound cannot be greater than the upper bound')

%% Initialization

% Assign initial positions (1) randomly or (2) equal to input values
if isempty(initial_positions)
    
    % Assign random uniform initial positions
    positions = lower_bound * ones(nb_particles, nb_dim) + rand(nb_particles, nb_dim) * (upper_bound-lower_bound);

else
   
    l = initial_positions(1);
    g = [initial_positions(2), initial_positions(3)];
    
    positions = lower_bound * ones(nb_particles, nb_dim) + rand(nb_particles, nb_dim) * (upper_bound-lower_bound);
    
    for i = 1 : nb_dim
        
        min1 = g(i) - l;
        max1 = g(i) + l;
        
        min2 = g(2) - l;
        max2 = g(2) + l;
        
        bad_idx = find((~(double(positions(:,1) < min1) + double(positions(:,1) > max1)) + ~(double(positions(:,2) < min2) + double(positions(:,2) > max2)))==2);
        nb_bad = numel(bad_idx);
        
        while ~isempty(bad_idx)
            
            positions(bad_idx, :) = lower_bound * ones(nb_bad, 2) + rand(nb_bad, 2) * (upper_bound-lower_bound);
            bad_idx = find((~(double(positions(:,1) < min1) + double(positions(:,1) > max1)) + ~(double(positions(:,2) < min2) + double(positions(:,2) > max2)))==2);
            nb_bad = numel(bad_idx);
            
        end
    end
end

%% Initialization

% Initial best position
personal_best_positions = positions;

% Initial fitness value
fitnesses = fun(positions);

% Initial number of objective function evaluations
nb_fun_eval = nb_particles;

% Initial personal best fitness values
personal_best_fitnesses = fitnesses;

% Initial global best fitness value
[global_best_fitness, best_index] = min(fitnesses);

% Initial global best positions
global_best_position = positions(best_index, :);

% Initial first hitting time
first_hitting_time = nan;

% Initialize velocities
velocities = zeros(nb_particles, 2);

% Initialize number of epochs
nb_epochs = 0;

%% Main loop

for iteration = 1 : max_iter
   
    % Increment number of epochs
    nb_epochs = nb_epochs + 1;
    
    % Velocity
    velocities = w * velocities + c1 * rand() * (personal_best_positions - positions) + c2 * rand() * (repmat(global_best_position, nb_particles, 1) - positions);
    
    % Update position
    positions =  positions + velocities;

    % Random reinitialization
    [rlb, clb] = find(positions < lower_bound);
    [rub, cub] = find(positions > upper_bound);
    r = [rlb; rub];
    c = [clb; cub];
    if ~isempty(r)
        nb_out_of_bounds = numel(r);
        for i = 1 : nb_out_of_bounds
            positions(r(i),c(i)) = lower_bound + rand() * (upper_bound-lower_bound);
        end
    end
   
    % Update positions history
    if positions_hist_flag
        positions_history{end + 1} = positions; %#ok
    end
    
    % New fitnesses
    fitnesses = fun(positions);
    [new_best, best_index] = min(fitnesses); 
    
    % Increment number of objetive function evaluations
    nb_fun_eval = nb_fun_eval + nb_particles;
   
    % Update global best
    if new_best < global_best_fitness
       global_best_fitness = new_best;
       global_best_position = positions(best_index,:);
    end
   
    % Update personal best
    personal_best_fitnesses(fitnesses < personal_best_fitnesses) = fitnesses(fitnesses < personal_best_fitnesses);
   
    % Check for convergence
    if abs(global_best_fitness - known_best_fitness) < tol
        first_hitting_time = nb_fun_eval;
        break
    end
 
end

%% Output

output.first_hitting_time = first_hitting_time;
output.positions_history = positions_history;

end
