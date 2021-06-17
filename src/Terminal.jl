export with_terminal, @terminal

import Suppressor: @color_output, @capture_out, @capture_err
import Logging:  ConsoleLogger, with_logger
import Markdown: htmlesc
import Base: show

struct WithTerminalOutput
    stdout::String
    stderr::String
    value::Any
end

function show(io::IO, mime::MIME"text/html", with_terminal::WithTerminalOutput)
	show(io, mime, HTML("""
		$(terminal_css)
        <div class="PlutoUI_terminal">
            <pre>$(htmlesc(with_terminal.stdout))</pre>
            $(isempty(with_terminal.stderr) ? "" : "<pre class='err'>" * htmlesc(with_terminal.stderr) * "</pre>")
        </div>
    """))
end

const terminal_css = """
<style>
div.PlutoUI_terminal {
    border: 10px solid #cedbd0; /* https://www.vintagecomputer.net/browse_thread.cfm?id=618 */
    border-radius: 15px;
    font-size: .65rem;
    background-color: #333;
    max-height: 300px;
    overflow: auto;
}
pluto-output div.PlutoUI_terminal pre:not(.no-block) {
    color: #ddd;
    background-color: transparent;
    margin-block-end: 0;
    height: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
}

div.PlutoUI_terminal pre.err {
    color: #ff5f5f;
}
</style>
"""

"""
Run the function, and capture all messages to `stdout`. The result will be a small terminal displaying the captured text.

This allows you to to see the messages from `println`, `dump`, `Pkg.status`, etc.

Example:

```julia
with_terminal() do
    x=1+1
    println(x)
    @warn "Oopsie!"
end 
```

```julia
with_terminal(dump, [1,2,[3,4]])
```

See also [PlutoUI.Dump](@ref).
           
"""
function with_terminal(f::Function, args...; kwargs...)
    local spam_out, spam_err, value
	@color_output false begin
		spam_out = @capture_out begin
            spam_err = @capture_err begin
	            with_logger(ConsoleLogger(stdout)) do	
                    value = f(args...; kwargs...)
                end
			end
		end
  end
	WithTerminalOutput(spam_out, spam_err, value)
end

"""
A convenience macro for `with_terminal` calls. See usage below.
			
__Usage:__
			
```julia
@terminal @show 2+2
@terminal begin
	println("2+2 = ", 2+2)
	println("also...")
	println("4+4 = ", 4+4)
end
@terminal print("Hello, world!")
```
"""
macro terminal(expr)
	quote
		with_terminal() do
			$(esc(expr))
		end
	end
end
