module Finance
    using YFinance, Dates, Statistics

    export Asset, Portfolio

    # --------------------------------------------------
    # Asset
    # --------------------------------------------------
    # symbol: Ticker do ativo na bolsa brasileira 
    # timestamps: Datas de dados disponíveis
    # high: Valor mais alto atingido do ativo
    # low: Valor mais baixo atingido do ativo
    # open: Valor de abertura do ativo
    # close: Valor de fechamento do ativo
    # returns: Retorno do ativo em todo o período em timestamps
    # --------------------------------------------------
    struct Asset
        symbol::AbstractString
        timestamps::Vector{Date}
        high::Vector{Float64}
        low::Vector{Float64}
        open::Vector{Float64}
        close::Vector{Float64}
        adjclose::Vector{Float64}
        returns::Vector{Float64}
    end

    # --------------------------------------------------
    # Portfolio
    # --------------------------------------------------
    # assets: Vetor de assets na carteira
    # weights: Vetor de pesos para cada um dos assets
    # returns: Retorno de toda a carteira
    # --------------------------------------------------
    struct Portfolio
        assets::Vector{Asset}
        returns::Vector{Float64}
        cov_matrix::Matrix{Float64}
        sharpe_ratio::Float64
    end

    # --------------------------------------------------
    # Construtor Asset
    # --------------------------------------------------
    function Asset(symbol::AbstractString, start_date::Date, end_date::Date)
        data = get_prices(symbol, startdt = start_date, enddt = end_date)

        timestamps = Date.(data["timestamp"])
        open = data["open"]
        close = data["close"]
        high = data["high"]
        low = data["low"]
        adjclose = data["adjclose"]

        daily_returns  = [i == 1 ? 0 : (adjclose[i]-adjclose[i-1])/adjclose[i-1] for i in eachindex(adjclose)]

        return Asset(symbol, timestamps, high, low, open, close, adjclose, daily_returns)
    end

    # --------------------------------------------------
    # Construtor Portfolio
    # --------------------------------------------------
    function Portfolio(symbol_list::Vector{AbstractString}, start_date::Date, end_date::Date)
        assets = [Asset(symbol, start_date, end_date) for symbol in symbol_list]

        returns = [mean(asset.returns) for asset in assets]

        cov_matrix = Statistics.cov(hcat([asset.returns for asset in assets]...))

        portfolio_variance = 0
        for i in 1:size(cov_matrix)[1]
            for j in 1:size(cov_matrix)[1]
                if i == j
                    portfolio_variance += cov_matrix[i,j]
                end
                
                if i < j
                    portfolio_variance += 2 * cov_matrix[i,j]
                end
            end
        end

        r_free = 0.13
        r_free_assets_returns = [(asset.returns .- r_free) for asset in assets]

        expected_return_assets = []
        for returns in r_free_assets_returns
            push!(expected_return_assets, Statistics.mean(returns))
        end

        portfolio_expected_return = sum(expected_return_assets)

        sharpe_ratio = portfolio_expected_return / portfolio_variance

        return Portfolio(assets, returns, cov_matrix, sharpe_ratio)
    end
end