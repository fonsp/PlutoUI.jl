module PlutoUI

import Base: show, get
import Markdown: htmlesc, withtag

using Reexport

const PKG_ROOT_DIR = normpath(joinpath(@__DIR__, ".."))

include("./Builtins.jl")
include("./Resource.jl")
include("./Terminal.jl")
include("./RangeSlider.jl")
include("./DisplayTricks.jl")

@reexport module MultiCheckBoxNotebook
    include("./MultiCheckBox.jl")
end
@reexport module TableOfContentsNotebook
    include("./TableOfContents.jl")
end
@reexport module SidebarNotebook
    include("./Sidebar.jl")
end
@reexport module ClockNotebook
    include("./Clock.jl")
end
@reexport module ScrubbableNotebook
    include("./Scrubbable.jl")
end

end
