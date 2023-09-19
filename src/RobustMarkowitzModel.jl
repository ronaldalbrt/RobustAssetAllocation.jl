module RobustMarkowitzModel
    using Distributions, Gurobi, JuMP
    # --------------------------------------------------
    # MarkowitzModelData
    # --------------------------------------------------
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # risk_levels: Vetor de níveis de risco
    # models: Vetor de modelos de otimização
    # K: Número de ativos a serem selecionados
    # --------------------------------------------------
    struct RobustMarkowitzModelData
        n::Int64
        return_interval::Tuple{Vector{Float64}, Vector{Float64}}
        cov_interval::Tuple{Matrix{Float64}, Matrix{Float64}}
        minimum_return::Vector{Float64}
        α::Float64
        models::Vector{Model}
        K::Int64
    end

    # --------------------------------------------------
    # Construtor RobustMarkowitzModelData
    # --------------------------------------------------
    function RobustMarkowitzModelData(n::Int64, returns::Vector{Float64}, cov::Matrix{Float64}, min_returns::Vector{Float64}, α::Float64, K::Int64 = 5)
        GRB_ENV = Gurobi.Env()
        
        # Quantil da distribuição t de Student com n - 1 graus de liberdade e nível de significância α
        q = quantile(Distributions.TDist(n - 1), α/2)

        # Quantis da distribuição qui-quadrado com n - 1 graus de liberdade e nível de significância α
        chi_q_u = quantile(Distributions.Chisq(n - 1), α/2)
        chi_q_l = quantile(Distributions.Chisq(n - 1), 1 - α/2)

        diag_cov = [cov[i,i] for i in 1:size(cov)[1]]

        # Intervalo de confiança para o retorno
        return_interval = (returns .+ q.*(diag_cov/sqrt(n)), returns .- q.*(diag_cov/sqrt(n)))
  
        # Intervalo de confiança para a matriz covariância
        cov_l = [(n - 1)*cov[i,j]/chi_q_l for i in 1:size(cov)[1], j in 1:size(cov)[2]]
        cov_l = [i != j ? -cov_l[i,i]*cov_l[j,j] : cov_l[i,i] for i in 1:size(cov)[1], j in 1:size(cov)[2]]
        cov_u = [(n - 1)*cov[i,j]/chi_q_u for i in 1:size(cov)[1], j in 1:size(cov)[2]]
        cov_u = [i != j ? cov_u[i,i]*cov_u[j,j] : cov_u[i,i] for i in 1:size(cov)[1], j in 1:size(cov)[2]]
        cov_interval = (cov_l, cov_u)

        models = [model_formulation(return_interval, cov_interval, min_return, K, GRB_ENV) for min_return in min_returns]

        return RobustMarkowitzModelData(n, return_interval, cov_interval, min_returns, α, models, K)
    end

    # --------------------------------------------------
    # Modelo de Markowitz Robusto
    # --------------------------------------------------
    # Parâmetros:
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # risk_level: Nível de risco
    # K: Número de ativos a serem selecionados
    # --------------------------------------------------
    # Retorno:
    # model: Modelo de otimização de Markowitz Robusto
    # --------------------------------------------------
    function model_formulation(return_interval::Tuple{Vector{Float64}, Vector{Float64}}, cov_interval::Tuple{Matrix{Float64}, Matrix{Float64}}, min_return::Float64, K::Int64, env::Gurobi.Env = Gurobi.Env())
        n = size(return_interval[1])[1]

        # Definição do Modelo Robusto de Markowitz
        model = Model(() -> Gurobi.Optimizer(env))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "TimeLimit", 100)
        set_optimizer_attribute(model, "MIPGap", 0.001)
        set_optimizer_attribute(model, "NonConvex", 2)
        set_optimizer_attribute(model, "Threads", min(length(Sys.cpu_info()),16))

        @variable(model, x[1:n] >= 0)
        @variable(model, y[1:n], Bin)

        @constraint(model, sum(x) == 1)
        @constraint(model, sum(y) == K)
        @constraint(model, return_interval[1]'*x >= min_return)
        @constraint(model, [i=1:n], x[i] <= y[i])

        @objective(model, Min, (x'*cov_interval[2]*x))
        
        return model
    end


    # --------------------------------------------------
    # Cálcula os valores para a Fronteira de Pareto
    # --------------------------------------------------
    # markowitz_model: Modelo de otimização de Markowitz
    # --------------------------------------------------
    # Retorno: 
    # allocations: Vetor de alocações para cada um dos modelos
    # allocation_return: Vetor de retornos para cada uma das alocações
    # allocation_risk: Vetor de riscos para cada uma das alocações
    # --------------------------------------------------
    function pareto_frontier(markowitz_model::RobustMarkowitzModelData)
        allocations = Vector{Vector{Float64}}()
        allocated = Vector{Vector{Int64}}()

        for (_, model) in enumerate(markowitz_model.models)
            optimize!(model)

            push!(allocations, value.(model[:x]))
            push!(allocated, value.(model[:y]))
        end
        allocation_return = alloc ->  (markowitz_model.return_interval[1]'*alloc, markowitz_model.return_interval[2]'*alloc)
        allocation_risk = alloc -> (alloc' * markowitz_model.cov_interval[1] * alloc, alloc' * markowitz_model.cov_interval[2] * alloc)

        
        return allocations, allocated[1], allocation_return.(allocations), allocation_risk.(allocations)
    end
end