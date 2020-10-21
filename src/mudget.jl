using Mustache
export @mudget

function mustache_vars!(tokens, vars=Symbol[], layer::Int=0)
    for token in tokens
        if token._type != "text" && (layer==0 || startswith(token.value, "~"))
            if startswith(token.value, ":") || startswith(token.value, "~")
                sym = strip(token.value, [':', '~'])
            else
                sym = token.value
            end
            sym != "default" && push!(vars, Symbol(sym))
        end
        if token isa Mustache.SectionToken
            mustache_vars!(token.collector, vars, layer+1)
        end
    end
    return vars
end

"""
    @mudget TypeName template

```example
julia> @mudget MyFileInput "<input type='file' id='{{id}}' accept='{{#accepts}}{{.}}, {{/accepts}}'" accepts=[]

julia> mfi = MyFileInput(default="", id="haha")
MyFileInput("haha", Any[], "")

julia> show(stdout, MIME("text/html"), mfi)
<input type='file' id='haha' accept=''
```

It will generate a type `MyFileInput` that with constructor `MyFileInput(; accepts=[], id, default)`.
Any template variable marked with `{{varname}}` and `{{:varname}}` in top level, or `{{~varname}}` in any level
will become keyword arguments of `MyFileInput`.
One can specify their initial values by appending key word arguments to this macro call.

The `default` argument is special.
It represents the default value of the mudget and will be returned by the `get(::MyFileInput)` function.
It will be there even if not used in the template.
"""
macro mudget(T, template, defaults...)
    ps = Mustache.parse(template, ("{{", "}}"))
    args = push!(unique(mustache_vars!(ps.tokens, Any[], 0)), :default)
    for d in defaults
        if d isa Expr && d.head == :(=)
            for i=1:length(args)
                if args[i] == d.args[1]
                    args[i] = d
                    break
                end
            end
        end
    end
    constr = Expr(:struct, false, T, Expr(:block, args...))
    docstr = """
    $T(; kwargs...)
HTML mudget with `kwargs`

    * $(join(args, "\n    * "))
"""

    esc(quote
        export $T
        @doc $docstr
        Base.@kwdef $constr

        function Base.show(io::IO, ::MIME"text/html", obj::$T)
            ret = $(Mustache.render)($ps, obj)
            print(io, ret)
        end

        Base.get(x::$T) = x.default
    end)
end
