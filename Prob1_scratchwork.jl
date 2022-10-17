using JuMP
using HiGHS
using DataFrames
using Plots

# generator data
investment_cost = [457000, 268000, 85000, 62580, 92000, 92000]
op_cost = [0, 22, 35, 45, 0, 0]
co2_emissions = [0, 1, 0.43, 0.55, 0, 0]
thermal_cf = [0.95, 1, 1, 1]

hours = 1:24
demand = [1517, 1486, 1544, 1733, 2058, 2470, 2628, 2696, 2653, 2591, 2626, 2714, 2803, 2842, 2891,  2821, 3017, 3074, 2957,  2487, 2249, 1933, 1684, 1563]
wind_cf = [0.58, 0.57, 0.55, 0.28, 0.14, 0.21, 0.03, 0.04, 0.01, 0.04, 0.04, 0.01, 0.04, 0.04, 0.01, 0.01, 0.01, 0.13, 0.30, 0.45, 0.44, 0.57, 0.55, 0.58]
solar_cf = [0, 0, 0, 0, 0, 0, 0.20, 0.57, 0.80, 0.93, 0.99, 0.99, 0.85, 0.99, 0.95, 0.81, 0.55, 0.12, 0, 0, 0, 0, 0, 0]

gencap = Model(HiGHS.Optimizer)
generators = ["Geothermal", "Coal", "CCGT", "CT", "Wind", "Solar"]
G = 1:length(generators)
T = 1:length(hours)

@variable(gencap, x[G] >= 0)
@variable(gencap, y[G, T] >= 0)
@objective(gencap, Min, (investment_cost'*x) + 365*sum(op_cost .* [sum(y[g, :]) for g in G]) + 1000*365*(sum(demand)-sum(y)))

avail = vcat(repeat(thermal_cf, 1, 24), wind_cf', solar_cf')
@constraint(gencap, availability[g in G, t in T], y[g, t] <= avail[g, t]*x[g])

@constraint(gencap, load[t in T], sum(y[:, t]) <= demand[t])

optimize!(gencap)
# objective_value(gencap) # total cost (over one year)

value.(x) # how much capacity should be installed for each generator type

unmet_demand = demand - [sum(value.(y).data[:, t]) for t in T] # non-served demand

# plot generated electricity by generator type over one day
# plot(value.(y).data', xlabel="Time (hr)", ylabel="Generated electricity (MW)", label=["Geothermal" "Coal" "CCGT" "CT" "Wind" "Solar"], linewidth=2)

# stacked area plot
# areaplot(value.(y).data', xlabel="Time (hr)", ylabel="Generated electricity (MW)", label=["Geothermal" "Coal" "CCGT" "CT" "Wind" "Solar"])
# plot!(demand, linewidth=2, linecolor=:black, label="Demand")