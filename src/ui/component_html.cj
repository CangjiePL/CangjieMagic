package magic.ui

import std.regex.*
import std.collection.*

public class HTMLComponent {
    var css = ''
    var body = ''
    var script = ''

    public HTMLComponent(let template: String, public let index: Int64) {
        var cssParts = template.split("<style>")
        if (cssParts.size > 1) {
            let cssParts = cssParts[1].split("</style>")
            this.css += cssParts[0]
            this.css += "\n"
        }

        var bodyParts = template.split("<body>")
        if (bodyParts.size > 1) {
            bodyParts = bodyParts[1].split("<script>")
            if (bodyParts.size > 1) {
                let scriptParts = bodyParts[1].split("</script>")
                this.script += scriptParts[0]
                this.script += "\n"
                this.body += bodyParts[0]
                this.body += "\n"
            } else {
                bodyParts = bodyParts[0].split("</body>")
                this.body += bodyParts[0]
                this.body += "\n"
            }
        }
        css = css.replace("-{ num }", "_" + index.toString())
        body = body.replace("-{ num }", "_" + index.toString())
        script = script.replace("-{ num }", "_" + index.toString())
    }

    public func getCSS(): String {
        return css
    }

    public func getBody(): String {
        return body
    }

    public func getScript(): String {
        return script
    }
}

public enum HTMLayout {
    | Linear
    | Grid
    | Waterfall
}

public func mergeHTML(title: String,
                      components: ArrayList<HTMLComponent>,
                      layout!: HTMLayout = Linear): String {

    // 1. 公共 CSS —— 与布局无关的部分
    let commonCSS = """
    \n:root {
        --primary: hsl(220, 100%, 54%);
        --primary-dark: hsl(210, 100%, 30%);
        --primary-light: hsl(210, 100%, 95%);
        --secondary: hsl(156, 68%, 52%);
        --neutral: hsl(210, 17%, 95%);
        --neutral-dark: hsl(220, 13%, 18%);
        --gray-200: hsl(210, 16%, 93%);
        --gray-300: hsl(210, 14%, 89%);
        --gray-500: hsl(215, 10%, 44%);
        --gray-700: hsl(215, 16%, 27%);
        --red-500: hsl(0, 79%, 63%);
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
        font-family: 'Inter', sans-serif;
    }

    body {
        background-color: hsl(210, 17%, 98%);
        color: hsl(215, 28%, 17%);
    }

    h1 {
        text-align: center;
        color: hsl(0, 0%, 20%);
        margin-bottom: 30px;
    }

    h3 {
        font-size: 1.25rem;
        font-weight: 600;
        color: var(--neutral-dark);
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
    }

    h3 i {
        color: var(--primary);
        margin-right: 0.5rem;
    }

    h4 {
        font-size: 1.125rem;
        font-weight: 500;
        color: var(--neutral-dark);
        margin-bottom: 0.75rem;
    }

    .container {
        max-width: 384px;
        margin: 0 auto;
        padding: 1rem 1rem;
    }

    .card {
        background-color: white;
        border-radius: 0.75rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        transition: all 0.3s ease;
    }
    """

    // 2. 布局专属 CSS
    var currentIndex = 0
    let (extraCSS, containerCls, cardCls) = match (layout) {
        case Linear   => ("", "", "")
        case Waterfall => currentIndex = 1
        ("""
        .waterfall {
            column-count: 2;
            column-gap: 10px;
            column-fill: balance;
        }

        @media(min-width:768px) {
            .waterfall {
                column-count: 3;
            }
        }

        .water-card {
            break-inside: avoid;
            background: hsl(0, 0%, 100%);
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 10px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, .1);
        }
        """, "waterfall", "water-card")
        case Grid      => currentIndex = 2
        ("""
        .responsive-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 3px;
            width: 100%;
            padding: 0;
            min-width: 300px;
        }

        @media (max-width: 576px) {
            .responsive-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 8px;
                padding: 0;
            }
        }

        @media (min-width: 768px) {
            .responsive-grid {
                grid-template-columns: repeat(2, 1fr); // 仍保持2列等宽
                // 如需多列等宽，改为repeat(3, 1fr) / repeat(4, 1fr)
            }
        }

        .grid-card {
            border-radius: 8px;
            width: 100%;
            height: 100%;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        """, "responsive-grid", "grid-card")
    }

    // 3. 收集组件碎片
    let css  = StringBuilder(commonCSS + extraCSS)
    let body = StringBuilder()
    let script = StringBuilder()

    if (components.size > 1) {
        css.append('''
        .layout-toggle {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 100;
        }
        .layout-btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            background-color: hsl(217, 89%, 61%);
            color: hsl(0, 0%, 100%);
            cursor: pointer;
            transition: all 0.3s ease;
        }''')

        // body.append('''
        //     <div class="layout-toggle">
        //         <button class="layout-btn" id="layoutToggleBtn">切换布局</button>
        //     </div>
        // ''')

        script.append('''
        let currentIndex = ${currentIndex}
        const layouts = ['线性', '瀑布流', '网格']
        document.getElementById('layoutToggleBtn').addEventListener('click', function() {
            currentIndex = (currentIndex + 1) % layouts.length
            agentCallbackObject.sendMessageByUI(`切换为\${layouts[currentIndex]}布局`);
        });
        ''')
    }

    for (c in components) {
        css.append(c.getCSS())
        script.append(c.getScript())
        let fragment = c.getBody()
        if (cardCls.isEmpty()) { body.append(fragment) }
        else { body.append('<div class="${cardCls}">${fragment}</div>\n') }
    }
    if (body.size == 0) { return "" }

    let coreBody: String = if (containerCls.isEmpty()) {
        body.toString()
    } else {
        '<div class="${containerCls}">${body}</div>'
    }

    return """
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
      <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.min.js"></script>
      <style>${css}</style>
    </head>
    <body>
      ${coreBody}
      <script>${script}</script>
    </body>
    </html>
    """
}
