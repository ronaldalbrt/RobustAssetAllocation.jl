module MarkowitzModel
    using JuMP, Gurobi

    # --------------------------------------------------
    # MarkowitzModelData
    # --------------------------------------------------
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # risk_levels: Vetor de níveis de risco
    # models: Vetor de modelos de otimização
    # --------------------------------------------------
    struct MarkowitzModelData
        mean::Vector{Float64}
        cov::Matrix{Float64}
        risk_levels::Vector{Float64}
        models::Vector{Model}
    end

    # --------------------------------------------------
    # Construtor MarkowitzModelData
    # --------------------------------------------------
    function MarkowitzModelData(mean::Vector{Float64}, cov::Matrix{Float64}, risk_levels::Vector{Float64})
        n = size(mean)[1]
        GRB_ENV = Gurobi.Env()

        models = Vector{Model}()
        for risk_level in risk_levels
            model = Model(() -> Gurobi.Optimizer(GRB_ENV))
            set_optimizer_attribute(model, "OutputFlag", 0)
            set_optimizer_attribute(model, "TimeLimit", 100)
            set_optimizer_attribute(model, "MIPGap", 0.001)
            set_optimizer_attribute(model, "Threads", min(length(Sys.cpu_info()),16))

            @variable(model, x[1:n] >= 0)

            @constraint(model, sum(x) == 1)

            @objective(model, Max, risk_level*(mean'*x) - (1 - risk_level) * (x'*cov*x))
            
            push!(models, model)
        end
        
        return MarkowitzModelData(mean, cov, risk_levels, models)
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
    function pareto_frontier(markowitz_model::MarkowitzModelData)
        allocations = Vector{Vector{Float64}}()

        for (i, model) in enumerate(markowitz_model.models)
            optimize!(model)

            push!(allocations, value.(model[:x]))
        end

        allocation_return = alloc -> markowitz_model.mean'*alloc
        allocation_risk = alloc -> alloc' * markowitz_model.cov * alloc

        
        return allocations, allocation_return.(allocations), allocation_risk.(allocations)
    end
end