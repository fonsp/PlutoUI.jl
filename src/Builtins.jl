import Random: randstring

export Slider, NumberField, Button, CheckBox, TextField, Select, MultiSelect, Radio, FilePicker

struct Slider
    range::AbstractRange
    default::Number
    show_value::Bool
end

"""A Slider on the given `range`.

## Examples
`@bind x Slider(1:10)`

`@bind x Slider(0.00 : 0.01 : 0.30)`

`@bind x Slider(1:10; default=8, show_value=true)`

"""
Slider(range::AbstractRange; default=missing, show_value=false) = Slider(range, (default === missing) ? first(range) : default, show_value)

function show(io::IO, ::MIME"text/html", slider::Slider)
    print(io, """<input 
        type="range" 
        min="$(first(slider.range))" 
        step="$(step(slider.range))" 
        max="$(last(slider.range))" 
        value="$(slider.default)"
        $(slider.show_value ? "oninput=\"this.nextElementSibling.value=this.value\"" : "")
        >""")
    
    if slider.show_value
        print(io, """<output>$(slider.default)</output>""")
    end
end

get(slider::Slider) = slider.default

"""A box where you can type in a number, within a specific range.

## Examples
`@bind x NumberField(1:10)`

`@bind x NumberField(0.00 : 0.01 : 0.30)`

`@bind x NumberField(1:10; default=8)`

"""
struct NumberField
    range::AbstractRange
    default::Number
end

NumberField(range::AbstractRange; default=missing) = NumberField(range, (default === missing) ? first(range) : default)

function show(io::IO, ::MIME"text/html", numberfield::NumberField)
    print(io, """<input type="number" min="$(first(numberfield.range))" step="$(step(numberfield.range))" max="$(last(numberfield.range))" value="$(numberfield.default)">""")
end

get(numberfield::NumberField) = numberfield.default


"""A button that sends back the same value every time that it is clicked.

You can use it to _trigger reactive cells_.

## Examples

In one cell:

```julia
@bind go Button("Go!")
```

and in a second cell:

```julia
begin
    # reference the bound variable - clicking the button will run this cell
    go

    md"My favorite number is $(rand())!"
end
```
"""
struct Button
    label::AbstractString
end
Button() = Button("Click")

function show(io::IO, ::MIME"text/html", button::Button)
    print(io, """<input type="button" value="$(htmlesc(button.label))">""")
end

get(button::Button) = button.label


"""A checkbox to choose a Boolean value `true`/`false`.

## Examples

`@bind programming_is_fun CheckBox()`

`@bind julia_is_fun CheckBox(default=true)`

`md"Would you like the thing? \$(@bind enable_thing CheckBox())"`
"""
struct CheckBox
    default::Bool
end

CheckBox(;default::Bool=false) = CheckBox(default)

function show(io::IO, ::MIME"text/html", button::CheckBox)
    print(io, """<input type="checkbox"$(button.default ? " checked" : "")>""")
end

get(checkbox::CheckBox) = checkbox.default


"""A text input (`<input type="text">`) - the user can type text, the text is return as `String` via `@bind`.

If `dims` is a tuple `(cols::Integer, row::Integer)`, a `<textarea>` will be shown, with the given dimensions

Use `default` to set the initial value.

See the [Mozilla docs about `<input type="text">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/text) and [`<textarea>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea)

# Examples
`@bind poem TextField()`

`@bind poem TextField((30,5); default="Hello\nJuliaCon!")`"""
struct TextField
    dims::Union{Tuple{Integer,Integer},Nothing}
    default::AbstractString
end
TextField(dims::Union{Tuple{Integer,Integer},Nothing}=nothing; default::AbstractString="") = TextField(dims, default)

function show(io::IO, ::MIME"text/html", textfield::TextField)
    if textfield.dims === nothing
        print(io, """<input type="text" value="$(htmlesc(textfield.default))">""")
    else
        print(io, """<textarea cols="$(textfield.dims[1])" rows="$(textfield.dims[2])">$(htmlesc(textfield.default))</textarea>""")
    end
end

get(textfield::TextField) = textfield.default

