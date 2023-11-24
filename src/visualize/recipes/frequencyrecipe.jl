"""

    frequencybydepthplot(experiment::RelativeSpikes, depths, period)
    frequencybydepthplot!(ax, experiment::RelativeSpikes, depths, period)

Makie plot recipe for relative frequency by depth.           

Requires an `experiment::RelativeSpikes`, number of `depths` and `period` for length of bins when calculating frequency.

## Attributes

### Plot-specific Attributes

- `customx` A vector of custom x values. Should be of the same length as the number of frequency bins.

### General 'lines' attributes

- `color`
- `linestyle`
- `linewidth`
- `colormap`
- `colorscale`
- `colorrange`
- `nan_color`
- `lowclip`
- `highclip`
- `alpha`
- `visible`
- `overdraw`
- `fxaa`
- `inspectable`
- `depth_shift`
- `space`
"""
MakieCore.@recipe(FrequencyByDepthPlot, experiment, depths, period) do scene
    MakieCore.Attributes(
        stimlines=true,
        customx=nothing,
        color=nothing,
        linestyle=:solid,
        linewidth=1.5,
        colormap=:viridis,
        colorscale=identity,
        colorrange=(0.0, 2.5),
        nan_color="#ffffff",
        lowclip=nothing,
        highclip=nothing,
        alpha=1.0,
        visible=true,
        overdraw=false,
        fxaa=true,
        inspectable=true,
        depth_shift=0.0f0,
        space=:data
    )
end


function MakieCore.plot!(plt::FrequencyByDepthPlot)
    p = plt.experiment

    depths = plt.depths

    period = plt.period

    lins = MakieCore.Observable(Vector{Vector{Float64}}(undef, 0))
    alldepths::Vector{Float64} = parse.(Float64, info.(clustervector(p[]), "depth"))
    maxdepth::Float64 = maximum(alldepths)

    function update_plot(p, depths, period, alldepths, maxdepth)
        depthinterval = maxdepth / depths[]
        actualdepths::Vector{Int64} = Int64[]

        for d in depths[]:-1:1
            if length(alldepths[(d-1)*depthinterval.<=alldepths.<d*depthinterval]) != 0
                push!(actualdepths, d)
            end
        end

        empty!(lins[])

        for i in eachindex(actualdepths)
            dpth::NTuple{2,Float64} = ((actualdepths[i] - 1) * depthinterval, actualdepths[i] * depthinterval)
            push!(
                lins[],
                LaskaCore.relativefrequency(LaskaCore.spikesatdepth(p[], dpth), period[])
            )
        end
        maxresp = maximum(maximum(lins[])) + abs(minimum(minimum(lins[])))
        for i in length(lins[]):-1:1
            lins[][i] .+= (((i - 1) * maxresp) - 1)
        end


    end
    MakieCore.Observables.onany(update_plot, p, depths, period)
    update_plot(p, depths, period, alldepths, maxdepth)

    if isnothing(plt.color[])
        plt.color[] = standardcol
    end
    if isnothing(plt[:customx][])
        plt[:customx][] = LaskaCore.sampleratetoms(collect(LaskaCore.roundup(LaskaCore.minval(spikesatdepth(p[], (0.0, maxdepth))), period[]):period[]:LaskaCore.roundup(LaskaCore.maxval(spikesatdepth(p[], (0.0, maxdepth))), period[]))[2:end], parse(Float64, getmeta(p[], "imSampRate")))
    end

    if plt[:stimlines][]
        stimT = collect(values(stimtimes(p[])))
        Makie.vlines!(
            plt,
            stimT,
        )
    end


    for i in eachindex(lins[])
        MakieCore.lines!(
            plt,
            plt[:customx][],
            lins[][i],
            color=plt.color[],
            linestyle=plt.linestyle[],
            linewidth=plt.linewidth[],
            colormap=plt.colormap[],
            colorscale=plt.colorscale[],
            colorrange=plt.colorrange[],
            nan_color=plt.nan_color[],
            lowclip=plt.lowclip[],
            highclip=plt.highclip[],
            alpha=plt.alpha[],
            visible=plt.visible[],
            overdraw=plt.overdraw[],
            fxaa=plt.fxaa[],
            inspectable=plt.inspectable[],
            depth_shift=plt.depth_shift[],
            space=plt.space[])
    end
end
