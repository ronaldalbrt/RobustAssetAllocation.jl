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
        returns::Float64
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
        weights::Vector{Float64}
        returns::Float64
    end

    function Asset(symbol::AbstractString, start_date::Date, end_date::Date)
        data = get_prices(symbol, startdt = start_date, enddt = end_date)

        timestamps = Date.(data["timestamp"])
        open = data["open"]
        close = data["close"]
        high = data["high"]
        low = data["low"]

        daily_returns  = [i == 1 ? 0 : (close[i]-close[i-1])/close[i-1] for i in eachindex(close)]
        returns = cumprod(1 .+ daily_returns)[end]

        return Asset(symbol,timestamps, high, low, open, close, returns)
    end


    function Portfolio(symbol_list::Vector{AbstractString}, weights::Vector{Float64}, start_date::Date, end_date::Date)
        assets = [Asset(symbol, start_date, end_date) for symbol in symbol_list]

        returns = sum([asset.returns * weight for (asset, weight) in zip(assets, weights)])

        return Portfolio(assets, weights, returns)
    end
end