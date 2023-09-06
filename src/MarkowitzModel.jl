module MarkowitzModel
    using JuMP, Gurobi

    # --------------------------------------------------
    # MarkowitzModelData
    # --------------------------------------------------
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # min_returns: Vetor de Retornos mínimos
    # models: Vetor de modelos de otimização
    # --------------------------------------------------
    struct MarkowitzModelData
        mean::Vector{Float64}
        cov::Matrix{Float64}
        min_returns::Vector{Float64}
        models::Vector{Model}
    end

    # --------------------------------------------------
    # Construtor MarkowitzModelData
    # --------------------------------------------------
    function MarkowitzModelData(mean::Vector{Float64}, cov::Matrix{Float64}, min_returns::Vector{Float64})
        n = size(mean)[1]
        GRB_ENV = Gurobi.Env()

        models = Vector{Model}()
        for min_return in min_returns
            model = model_formulation(mean, cov, min_return, GRB_ENV)
            
            push!(models, model)
        end
        
        return MarkowitzModelData(mean, cov, min_returns, models)
    end

    # --------------------------------------------------
    # Modelo de Markowitz
    # --------------------------------------------------
    # Parâmetros:
    # mean: Vetor de médias dos ativos
    # cov: Matriz de covariância dos ativos
    # min_return: Retorno mínimo
    # --------------------------------------------------
    # Retorno:
    # model: Modelo de otimização de Markowitz
    # --------------------------------------------------
    function model_formulation(mean::Vector{Float64}, cov::Matrix{Float64}, min_return::Float64, env::Gurobi.Env = Gurobi.Env())
        n = size(mean)[1]
        model = Model(() -> Gurobi.Optimizer(env))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "TimeLimit", 100)
        set_optimizer_attribute(model, "MIPGap", 0.001)
        set_optimizer_attribute(model, "Threads", min(length(Sys.cpu_info()),16))

        @variable(model, x[1:n] >= 0)

        @constraint(model, sum(x) == 1)
        @constraint(model, mean'*x >= min_return)

        @objective(model, Min, (x'*cov*x))
        
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