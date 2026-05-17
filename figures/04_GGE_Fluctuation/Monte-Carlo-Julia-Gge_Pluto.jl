### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ b30a0b15-f456-4e84-b13e-fa2bf3ba249f
#📦 Bloc 0 — Import des package
begin
	import Pkg; Pkg.add("StatsBase")
	import Pkg; Pkg.add("Plots")
	import Pkg; Pkg.add("LaTeXStrings")
	import Pkg; Pkg.add("NLsolve")
	import Pkg; Pkg.add("PlutoUI")
end

# ╔═╡ 299102b0-6cca-11f0-1c56-e5b218c87129
#📦 Bloc 1 — Import des packages
begin
	using LinearAlgebra, Random, Printf, StatsBase, Plots, LaTeXStrings, NLsolve, PlutoUI
end

# ╔═╡ 8181996d-0d70-4a9f-a257-7d5db95ee8d8
#🔧 Bloc 2 — Paramètres interactifs
begin
	@bind N Slider(2:2:20, default=7, show_value=true)
end 

# ╔═╡ 550e8b3a-f272-45ff-b8bb-462456fe414f
begin
	@bind L Slider(5.0:0.5:20.0, default=10.0, show_value=true)
end 

# ╔═╡ 3feb4f31-e3cc-4464-a397-de958f6eaa6e
begin
	@bind c Slider(1:1:10, default=1, show_value=true)
end 

# ╔═╡ 03837246-1c66-4125-b860-4928d25cc545
begin
	@bind β Slider(0.1:0.1:5.0, default=1.0, show_value=true)
end 

# ╔═╡ 5f09a11a-7bae-4830-bf85-7ab9ca088f4b
begin
	@bind nsteps Slider(1_000:1_000:10_000_000, default=10_000_000, show_value=true)
end 

# ╔═╡ 784c1707-049c-4d30-9f5d-5dd4634b1605
begin
	@bind eps Slider(1e-4:1e-4:1e-1, default=1e-2, show_value=true)
end 

# ╔═╡ 764682b6-f979-4deb-8d4a-cd74fc4f424d
begin
	@bind nbins Slider(1e1:1e0:5e2, default=1e2, show_value=true)
end

# ╔═╡ 03b27b2a-bd58-4190-aa89-a5a775c0a27d
#📈 Bloc 3 — Discrétisation
begin
	theta_bins = range(-5, stop=5, length=Int(nbins) + 1)
	theta_centers = [(theta_bins[i] + theta_bins[i+1])/2 for i in 1:Int(nbins)]
	dtheta = theta_centers[2] - theta_centers[1]
end

# ╔═╡ 6a187dbc-7242-4f24-b429-65febb474ee6
#💡 Bloc 4 — Potentiel spectral
w_original(θ) = β * 0.5 * θ^2

# ╔═╡ bb4b1abf-da0a-4fa3-b55a-3bffc4c72125
#🔁 Bloc 5 — Fonctions utilitaires
### Affiche une barre d'acceptation de Metropolis
function print_acceptance_bar(accepted::Int, nsteps::Int; bar_length::Int = 30)
    percentage = nsteps == 0 ? 0.0 : accepted / nsteps * 100
    filled_length = Int(floor(bar_length * percentage / 100))
    bar = repeat("\u2588", filled_length) * repeat("-", bar_length - filled_length)
    print("\r🛠 : [", bar, "] ", @sprintf("%.1f", percentage), "% ($accepted/$nsteps)")
    flush(stdout)
end

# ╔═╡ 9e64ec61-7fbd-4284-a070-2704a990c9d2
### === RÉSOLUTION DES ÉQUATIONS DE BETHE ===
function solve_bethe(I::Vector{Int}, guess::Vector{Float64})
    function fun!(F, lmb)
        diff_matrix = (lmb .- transpose(lmb)) ./ c
        kernel = @. 2 * atan(diff_matrix)
        interaction = vec(sum(kernel, dims=2))  # <-- correction ici
        F .= L .* lmb .+ interaction .- 2π .* I
    end
    result = nlsolve(fun!, guess)
    #return sort(result.zero)
	result.zero |> sort
end

# ╔═╡ 5fbbe838-d172-42d4-8723-a0fc9ddb0813
function initial_I(N)
    if isodd(N)
        return collect(-(N - 1) ÷ 2 : (N - 1) ÷ 2)
    else
        return collect(-N ÷ 2 + 1 : N ÷ 2)
    end
end

# ╔═╡ 43f22688-8d59-4f65-84d8-f97a463d42a5
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

