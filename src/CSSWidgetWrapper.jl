export CSSWidgetWrapper

"""
    CSSWidgetWrapper(widget, style::Dict{String,String})

Modify the style properties of the first HTML node for the given widget. 

# Examples
Generate a text field with a red background and white text.
```
@bind text CSSWidgetWrapper(TextField(),Dict("backgroundColor"=>"red","color"=>"white"))
```
Generate a text field with 1px wide solid red border.
```
@bind text CSSWidgetWrapper(TextField(),Dict("border"=>"1px solid red"))
```
"""
struct CSSWidgetWrapper
    widget
    style::Dict{String,String}
end

function show(io::IO, m::MIME"text/html", w::CSSWidgetWrapper)
    style = join(["widget.style.$k = '$v';" for (k,v) in w.style],"\n")
    script = """
        <script>
        var widget = currentScript.parentElement.firstElementChild
        $style    
        </script>
    """
    show(io,m,w.widget)
    print(io,script)
end

Base.get(w::CSSWidgetWrapper) = get(w.widget)
