module RobustMarkowitzModel
    using Distributions, Gurobi, JuMP
    # --------------------------------------------------
    # MarkowitzModelData
    # --------------------------------------------------
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # risk_levels: Vetor de níveis de risco
    # models: Vetor de modelos de otimização
    # --------------------------------------------------
    struct RobustMarkowitzModelData
        n::Int64
        return_interval::Tuple{Vector{Float64}, Vector{Float64}}
        cov_interval::Tuple{Matrix{Float64}, Matrix{Float64}}
        minimum_return::Vector{Float64}
        confidence_level::Float64
        models::Vector{Model}
    end

    # --------------------------------------------------
    # Construtor RobustMarkowitzModelData
    # --------------------------------------------------
    function RobustMarkowitzModelData(n::Int64, returns::Vector{Float64}, cov::Matrix{Float64}, min_returns::Vector{Float64}, confidence_level::Float64)
        t_dist = Distributions.TDist(n - 1)
        q = quantile(t_dist, (1 - confidence_level)/2)

        return_interval = (returns .+ q*diag(cov), returns - q*diag(cov))
        # cov_interval = 
    end

    # --------------------------------------------------
    # Modelo de Markowitz Robusto
    # --------------------------------------------------
    # Parâmetros:
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # risk_level: Nível de risco
    # --------------------------------------------------
    # Retorno:
    # model: Modelo de otimização de Markowitz Robusto
    # --------------------------------------------------
    function model_formulation(return_interval::Tuple{Vector{Float64}, Vector{Float64}}, cov_interval::Tuple{Matrix{Float64}, Matrix{Float64}}, min_return::Float64, env::Gurobi.Env = Gurobi.Env())
        n = size(return_interval[1])[1]

        model = Model(() -> Gurobi.Optimizer(env))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "TimeLimit", 100)
        set_optimizer_attribute(model, "MIPGap", 0.001)
        set_optimizer_attribute(model, "Threads", min(length(Sys.cpu_info()),16))

        @variable(model, x[1:n] >= 0)

        @constraint(model, sum(x) == 1)

        @constraint(model, return_interval[1]'*x >= min_return)
        @objective(model, Min, (x'*cov_interval[2]*x))
        
        return model
    end
end