# ╔═╡ 265738ba-0cec-4c93-8701-fd2157b20add
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

# ╔═╡ 7cd1f176-d81f-4f7d-9730-74d489d24ad7
## fonction Final
function run_chi_from_derivative(N, nsteps, w_original , eps )
    chi_from_derivative = []
    #w = w_original
    
    _, mean_rho_0, _, chi_matrix_0 = run_monte_carlo_and_return_mean_density(N, Int(nsteps),  w_original)
    for j in 1:Int(nbins)
        #w = make_w_with_perturbation(theta_centers, eps, j)
        #_, mean_rho_eps_m, _, _ = run_monte_carlo_and_return_mean_density(N, nsteps, w_perturbed_factory(theta_centers, j, w_original  , -eps))
        _, mean_rho_eps, _, _ = run_monte_carlo_and_return_mean_density(N, nsteps, w_perturbed_factory(theta_centers, j, w_original  , eps))
        chi_col_j = - (mean_rho_eps .- mean_rho_0) ./ eps ./ L
        #chi_col_j = - (mean_rho_eps .- mean_rho_eps_m) ./ (2*eps) ./ L
        #chi_col_j = - (mean_rho_eps .- mean_rho_0) ./ (w.(theta_centers[j])- w_original.(theta_centers[j])) ./ L
        push!(chi_from_derivative, chi_col_j)
        print_acceptance_bar(j, Int(nbins))
    end
    chi_from_derivative = reduce(hcat, chi_from_derivative)
    return [chi_matrix_0,chi_from_derivative]
end

# ╔═╡ 8b97e6cc-e4ed-4dda-828e-7b8abe91bd17
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

# ╔═╡ 1bf5bb64-4325-43ec-b240-3d721d05ff4b
#🔥 Bloc 6 — Calculs
chi_exacte, chi_perturbée = run_chi_from_derivative(N, nsteps, w_original, eps)

# ╔═╡ 64028410-1a44-4cd5-b036-249049811782
#🌡️ Bloc 7 — Affichage des résultats
begin
	p1 = heatmap(theta_centers, theta_centers, chi_exacte, xlabel=L"\theta'", ylabel=L"\theta", title="χ exacte", colorbar=true, aspect_ratio=1)
	p2 = heatmap(theta_centers, theta_centers, chi_perturbée, xlabel=L"\theta'", ylabel=L"\theta", title="χ par perturbation", colorbar=true, aspect_ratio=1)
	p3 = heatmap(theta_centers, theta_centers, log10.(abs.((chi_exacte .+ 1e-10) ./ (chi_perturbée .+ 1e-10))), xlabel=L"\theta'", ylabel=L"\theta", title="log₁₀ |χ/χ_perturbée|", colorbar=true, aspect_ratio=1)

	plot(p1, p2, p3, layout=(1,3), size=(1800, 600))
end

# ╔═╡ Cell order:
# ╠═b30a0b15-f456-4e84-b13e-fa2bf3ba249f
# ╠═299102b0-6cca-11f0-1c56-e5b218c87129
# ╠═8181996d-0d70-4a9f-a257-7d5db95ee8d8
# ╠═550e8b3a-f272-45ff-b8bb-462456fe414f
# ╠═3feb4f31-e3cc-4464-a397-de958f6eaa6e
# ╠═03837246-1c66-4125-b860-4928d25cc545
# ╠═5f09a11a-7bae-4830-bf85-7ab9ca088f4b
# ╠═784c1707-049c-4d30-9f5d-5dd4634b1605
# ╠═764682b6-f979-4deb-8d4a-cd74fc4f424d
# ╠═03b27b2a-bd58-4190-aa89-a5a775c0a27d
# ╠═6a187dbc-7242-4f24-b429-65febb474ee6
# ╠═bb4b1abf-da0a-4fa3-b55a-3bffc4c72125
# ╠═9e64ec61-7fbd-4284-a070-2704a990c9d2
# ╠═5fbbe838-d172-42d4-8723-a0fc9ddb0813
# ╠═43f22688-8d59-4f65-84d8-f97a463d42a5
# ╠═265738ba-0cec-4c93-8701-fd2157b20add
# ╠═7cd1f176-d81f-4f7d-9730-74d489d24ad7
# ╠═8b97e6cc-e4ed-4dda-828e-7b8abe91bd17
# ╠═1bf5bb64-4325-43ec-b240-3d721d05ff4b
# ╟─64028410-1a44-4cd5-b036-249049811782
