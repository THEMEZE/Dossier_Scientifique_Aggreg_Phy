# Package

#=
Traduction Julia du script Python échantillonnant les configurations de Bethe dans un GGE
=#
import Pkg; Pkg.add("StatsBase")
import Pkg; Pkg.add("Plots")
import Pkg; Pkg.add("LaTeXStrings")
import Pkg; Pkg.add("NLsolve")

using LinearAlgebra
using Random
using Printf
using StatsBase
using Plots
using LaTeXStrings
using NLsolve
using NLsolve, StatsBase

# Fonctions

## Générals
### Affiche une barre d'acceptation de Metropolis
function print_acceptance_bar(accepted::Int, nsteps::Int; bar_length::Int = 30)
    percentage = nsteps == 0 ? 0.0 : accepted / nsteps * 100
    filled_length = Int(floor(bar_length * percentage / 100))
    bar = repeat("\u2588", filled_length) * repeat("-", bar_length - filled_length)
    print("\r🛠 : [", bar, "] ", @sprintf("%.1f", percentage), "% ($accepted/$nsteps)")
    flush(stdout)
end

## Corrélation Montés Carlos

### === PARAMÈTRES DU PROBLÈME ===
const N = 7
const L = 10.0
const c = 1.0
const nbins = 10
const nsteps = 1_000
beta = 1.e0

### Discrétisation de l'axe des rapidités
const theta_bins = range(-5, stop=5, length=nbins + 1)
theta_centers = [(theta_bins[i] + theta_bins[i+1])/2 for i in 1:nbins]
const dtheta = theta_centers[2] - theta_centers[1]

### Potentiel spectral (ex : quadratique)
w_original(θ) = beta*0.5 * θ^2

### === RÉSOLUTION DES ÉQUATIONS DE BETHE ===
function solve_bethe(I::Vector{Int}, guess::Vector{Float64})
    function fun!(F, lmb)
        diff_matrix = (lmb .- transpose(lmb)) ./ c
        kernel = @. 2 * atan(diff_matrix)
        interaction = vec(sum(kernel, dims=2))  # <-- correction ici
        F .= L .* lmb .+ interaction .- 2π .* I
    end
    result = nlsolve(fun!, guess)
    return sort(result.zero)
end

function initial_I(N)
    if isodd(N)
        return collect(-(N - 1) ÷ 2 : (N - 1) ÷ 2)
    else
        return collect(-N ÷ 2 + 1 : N ÷ 2)
    end
end

### === SAMPLING DE CONFIGURATIONS PAR MÉTHODE DE METROPOLIS ===
function run_monte_carlo_and_return_mean_density(N::Int, nsteps::Int, w::Function)
    I = initial_I(N)
    guess = collect(LinRange(-N/2, N/2, N))
    lambda_cur = solve_bethe(I, guess)
    energy_cur = sum(w.(lambda_cur))
    samples_hist = []
    guess = copy(lambda_cur)

    accepted = 0
    while accepted < nsteps

        #liste_idx = randperm(N)[1:rand(1:N)]
        liste_idx = randperm(N)[1:N]
        
        #idx = rand(1:N)
        I_prop = copy(I)
        for idx in liste_idx
            I_prop[idx] += rand([-1, 1])
        end
           
        sort!(I_prop)
        if length(unique(I_prop)) < N
            continue
        end

        try
            lambda_prop = solve_bethe(I_prop, guess)
            energy_prop = sum(w.(lambda_prop))
            if rand() < min(1 , exp(-(energy_prop - energy_cur)))
                I = copy(I_prop)
                lambda_cur = copy(lambda_prop)
                energy_cur = energy_prop
            end
            guess = copy(lambda_prop)
        catch
            continue
        end

        accepted += 1

        # Histogramme de ρ(θ)
        hist = fit(Histogram, lambda_cur, theta_bins)
        push!(samples_hist, hist.weights / (L * dtheta))

        #print_acceptance_bar(accepted, nsteps)
    end

    # === POST-TRAITEMENT ===
    samples_hist = reduce(vcat, [permutedims(h) for h in samples_hist])
    mean_rho = vec(mean(samples_hist, dims=1))
    delta_rho = samples_hist .- mean_rho'
    chi_matrix = cov(delta_rho, dims=1)

    return samples_hist, mean_rho, delta_rho, chi_matrix
