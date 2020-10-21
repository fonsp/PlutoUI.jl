using PlutoUI
using Mustache
using Markdown: html
using Test

@testset "builtins" begin
    @mudget MyFileInput "<input type='file' id='{{id}}' accept='{{#accepts}}{{.}}, {{/accepts}}'>" accepts=[]
    mfi = MyFileInput(default="", id="haha", accepts=[".toml", ".dat"])
    @test html(mfi) == "<input type='file' id='haha' accept='.toml, .dat, '>"
end

@testset "mustache vars" begin
    @test PlutoUI.mustache_vars!(mt"{{x}}{{#y}}{{z}}{{/y}}{{:l}}".tokens) == [:x, :y, :l]
end
