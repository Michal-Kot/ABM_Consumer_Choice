using DataFrames
using CSV
using DataFrames
using DataFramesMeta
using StatsPlots
using Plots
using StatsBase
using GLM
using LinearAlgebra

df_elas = CSV.read(pwd() * "/data/results_final_elasticity.csv", DataFrame, decimal = ',', delim=';')

rename!(df_elas, ["num_firms","num_customers","network_type","pref_att_links","acc_step","l_ind","l_wom","l_ad","q","s_v0","s_a","s_e","maxstock","wealth","risk","buyer_memory","p","c","d","cpp","a","ai","num_links","max_iter","roi","mgn","cst","market_size","sales_quantity","final_quanlity_expectation","final_uncertainty"])

df_elas_gp = @chain df_elas begin
    @select(:ai, :d, :p, :sales_quantity)
    @transform(p_d = :p .- :d)
    groupby([:ai, :p_d])
    combine(:sales_quantity => mean)
end

sort!(df_elas_gp, :ai)

p1 = plot(df_elas_gp[df_elas_gp.ai .== -0.05,:p_d], df_elas_gp[df_elas_gp.ai .== -0.05,:sales_quantity_mean], markershape = :circle, xlabel = "Price", ylabel = "Demand", label = "Ad intensity = 0.0")
plot!(df_elas_gp[df_elas_gp.ai .== -0.025,:p_d], df_elas_gp[df_elas_gp.ai .== -0.025,:sales_quantity_mean], markershape = :circle, xlabel = "Price", ylabel = "Demand", label = "Ad intensity = 0.025")
plot!(df_elas_gp[df_elas_gp.ai .== 0,:p_d], df_elas_gp[df_elas_gp.ai .== 0,:sales_quantity_mean], markershape = :circle, label = "Ad intensity = 0.050")
plot!(df_elas_gp[df_elas_gp.ai .== 0.025,:p_d], df_elas_gp[df_elas_gp.ai .== 0.025,:sales_quantity_mean], markershape = :circle, label = "Ad intensity = 0.075")
plot!(df_elas_gp[df_elas_gp.ai .== 0.05,:p_d], df_elas_gp[df_elas_gp.ai .== 0.05,:sales_quantity_mean], markershape = :circle, label = "Ad intensity = 0.100")
plot!(df_elas_gp[df_elas_gp.ai .== 0.075,:p_d], df_elas_gp[df_elas_gp.ai .== 0.075,:sales_quantity_mean], markershape = :circle, label = "Ad intensity = 0.125")

p2 = plot(df_elas_gp[df_elas_gp.p_d .== 30,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 30,:sales_quantity_mean], markershape = :circle, xlabel = "Advertising intensity", ylabel = "Demand", label = "Price = 30", legend = :topleft)
xticks!([0, 0.025, 0.050, 0.075, 0.10, 0.125])
plot!(df_elas_gp[df_elas_gp.p_d .== 35,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 35,:sales_quantity_mean], markershape = :circle, label = "Price = 35")
plot!(df_elas_gp[df_elas_gp.p_d .== 40,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 40,:sales_quantity_mean], markershape = :circle, label = "Price = 40")
plot!(df_elas_gp[df_elas_gp.p_d .== 45,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 45,:sales_quantity_mean], markershape = :circle, label = "Price = 45")
plot!(df_elas_gp[df_elas_gp.p_d .== 50,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 50,:sales_quantity_mean], markershape = :circle, label = "Price = 50")
plot!(df_elas_gp[df_elas_gp.p_d .== 55,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 55,:sales_quantity_mean], markershape = :circle, label = "Price = 55")
plot!(df_elas_gp[df_elas_gp.p_d .== 60,:ai] .+ 0.05, df_elas_gp[df_elas_gp.p_d .== 60,:sales_quantity_mean], markershape = :circle, label = "Price = 60")

df_elas_gp_by_ai = @chain df_elas_gp begin
    groupby(:ai)
    combine(:sales_quantity_mean => minimum, :sales_quantity_mean => maximum)
    @transform(range_between = :sales_quantity_mean_maximum .- :sales_quantity_mean_minimum)
    @transform(elasticity = :range_between ./ 30)
    @select(:ai, :elasticity)
end

margin = [mean((df_elas.sales_quantity)[(df_elas.ai .== a) .& (df_elas.d .== p)]) for a in sort(unique(df_elas.ai)), p in sort(unique(df_elas.d))]

margin_incremental = margin .- margin[1,1]

margin_incremental = transpose(transpose(margin_incremental) .* collect(30:-2.5:0))

cost_advertising = [mean(((df_elas.a .+ df_elas.ai) .* 100 / 2 .* df_elas.max_iter * 3)[(df_elas.ai .== a) .& (df_elas.d .== p)]) for a in sort(unique(df_elas.ai)), p in sort(unique(df_elas.d))]

profit = margin_incremental - cost_advertising

x = sort(unique(df_elas.d))
y = sort(unique(df_elas.ai)) .+ 0.05

p3 = Plots.heatmap(x, y, profit, xlabel = "Discount", ylabel = "Advertising intensity",border="black")
xticks!(x)
yticks!(y)

r_profit = round.(profit ./ maximum(profit),digits=2)

fontsize = 10
nrow, ncol = size(profit)
for i in 1:nrow
    for j in 1:ncol
        p3 = annotate!(x[j],y[i], text(r_profit[i,j], 10))
    end
end 

p3