end

##  Suceptibilité

### Fonction perturbation w

function w_perturbed_factory(theta_centers, theta_prime_idx,  w_original  , eps)
    theta_prime = theta_centers[theta_prime_idx]
    width = theta_centers[2] - theta_centers[1]
    delta_window = width / 2

    function w_func(lamb)
        correction = eps .* (abs.(lamb .- theta_prime) .< delta_window)
        return w_original.(lamb) .+ correction
    end

    return w_func
end

## fonction Final
function run_chi_from_derivative(N, nsteps, w_original , eps )
    chi_from_derivative = []
    #w = w_original
    
    _, mean_rho_0, _, chi_matrix_0 = run_monte_carlo_and_return_mean_density(N, Int(nsteps),  w_original)
    for j in 1:nbins
        #w = make_w_with_perturbation(theta_centers, eps, j)
        #_, mean_rho_eps_m, _, _ = run_monte_carlo_and_return_mean_density(N, nsteps, w_perturbed_factory(theta_centers, j, w_original  , -eps))
        _, mean_rho_eps, _, _ = run_monte_carlo_and_return_mean_density(N, nsteps, w_perturbed_factory(theta_centers, j, w_original  , eps))
        chi_col_j = - (mean_rho_eps .- mean_rho_0) ./ eps ./ L
        #chi_col_j = - (mean_rho_eps .- mean_rho_eps_m) ./ (2*eps) ./ L
        #chi_col_j = - (mean_rho_eps .- mean_rho_0) ./ (w.(theta_centers[j])- w_original.(theta_centers[j])) ./ L
        push!(chi_from_derivative, chi_col_j)
        print_acceptance_bar(j, nbins)
    end
    chi_from_derivative = reduce(hcat, chi_from_derivative)
    return [chi_matrix_0,chi_from_derivative]
end

### le bon Epslilon ?

function plot_norm_chi_vs_eps(N, nsteps, w_original, eps_list)
    norms = Float64[]

    for eps in eps_list
        chi = run_chi_from_derivative(N, nsteps, w_original, eps)
        residual = (chi_matrix_0 .- chi)./chi_matrix_0
        valid_mask = .!isnan.(residual) .& .!isinf.(residual)
        norm_chi = norm(residual[valid_mask])  # norme Frobenius
        push!(norms, norm_chi)
        println("ε = $eps → ||χ-χ0/χ0|| = $norm_chi")
    end

    plot(eps_list, norms,
        xlabel = L"\epsilon",
        ylabel = L"\left\| \frac{\delta \langle \rho \rangle}{\delta w} \right\|",
        xscale = :log10,
        yscale = :log10,
        marker = :circle,
        label = "",
        title = "Norme de la réponse linéaire vs ε"
    )
end

chi_from_derivative = run_chi_from_derivative(N, nsteps, w_original, 1.0e-2)
# Affichage de chi(\theta,\theta')
p1 = heatmap(theta_centers, theta_centers, chi_matrix_0, xlabel=L"\theta'", ylabel=L"\theta", title=L"\chi(\theta,\theta')", colorbar=true, aspect_ratio=1)
# Comparaison des deux chi
p2 = heatmap(theta_centers, theta_centers, chi_from_derivative, xlabel=L"\theta'", ylabel=L"\theta", title=L"\chi(\theta,\theta') (fonctionnelle)", colorbar=true, aspect_ratio=1)
# Comparaison des deux chi
p3 = heatmap(theta_centers, theta_centers, (chi_matrix_0 .+ 1.0e-10)./(chi_from_derivative .+ 1.0e-10), xlabel=L"\theta'", ylabel=L"\theta", title=L"\chi(\theta,\theta') (fonctionnelle)", colorbar=true, aspect_ratio=1)

# Créer la figure composée
plt = plot(p1, p2, p3, layout=(1, 3), size=(1800, 600))
