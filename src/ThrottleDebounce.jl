### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ d921bec2-b491-471f-9373-ae4cfbc7b210
using HypertextLiteral

# ╔═╡ e6b13f1f-cdc6-447f-9c23-e994f901965a
md"""
# `throttle` and `debounce` wrappers
_Limit the frequency of input events!_

When moving a slider from 0 to 100, it will fire many **intermediate values**, and you can see that the notebook updates many times.
"""

# ╔═╡ 15f9f9b5-e5b5-4743-bf48-9f2322d1e863
md"""
### Throttled
Normally, this is great, since it gives you very interactive notebooks! However, in some cases, you want to **limit how many events are fired per second**. 

This is done with the `throttled` function, which takes two arguments: 
1. the element to throttle, and 
2. the minimum time _(in seconds)_ between two input events.
"""

# ╔═╡ 01b4ba88-8d86-4905-b5c3-20c05917c024
md"""
You can give two additional keyword arguments:
- `leading::Bool=true`: After the cooldown period, fire the first input immediately?
- `trailing::Bool=true`: After the last cooldown period, also fire the last throttled event?

For more info, see the [lodash documentation](https://lodash.com/docs/4.17.15#throttle).
"""

# ╔═╡ a98461b6-883f-4e89-bb7a-7e60d7ab807d
md"""
### Debounced
Besides _throttling_ the number of inputs fired per second, you can also **discard all intermediate events**. In the case of a slider, an event will only be fired when you stop moving the slider for a short while.

This is done with the `debounced` function, which takes two arguments: 
1. the element to debounce, and 
2. the cooldown time _(in seconds)_ during which events will be discarded.
"""

# ╔═╡ 4e87b559-c0ca-450a-ba75-e713c86d6c26
md"""
You can give three additional keyword arguments:
- `leading::Bool=false`: After the cooldown period, fire the first input immediately?
- `maxwait::Union{Nothing,Real}=nothing`: The maximum time that events are allowed to be delayed.
- `trailing::Bool=true`: After the last cooldown period, also fire the last throttled event?

For more info, see the [lodash documentation](https://lodash.com/docs/4.17.15#debounce).
"""

# ╔═╡ ba7e3059-a12a-4031-84c7-be0113c3a1dc


# ╔═╡ 7d955dc4-4ad3-4d0f-9e86-9c5595604ff4
"Fake slider used in examples"
Slider(args...) = html"<input type=range value=0>";

# ╔═╡ 003440c7-cf98-4830-9648-ea7b7101683c
begin
	struct CoolSlider
	end
	Base.get(::CoolSlider) = 50
	Base.show(io::IO, m::MIME"text/html", t::CoolSlider) = write(io, "<input type=range>")
end

# ╔═╡ 820df928-69a0-4704-8c36-d46d73085318
md"""
# More tests
"""

# ╔═╡ d17f533b-7b15-4c76-8a42-a723de409476
function renderlodash(el, wait_ms::Real, method::String, options)
	@htl("""
	<span>
	
	$(el)

	<script>
		

	const { default: _ } = await import("https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm")

	const span = currentScript.parentElement
	
	const el = span.firstElementChild
	
	console.log(el)

		const val = { current: el.value }
		
		const relay = _[$(method)](() => {
			span.value = val.current
			span.dispatchEvent(new CustomEvent("input"))
		}, $(wait_ms), $(options))
		
		
		;(async () => {
			for (const value of Generators.input(el)) {
				val.current = await value
				relay()
			  }
		
		})();
		
		
		el.addEventListener("input", (e) => {
			e.stopPropagation()
		})

	</script>
	</span>
	""")
end

# ╔═╡ 9f8b24de-6f9f-4af1-b73e-8c6da073520a
begin
	struct ThrottleDebounced{T}
		x::T
		wait_ms::Real
		method::String
		options
	end
	
	
	
	Base.get(t::ThrottleDebounced{T}) where T = if hasmethod(Base.get, Tuple{T})
		Base.get(t.x)
	else
		missing
	end
	
	function Base.show(io::IO, m::MIME"text/html", t::ThrottleDebounced)
		
		
		Base.show(io, m, renderlodash(t.x, t.wait_ms, t.method, t.options))
	end
	
	
	
end

# ╔═╡ 2104e758-282e-458c-9595-9254718b4645
@bind x Slider(0:100)

# ╔═╡ f7694341-411b-4247-b5a9-5cca33a39e0f
x

# ╔═╡ 9eedad1d-8ebe-4005-aec6-1ecb2816af63
"""
    throttled(widget, delay_seconds::Real)

A wrapper around an input `widget` that limits how many input events are fired per second. 

# Example

```julia
@bind x throttled(Slider(1:100), 0.5)

x
```

`x` will be updated at most 2 times per second.

"""
function throttled(el, wait=0; leading::Bool=true, trailing::Bool=true)
	ThrottleDebounced(
		el,
		wait * 1000,
		"throttle",
		Dict(
			:leading=>leading,
			:trailing=>trailing,
		)
	)
end

