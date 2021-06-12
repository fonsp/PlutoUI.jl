import Base64
import Markdown

export Resource, RemoteResource, LocalResource, DownloadButton

"""
    Resource(src::String, mime=mime_from_filename(src)[, html_attributes::Pair...])

A container for a URL-addressed resource that displays correctly in rich IDEs.

# Examples
```
Resource("https://julialang.org/assets/infra/logo.svg")
```

```
Resource("https://interactive-examples.mdn.mozilla.net/media/examples/flower.webm", :width => 100)
```

```
md\"\"\"
This is what a duck sounds like: \$(Resource("https://interactive-examples.mdn.mozilla.net/media/examples/t-rex-roar.mp3"))
md\"\"\"
```

"""
struct Resource
    src::AbstractString
    mime::Union{Nothing,MIME}
    html_attributes::NTuple{N,Pair} where N
end
Resource(src::AbstractString, html_attributes::Pair...) = Resource(src, mime_fromfilename(src), html_attributes)

function Base.show(io::IO, ::MIME"text/html", r::Resource)
    tag = if r.mime ∈ imagemimes
        :img
    elseif r.mime isa MIME"text/javascript"
        :script
    elseif r.mime ∈ audiomimes
        :audio
    elseif r.mime ∈ videomimes
        :video
    else
        :data
    end
    type_attr = r.mime isa MIME ? [:type => string(r.mime)] : []
    
    Markdown.withtag(() -> (), io, tag, :src => r.src, :controls => "", type_attr..., (k => string(v) for (k, v) in r.html_attributes)...)
end


RemoteResource = Resource

"""
Create a `Resource` for a local file (a base64 encoded data URL is generated).

# WARNING
`LocalResource` **will not work** when you share the script/notebook with someone else, _unless they have those resources at exactly the same location on their file system_. 

## Recommended alternatives (images)
1. Go to [imgur.com](https://imgur.com) and drag&drop the image to the page. Right click on the image, and select "Copy image location". You can now use the image like so: `PlutoUI.Resource("https://i.imgur.com/SAzsMMA.jpg")`.
2. If your notebook is part of a git repository, place the image in the repository and use a relative path: `PlutoUI.LocalResource("../images/cat.jpg")`.

# Examples
```
LocalResource("./cat.jpg")
```

```
LocalResource("/home/fons/Videos/nijmegen.mp4", :width => 200)
```

```
md\"\"\"
This is what a duck sounds like: \$(LocalResource("../data/hannes.mp3"))
md\"\"\"
```
"""
function LocalResource(path::AbstractString, html_attributes::Pair...)
    @warn """`LocalResource` **will not work** when you share the script/notebook with someone else, _unless they have those resources at exactly the same location on their file system_. 

    ## Recommended alternatives (images)
    1. Go to [imgur.com](https://imgur.com) and drag&drop the image to the page. Right click on the image, and select "Copy image location". You can now use the image like so: `PlutoUI.Resource("https://i.imgur.com/SAzsMMA.jpg")`.
    2. If your notebook is part of a git repository, place the image in the repository and use a relative path: `PlutoUI.LocalResource("../images/cat.jpg")`."""
    mime = mime_fromfilename(path; default="")
    src = join([
		"data:", 
		string(mime),
		";base64,", 
		Base64.base64encode(read(path))
	])
	Resource(src, mime, html_attributes)
end

###
# DOWNLOAD BUTTON
###

"""
Button to download a Julia object as a file from the browser.

See [`FilePicker`](@ref) to do the opposite.

# Examples

```julia
DownloadButton("Roses are red,", "novel.txt")
```
```julia
DownloadButton(UInt8[0xff, 0xd8, 0xff, 0xe1, 0x00, 0x69], "raw.dat")
```
```julia
import JSON
DownloadButton(JSON.json(Dict("name" => "merlijn", "can_cook" => true)), "staff.json")
```

If you want to make a **local file** available for download, you need to `read` the file's data:
```julia
let
    filename = "/Users/fonsi/Documents/mydata.csv"
    DownloadButton(read(filename), basename(filename))
end
```

"""
struct DownloadButton
    data
    filename::AbstractString
end
DownloadButton(data) = DownloadButton(data, "result")


function Base.show(io::IO, m::MIME"text/html", db::DownloadButton)
	write(io, "<a href=\"data:")
	write(io, string(mime_fromfilename(db.filename, default="")))
	write(io, ";base64,")
	write(io, Base64.base64encode(db.data))
	write(io, "\" download=\"")
	write(io, Markdown.htmlesc(db.filename))
	write(io, "\" style=\"text-decoration: none; font-weight: normal; font-size: .75em; font-family: sans-serif;\"><button>Download...</button> ")
	write(io, db.filename)
	write(io, "</a>")
end

###
# MIMES
###

"Attempt to find the MIME pair corresponding to the extension of a filename. Defaults to `text/plain`."
function mime_fromfilename(filename; default=nothing, filename_maxlength=2000)
	if length(filename) > filename_maxlength
		default
    else
		get(mimepairs, '.' * split(split(split(filename, '?')[1], '#')[1], '.')[end], default)
	end
end

const mimepairs = let
	# This bad boy is from: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
	originals = Dict(".aac" => "audio/aac", ".bin" => "application/octet-stream", ".bmp" => "image/bmp", ".css" => "text/css", ".csv" => "text/csv", ".eot" => "application/vnd.ms-fontobject", ".gz" => "application/gzip", ".gif" => "image/gif", ".htm" => "text/html", ".html" => "text/html", ".ico" => "image/vnd.microsoft.icon", ".jpeg" => "image/jpeg", ".jpg" => "image/jpeg", ".js" => "text/javascript", ".json" => "application/json", ".jsonld" => "application/ld+json", ".mjs" => "text/javascript", ".mp3" => "audio/mpeg", ".mpeg" => "video/mpeg", ".mp4" => "video/mp4", ".oga" => "audio/ogg", ".ogg" => "audio/ogg", ".ogv" => "video/ogg", ".ogx" => "application/ogg", ".opus" => "audio/opus", ".otf" => "font/otf", ".png" => "image/png", ".pdf" => "application/pdf", ".rtf" => "application/rtf", ".sh" => "application/x-sh", ".svg" => "image/svg+xml", ".tar" => "application/x-tar", ".tif" => "image/tiff", ".tiff" => "image/tiff", ".ttf" => "font/ttf", ".txt" => "text/plain", ".wav" => "audio/wav", ".weba" => "audio/webm", ".webm" => "video/webm", ".webp" => "image/webp", ".woff" => "font/woff", ".woff2" => "font/woff2", ".xhtml" => "application/xhtml+xml", ".xml" => "application/xml", ".xul" => "application/vnd.mozilla.xul+xml", ".zip" => "application/zip")
	Dict((k => MIME(v)) for (k, v) in originals)
end

const imagemimes = [MIME"image/svg+xml"(), MIME"image/png"(), MIME"image/webp"(), MIME"image/tiff"(), MIME"image/jpg"(), MIME"image/jpeg"(), MIME"image/bmp"(), MIME"image/gif"()]
const audiomimes = [MIME"audio/mpeg"(), MIME"audio/wav"(), MIME"audio/aac"(), MIME"audio/ogg"(), MIME"audio/opus"(), MIME"audio/webm"()]
const videomimes = [MIME"video/mpeg"(), MIME"video/ogg"(), MIME"video/webm"(), MIME"video/mp4"()]