"""A dropdown menu (`<select>`) - the user can choose one of the `options`, an array of `String`s.

See [`MultiSelect`](@ref) for a version that allows multiple selected items.

`options` can also be an array of pairs `key::String => value::Any`. The `key` is returned via `@bind`; the `value` is shown.

See the [Mozilla docs about `select`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select)

# Examples
`@bind veg Select(["potato", "carrot"])`

`@bind veg Select(["potato" => "🥔", "carrot" => "🥕"])`

`@bind veg Select(["potato" => "🥔", "carrot" => "🥕"], default="carrot")`"""
struct Select
    options::Array{Pair{<:AbstractString,<:Any},1}
    default::Union{Missing, AbstractString}
end
Select(options::Array{<:AbstractString,1}; default=missing) = Select([o => o for o in options], default)
Select(options::Array{<:Pair{<:AbstractString,<:Any},1}; default=missing) = Select(options, default)

function show(io::IO, ::MIME"text/html", select::Select)
    withtag(io, :select) do
        for o in select.options
            print(io, """<option value="$(htmlesc(o.first))"$(select.default === o.first ? " selected" : "")>""")
            if showable(MIME"text/html"(), o.second)
                show(io, MIME"text/html"(), o.second)
            else
                print(io, o.second)
            end
            print(io, "</option>")
        end
    end
end

get(select::Select) = ismissing(select.default) ? first(select.options).first : select.default


"""A multi-selector (`<select multi>`) - the user can choose one or more of the `options`, an array of `Strings.

See [`Select`](@ref) for a version that allows only one selected item.

`options` can also be an array of pairs `key::String => value::Any`. The `key` is returned via `@bind`; the `value` is shown.

See the [Mozilla docs about `select`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select)

# Examples
`@bind veg MultiSelect(["potato", "carrot"])`

`@bind veg MultiSelect(["potato" => "🥔", "carrot" => "🥕"])`

`@bind veg MultiSelect(["potato" => "🥔", "carrot" => "🥕"], default=["carrot"])`"""
struct MultiSelect
    options::Array{Pair{<:AbstractString,<:Any},1}
    default::Union{Missing, AbstractVector{AbstractString}}
end
MultiSelect(options::Array{<:AbstractString,1}; default=missing) = MultiSelect([o => o for o in options], default)
MultiSelect(options::Array{<:Pair{<:AbstractString,<:Any},1}; default=missing) = MultiSelect(options, default)

function show(io::IO, ::MIME"text/html", select::MultiSelect)
    withtag(io, Symbol("select multiple")) do
        for o in select.options
            print(io, """<option value="$(htmlesc(o.first))"$(!ismissing(select.default) && o.first ∈ select.default ? " selected" : "")>""")
            if showable(MIME"text/html"(), o.second)
                show(io, MIME"text/html"(), o.second)
            else
                print(io, o.second)
            end
            print(io, "</option>")
        end
    end
end

get(select::MultiSelect) = ismissing(select.default) ? Any[] : select.default

"""A file upload box. The chosen file will be read by the browser, and the bytes are sent back to Julia.

The optional `accept` argument can be an array of `MIME`s. The user can only select files with these MIME. If only `image/*` MIMEs are allowed, then smartphone browsers will open the camera instead of a file browser.

## Examples

`@bind file_data FilePicker()`

`file_data["data"]`

You can limit the allowed MIME types:

```julia
@bind image_data FilePicker([MIME("image/jpg"), MIME("image/png")])
# and use MIME groups:
@bind image_data FilePicker([MIME("image/*")])
```
"""
struct FilePicker
    accept::Array{MIME,1}
end
FilePicker() = FilePicker(MIME[])

function show(io::IO, ::MIME"text/html", filepicker::FilePicker)
    print(io, """<input type='file' accept='""")
    join(io, string.(filepicker.accept), ",")
    print(io, "'>")
end

get(select::FilePicker) = Dict("name" => "", "data" => [], "type" => "")

"""A group of radio buttons - the user can choose one of the `options`, an array of `String`s. 

`options` can also be an array of pairs `key::String => value::Any`. The `key` is returned via `@bind`; the `value` is shown.


# Examples
`@bind veg Radio(["potato", "carrot"])`

`@bind veg Radio(["potato" => "🥔", "carrot" => "🥕"])`

`@bind veg Radio(["potato" => "🥔", "carrot" => "🥕"], default="carrot")`

"""
struct Radio
    options::Array{Pair{<:AbstractString,<:Any},1}
    default::Union{Missing, AbstractString}
