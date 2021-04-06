import Random: randstring
import Dates

export Slider, NumberField, Button, CheckBox, TextField, PasswordField, Select, MultiSelect, Radio, FilePicker, DateField, TimeField, ColorStringPicker

struct Slider
    vector::AbstractVector{<:Union{Real,AbstractString}}
    default::Union{Real,AbstractString}
    show_value::Bool
end

"""A Slider on the given vector.

## Examples
`@bind x Slider(1:10)`

`@bind x Slider(0.00 : 0.01 : 0.30; default=0.15, show_value=true)`

`@bind x Slider(["A","B","C","D"])`

"""
Slider(
    vector::AbstractVector{<:Union{Real,AbstractString}};
    default::Union{Missing,Real,AbstractString}=missing,
    show_value=false
) = Slider(vector, (default === missing) ? first(vector) : default, show_value)

function show(io::IO, ::MIME"text/html", slider::Slider)
    # Reindex to correspond to Javascript-like index
    indices = eachindex(slider.vector)
    defaultindex = findfirst(isequal(slider.default),slider.vector)
    defaultindex = defaultindex === nothing ? 0 : defaultindex - 1
    
    # Escape strings to be used in script
    parsedvector = slider.vector
    if parsedvector isa AbstractVector{<:AbstractString}
        parsedvector = ["\"$(replace(el, r"([\'\"])" => s"\\\1"))\"" for el in parsedvector]
    end
    
    # Output
    input = """<input 
        type="range" 
        min="0" 
        step="1" 
        max="$(length(indices)-1)" 
        value="$(defaultindex)"
        >"""
    output = slider.show_value ? "<output>$(slider.vector[indices[defaultindex+1]])</output>" : ""
    js = """
	<script>
		const slider = this.currentScript.parentElement
        const sInput = slider.querySelector("input")
        const sOutput = slider.querySelector("output")
        const showVal = sOutput !== null
        const values = [$(join(parsedvector,","))]
        sInput.oninput = (e) => {
            var index = sInput.valueAsNumber
            slider.value = values[index]
            if (showVal)
                sOutput.value = values[index]
            slider.dispatchEvent(new CustomEvent("input"))
            e && e.stopPropagation()
        }
        sInput.oninput()
	</script>
    """
    
    print(io, """<slider>$(input)$(output)$(js)</slider>""")
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


"""A text input (`<input type="text">`) - the user can type text, the text is returned as `String` via `@bind`.

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



"""A password input (`<input type="password">`) - the user can type text, the text is returned as `String` via `@bind`.

This does not provide any special security measures, it just renders black dots (•••) instead of the typed characters.

Use `default` to set the initial value.

See the [Mozilla docs about `<input type="password">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/password)

# Examples
`@bind secret_poem PasswordField()`

`@bind secret_poem PasswordField(default="Te dansen omdat men leeft")`"""
Base.@kwdef struct PasswordField
    default::AbstractString=""
end

function show(io::IO, ::MIME"text/html", passwordfield::PasswordField)
    print(io, """<input type="password" value="$(htmlesc(passwordfield.default))">""")
end

get(passwordfield::PasswordField) = passwordfield.default


"""A dropdown menu (`<select>`) - the user can choose one of the `options`, an array of `String`s.

See [`MultiSelect`](@ref) for a version that allows multiple selected items.

`options` can also be an array of pairs `key::String => value::Any`. The `key` is returned via `@bind`; the `value` is shown.

See the [Mozilla docs about `select`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select)

# Examples
`@bind veg Select(["potato", "carrot"])`

`@bind veg Select(["potato" => "🥔", "carrot" => "🥕"])`

`@bind veg Select(["potato" => "🥔", "carrot" => "🥕"], default="carrot")`"""
struct Select
    options::Vector{Pair{<:AbstractString,<:Any}}
    default::Union{Missing, AbstractString}
end
Select(options::AbstractVector{<:AbstractString}; default=missing) = Select([o => o for o in options], default)
Select(options::AbstractVector{<:Pair{<:AbstractString,<:Any}}; default=missing) = Select(options, default)

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
    options::Vector{Pair{<:AbstractString,<:Any}}
    default::Union{Missing, AbstractVector{AbstractString}}
end
MultiSelect(options::AbstractVector{<:AbstractString}; default=missing) = MultiSelect([o => o for o in options], default)
MultiSelect(options::AbstractVector{<:Pair{<:AbstractString,<:Any}}; default=missing) = MultiSelect(options, default)

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

get(select::FilePicker) = Dict("name" => "", "data" => UInt8[], "type" => "")

"""A group of radio buttons - the user can choose one of the `options`, an array of `String`s. 

`options` can also be an array of pairs `key::String => value::Any`. The `key` is returned via `@bind`; the `value` is shown.


# Examples
`@bind veg Radio(["potato", "carrot"])`

`@bind veg Radio(["potato" => "🥔", "carrot" => "🥕"])`

`@bind veg Radio(["potato" => "🥔", "carrot" => "🥕"], default="carrot")`

"""
struct Radio
    options::Vector{Pair{<:AbstractString,<:Any}}
    default::Union{Missing, AbstractString}
end
Radio(options::AbstractVector{<:AbstractString}; default=missing) = Radio([o => o for o in options], default)
Radio(options::AbstractVector{<:Pair{<:AbstractString,<:Any}}; default=missing) = Radio(options, default)

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
        const form = document.querySelector('#$(groupname)')

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

"""A date input (`<input type="date">`) - the user can pick a date, the date is returned as `Dates.DateTime` via `@bind`.

Use `default` to set the initial value.

See the [Mozilla docs about `<input type="date">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/date)

# Examples
`@bind best_day_of_my_live DateField()`

`@bind best_day_of_my_live DateField(default=today())`"""
Base.@kwdef struct DateField
    default::Union{Dates.TimeType,Missing}=missing
end

function show(io::IO, ::MIME"text/html", datefield::DateField)
    withtag(() -> (), io, :input, :type=>"date", :value=>datefield.default === missing ? "" : Dates.format(datefield.default, "Y-mm-dd"))
end
get(datefield::DateField) = datefield.default


"""A time input (`<input type="time">`) - the user can pick a time, the time is returned as `Dates.DateTime` via `@bind`.

Use `default` to set the initial value.

See the [Mozilla docs about `<input type="time">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/time)

# Examples
`@bind lunch_time TimeField()`

`@bind lunch_time TimeField(default=now())`"""
Base.@kwdef struct TimeField
    default::Union{Dates.TimeType,Missing}=missing
end

function show(io::IO, ::MIME"text/html", timefield::TimeField)
    withtag(() -> (), io, :input, :type=>"time", :value=>timefield.default === missing ? "" : Dates.format(timefield.default, "HH:MM:SS"))
end
get(timefield::TimeField) = timefield.default


"""A color input (`<input type="color">`) - the user can pick an RGB color, the color is returned as color hex `String` via `@bind`. The value is lowercase and starts with `#`.

Use `default` to set the initial value.

See the [Mozilla docs about `<input type="color">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/color)

# Examples
`@bind color ColorStringPicker()`

`@bind color ColorStringPicker(default="#aabbcc")`
"""
Base.@kwdef struct ColorStringPicker
    default::String="#000000"
end

function show(io::IO, ::MIME"text/html", colorStringPicker::ColorStringPicker)
    withtag(() -> (), io, :input, :type=>"color", :value=>colorStringPicker.default)
end
get(colorStringPicker::ColorStringPicker) = colorStringPicker.default
