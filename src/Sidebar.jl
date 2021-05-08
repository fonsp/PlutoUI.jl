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

# ╔═╡ 6bb52c7c-9031-426b-9061-b9bebc213089
using Markdown: withtag

# ╔═╡ 40118f5c-d059-4f9f-9ed2-04cd99b92675
md"""
# Sidebar

You can add anything to the sidebar:
"""

# ╔═╡ 153b0efb-dc67-47bc-8f13-13e2ffe2dac5


# ╔═╡ 583fcd1b-bd5d-45fa-b0b7-db234cfd281d
md"""
## Implementation
"""

# ╔═╡ 1bdea858-cbe1-4a69-abf3-322ec8bdfb25
begin
	struct SidebarItem{T}
		item::T
	end
	function Base.show(io::IO, m::MIME"text/html", si::SidebarItem)
		withtag(io, :div, :class => "sidebar-item") do
			show(io, m, si.item)
		end
	end
end

# ╔═╡ 749bdfb0-fcc3-4cab-b17e-45f66835cd84
const sidebar_js = sidebar -> """
const getParentCell = el => el.closest("pluto-cell")

// Get all items not yet in sidebar (new items)
const getItems = () => {
	const selector = "pluto-notebook pluto-cell .sidebar-item:not(.sidebar-placed)"
	return Array.from(document.querySelectorAll(selector))
}

const render = (el) => html`\${el.map(h => {
	// TODO: highlight parentCell on hover

	h.classList.add("sidebar-placed")
	return html`<div class="sidebar-row">\${h}</div>`
})}`

const sidebarNode = html`<aside class="plutoui-sidebar">
	<div></div>
</aside>`

// Dictionary relating sidebar items (nodes) and cell ids
const sidebarItems = {
	current: {},
}

const updateCallback = () => {
	// Update our dictionary of items
	getItems().forEach((h) => {
		const parent_cell = getParentCell(h)
		sidebarItems.current[parent_cell.id] = h
	})
	console.log(sidebarItems)

	let items = render(Object.keys(sidebarItems.current).map((key) => {
		return sidebarItems.current[key]
	}))
	sidebarNode.querySelector("div").replaceWith(
		html`<div>\${items}</div>`
	)
}
updateCallback()

const notebook = document.querySelector("pluto-notebook")

// We have a MutationObserver for each cell:
const observers = {
	current: [],
}

const createCellObservers = () => {
	observers.current.forEach((o) => o.disconnect())
	observers.current = Array.from(notebook.querySelectorAll("pluto-cell")).map(el => {
		const o = new MutationObserver(updateCallback)
		o.observe(el, {attributeFilter: ["class"]})
		return o
	})
}
createCellObservers()

// An observer for the notebook's child list, which updates our cell observers:
const notebookObserver = new MutationObserver(() => {
	updateCallback()
	createCellObservers()
})
notebookObserver.observe(notebook, {childList: true})

// And finally, an observer for the document.body classList, to make sure that the
// sidebar also works when it is loaded during notebook initialization.
const bodyClassObserver = new MutationObserver(updateCallback)
bodyClassObserver.observe(document.body, {attributeFilter: ["class"]})

invalidation.then(() => {
	notebookObserver.disconnect()
	bodyClassObserver.disconnect()
	observers.current.forEach((o) => o.disconnect())
})

return sidebarNode
"""

# ╔═╡ 0f02965c-e014-4d18-aef5-e34d39b78682
const sidebar_css = """
@media screen and (min-width: 1666px) {
	.plutoui-sidebar {
		position:fixed;
		left: 1rem;
		top: 5rem;
		width:25%;
		padding: 10px;
		border: 3px solid rgba(0, 0, 0, 0.15);
		border-radius: 10px;
		box-shadow: 0 0 11px 0px #00000010;
		/* That is, viewport minus top minus Live Docs */
		max-height: calc(100vh - 5rem - 56px);
		overflow: auto;
		z-index: 50;
		background: white;
	}
}

.plutoui-sidebar div .sidebar-row {
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	padding-bottom: 2px;
}

.highlight-pluto-cell-shoulder {
	background: rgba(0, 0, 0, 0.05);
	background-clip: padding-box;
}
"""

# ╔═╡ 8d79a95f-2290-4578-a58b-c92ab11e7ae3
begin
	"""Generate a sidebar for declared content.

	# Examples:

	```julia
	Sidebar()
	```
	"""
	struct Sidebar end
	push!(::Sidebar, x) = SidebarItem(x)  # TODO: is this what we want?
	function Base.show(io::IO, ::MIME"text/html", sidebar::Sidebar)
		withtag(io, :script) do
			print(io, sidebar_js(sidebar))
		end
		withtag(io, :style) do
			print(io, sidebar_css)
		end
	end
end

# ╔═╡ c2a0ffb4-b015-11eb-0d96-638ad55db44e
export Sidebar

# ╔═╡ 2eac0c69-bac7-4d0f-9b89-b2071fc34f6a
sidebar = Sidebar()

# ╔═╡ 7f5f38c6-adf6-43c4-b23f-782455a8815a
push!(
	sidebar,
	md"""
	# My awesome sidebar

	You can add anything to the sidebar.
	"""
)

# ╔═╡ d6031502-e581-45b0-8c8d-ed4937b62a7b
push!(sidebar, md"Type your name: $(@bind x html\"<input value=\\\"hello world\\\">\")")

# ╔═╡ 89bdecb6-035c-4974-9d32-b510b9e7a818
x

# ╔═╡ eb56e390-3b6f-462f-a01e-1e0ba0f64c75
push!(sidebar, @bind checked html"<input type=\"checkbox\">")

# ╔═╡ 37916f4c-bfdd-4a92-ab03-5c574ec8d41f
checked

# ╔═╡ Cell order:
# ╠═c2a0ffb4-b015-11eb-0d96-638ad55db44e
# ╠═6bb52c7c-9031-426b-9061-b9bebc213089
# ╠═2eac0c69-bac7-4d0f-9b89-b2071fc34f6a
# ╠═89bdecb6-035c-4974-9d32-b510b9e7a818
# ╟─40118f5c-d059-4f9f-9ed2-04cd99b92675
# ╠═7f5f38c6-adf6-43c4-b23f-782455a8815a
# ╠═d6031502-e581-45b0-8c8d-ed4937b62a7b
# ╠═eb56e390-3b6f-462f-a01e-1e0ba0f64c75
# ╠═37916f4c-bfdd-4a92-ab03-5c574ec8d41f
# ╠═153b0efb-dc67-47bc-8f13-13e2ffe2dac5
# ╟─583fcd1b-bd5d-45fa-b0b7-db234cfd281d
# ╠═8d79a95f-2290-4578-a58b-c92ab11e7ae3
# ╠═1bdea858-cbe1-4a69-abf3-322ec8bdfb25
# ╠═749bdfb0-fcc3-4cab-b17e-45f66835cd84
# ╠═0f02965c-e014-4d18-aef5-e34d39b78682