end
Radio(options::Array{<:AbstractString,1}; default=missing) = Radio([o => o for o in options], default)
Radio(options::Array{<:Pair{<:AbstractString,<:Any},1}; default=missing) = Radio(options, default)

function show(io::IO, ::MIME"text/html", radio::Radio)
    groupname = randstring('a':'z')
    withtag(io, :form, :id=>groupname) do
        for o in radio.options
            withtag(io, :div) do
                print(io, """<input type="radio" id="$(htmlesc(groupname * o.first))" name="$(groupname)" value="$(htmlesc(o.first))"$(radio.default === o.first ? " checked" : "")>""")

                withtag(io, :label, :for=>(groupname * o.first)) do
                    if showable(MIME"text/html"(), o.second)
                        show(io, MIME"text/html"(), o.second)
                    else
                        print(io, o.second)
                    end
                end
            end
        end
    end
    withtag(io, :script) do
        print(io, """
        const form = this.querySelector('#$(groupname)')

        form.oninput = (e) => {
            form.value = e.target.value
            // and bubble upwards
        }

        // set initial value:
        const selected_radio = form.querySelector('input[checked]')
        if(selected_radio != null){
            form.value = selected_radio.value
        }
        """)
    end
end

get(radio::Radio) = radio.default


"""Generate Table of Contents using Markdown cells. Headers h1-h6 are used. 

`title` is the custom Title header to this element. 
`indent` aligns header elements in a heirarchy.

# Examples
`@bind TableOfContents()`

`@bind TableOfContents(indent=True)`

`@bind TableOfContents(title="Table of Contents")`

"""
struct TableOfContents
    title::AbstractString
    indent::Bool
end
TableOfContents(;title::AbstractString="", indent::Bool=false) = TableOfContents(title, indent)

function show(io::IO, ::MIME"text/html", toc::TableOfContents)

    if length(toc.title) > 0
        print(io, """<div class="title">$(toc.title)</div>""")
    end

    withtag(io, :script) do
        print(io, """
            const elementsOfType = (type) => Array.from(
                document.querySelectorAll(
                    "pluto-notebook pluto-output " + type
                )
            ).map(el => {
                const parentCellId = function(el) {
                    while (el.nodeName != 'PLUTO-CELL') {
                        el = el.parentNode;
                        if (!el) return null;
                    }
                    return el.id;
                }            
                return {
                    "el": el,
                    "parentCellId": parentCellId(el)
                }
            })
            
            const plutoCellIds = Array.from(
                document.querySelectorAll(
                    "pluto-notebook pluto-cell"
                )
            ).map(el => el.id)
            
            const headers = [...elementsOfType("h1"), ...elementsOfType("h2"),...elementsOfType("h3"),...elementsOfType("h4"), ...elementsOfType("h5"),...elementsOfType("h6")] 
            headers.sort((a,b) => plutoCellIds.indexOf(a.parentCellId)-plutoCellIds.indexOf(b.parentCellId))

            return html`\${headers.map(h => html`<div><a class="\${h.el.nodeName}" href="#\${h.parentCellId}">\${h.el.innerText}</a></div>`)}`
        """)
    end

    withtag(io, :style) do        
        print(io, """
            a {
                text-decoration: none;
            }
            .title{
                display: block;
                font-size: 2em;
                margin-top: 0.67em;
                margin-bottom: 0.67em;
                margin-left: 0;
                margin-right: 0;
                font-weight: bold;
            }
            """)

        if toc.indent 
            print(io, """
                .H1 {
                    padding: 0px 0px;
                }
                .H2 {
                    padding: 0px 10px;
                }
                .H3 {
                    padding: 0px 20px;
                }
                .H4 {
                    padding: 0px 30px;
                }
                .H5 {
                    padding: 0px 40px;
                }
                .H6 {
                    padding: 0px 50px;
                }"""        
            )
        end
    end
end

get(toc::TableOfContents) = toc.default