# ╔═╡ 559f3670-604c-49bf-9769-f8e852e9536b
@bind y throttled(Slider(0:100), 1.0)

# ╔═╡ 4014c7fc-5c0a-487c-9811-85fc4fc3afe4
y

# ╔═╡ 07345774-7c05-400f-85bc-faa9531d589a
@bind y_non_trailing throttled(Slider(0:100), 1.0; trailing=false)

# ╔═╡ e0e20ff5-40c4-4fee-b902-2248afc3b397
y_non_trailing

# ╔═╡ 7f9b2c9c-38dd-45b4-a2f6-8bcb8ef7c1ac
"""
    debounced(widget, delay_seconds::Real)

A wrapper around an input `widget` that discards all intermediate inputs events, and only relays the last value, when no input event is fired in an `delay_seconds` interval.

# Example

```julia
@bind x debounced(Slider(1:100), 0.5)

x
```

`x` will only be updated when you do not move the slider for 0.5 seconds.

"""
function debounced(el, wait=0; leading::Bool=false, maxwait::Union{Nothing,Real}=nothing, trailing::Bool=true)
	ThrottleDebounced(
		el,
		wait * 1000,
		"debounce",
		Dict(
			:leading=>leading,
			:maxwait=>maxwait,
			:trailing=>trailing,
		)
	)
end

# ╔═╡ 1d81d96e-8642-4f8d-aa7c-2ad53fae2cb8
@bind z debounced(Slider(0:100), 1.0)

# ╔═╡ 251fa612-e621-4ed8-b517-1d0715e9f98e
z

# ╔═╡ 31d187e1-9ce7-4738-8dc6-0643d2da16cd
export throttled, debounced

# ╔═╡ 5f82a82b-10a5-4702-837a-fb4e2dcaff3f
@bind x1 Slider()

# ╔═╡ 400fc0b0-3c0b-4bac-9575-4a969aa8b8fe
begin
	x2s = []
	@bind x2 throttled(Slider(), 0.5)
end

# ╔═╡ bf73c955-243a-4969-b2f9-60a1116fd021
push!(x2s, x2)

# ╔═╡ a993d308-29a6-4933-9b6f-7d28a8db4d56
begin
	x3s = []
	@bind x3 throttled(CoolSlider(), 0.5)
end

# ╔═╡ 1113967d-09fb-4645-8396-d5c1f9b30f51
push!(x3s, x3)

# ╔═╡ b6d3d6c5-9087-4878-a06c-42bc6f823ea9
begin
	x4s = []
	@bind x4 debounced(CoolSlider(), 0.5)
end

# ╔═╡ 45500c96-acaa-43f5-90ea-b3aac8a9a46c
push!(x4s, x4)

# ╔═╡ Cell order:
# ╟─e6b13f1f-cdc6-447f-9c23-e994f901965a
# ╠═2104e758-282e-458c-9595-9254718b4645
# ╠═f7694341-411b-4247-b5a9-5cca33a39e0f
# ╟─15f9f9b5-e5b5-4743-bf48-9f2322d1e863
# ╠═559f3670-604c-49bf-9769-f8e852e9536b
# ╠═4014c7fc-5c0a-487c-9811-85fc4fc3afe4
# ╟─01b4ba88-8d86-4905-b5c3-20c05917c024
# ╠═07345774-7c05-400f-85bc-faa9531d589a
# ╠═e0e20ff5-40c4-4fee-b902-2248afc3b397
# ╟─a98461b6-883f-4e89-bb7a-7e60d7ab807d
# ╠═1d81d96e-8642-4f8d-aa7c-2ad53fae2cb8
# ╠═251fa612-e621-4ed8-b517-1d0715e9f98e
# ╟─4e87b559-c0ca-450a-ba75-e713c86d6c26
# ╠═31d187e1-9ce7-4738-8dc6-0643d2da16cd
# ╠═9eedad1d-8ebe-4005-aec6-1ecb2816af63
# ╠═7f9b2c9c-38dd-45b4-a2f6-8bcb8ef7c1ac
# ╠═ba7e3059-a12a-4031-84c7-be0113c3a1dc
# ╠═7d955dc4-4ad3-4d0f-9e86-9c5595604ff4
# ╠═003440c7-cf98-4830-9648-ea7b7101683c
# ╟─820df928-69a0-4704-8c36-d46d73085318
# ╠═5f82a82b-10a5-4702-837a-fb4e2dcaff3f
# ╠═400fc0b0-3c0b-4bac-9575-4a969aa8b8fe
# ╠═bf73c955-243a-4969-b2f9-60a1116fd021
# ╠═a993d308-29a6-4933-9b6f-7d28a8db4d56
# ╠═1113967d-09fb-4645-8396-d5c1f9b30f51
# ╠═b6d3d6c5-9087-4878-a06c-42bc6f823ea9
# ╠═45500c96-acaa-43f5-90ea-b3aac8a9a46c
# ╠═9f8b24de-6f9f-4af1-b73e-8c6da073520a
# ╠═d17f533b-7b15-4c76-8a42-a723de409476
# ╠═d921bec2-b491-471f-9373-ae4cfbc7b210
