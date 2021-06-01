export UML

"""
Creates an UML diagram using [Mermaid.js](https://mermaid-js.github.io/mermaid/#/)

Diagrams are specified using Markdown code following the syntax described [here](https://mermaid-js.github.io/mermaid/#/).

Example:

    UML(\"\"\"
        graph LR
        A --- B
        B-->C[fa:fa-ban forbidden]
        B-->D(fa:fa-spinner)
        B-->E-->F---G
        \"\"\")
"""
struct UML
    code:: String
end

function show(io::IO, ::MIME"text/html", uml::UML)
    print(io, """
    <!DOCTYPE html>
    <body>
        <div class="mermaid">
            $(uml.code)
        </div>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@8.9.1/dist/mermaid.min.js"></script>
        <script>mermaid.initialize({startOnLoad:true});</script>
    </body>
    </html>
    """)
end
