using ForwardDiff
FD = ForwardDiff

Δx = 0.2
Lx = 1.0
xlim = (-Lx,Lx)
ylim = (-Lx,Lx)
g = PhysicalGrid(xlim,ylim,Δx)
    
n = 5
x = 0.5 .+ 0.2*rand(n)
y = 0.5 .+ 0.2*rand(n)

X = zeros(2n)
for i in eachindex(x)
    X[2i-1] = x[i]
    X[2i] = y[i]
end

cfg = FD.JacobianConfig(Regularize, X)
Xdual = cfg.duals
FD.seed!(Xdual, X)
seeds = cfg.seeds
FD.seed!(Xdual, X, 1, seeds)
xdual = Xdual[1:2:end]
ydual = Xdual[2:2:end]

function get_ddf_type(::DDF{ddftype,OVERDX}) where {ddftype,OVERDX}
    return ddftype
end

@testset "Regularization accepting FD.Dual numbers" begin
    Hdual = Regularize(xdual,ydual,cellsize(g),I0=origin(g),issymmetric=true)
    H = Regularize(x,y,cellsize(g),I0=origin(g),issymmetric=true)

    @testset "Regularization check for FD.Dual numbers" begin
        @test FD.value.(H.x) == H.x
        @test FD.value.(H.y) == H.y
    end 

    @testset "Derivative of DDF for FD.Dual numbers" begin
        Hdual_ddf = Hdual.ddf(xdual,ydual)
        H_ddf = H.ddf(x,y)
        ddftype = get_ddf_type(H.ddf)
        ddfx = GradDDF(1,ddftype=ddftype,dx=1.0)
        ddfy = GradDDF(2,ddftype=ddftype,dx=1.0)
        ddfxval = ddfx(x,y)
        ddfyval = ddfy(x,y)

        for i=1:n
            @test FD.partials.(Hdual_ddf,2i-1)[i,:] == ddfxval[i,:]
        end
        for i=1:n
            @test FD.partials.(Hdual_ddf,2i)[:,i] == ddfyval[:,i]
        end
    end 

end



