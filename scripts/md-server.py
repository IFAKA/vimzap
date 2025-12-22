#!/usr/bin/env python3
"""
Simple markdown file server for VimZap
Serves a single markdown file on local network with rendered HTML view
"""

import http.server
import socketserver
import sys
import os
import json
import socket
from urllib.parse import unquote

class MarkdownHandler(http.server.SimpleHTTPRequestHandler):
    md_file_path = ""
    cached_html = None
    cached_mtime = None
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    
    def log_message(self, format, *args):
        # Suppress server logs
        pass
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.end_headers()
            
            # Check if we can use cached HTML
            try:
                current_mtime = os.path.getmtime(MarkdownHandler.md_file_path)
                if (MarkdownHandler.cached_html and 
                    MarkdownHandler.cached_mtime == current_mtime):
                    # Use cached version
                    self.wfile.write(MarkdownHandler.cached_html)
                    return
            except:
                pass
            
            # Read markdown file
            try:
                with open(MarkdownHandler.md_file_path, 'r', encoding='utf-8') as f:
                    md_content = f.read()
                current_mtime = os.path.getmtime(MarkdownHandler.md_file_path)
            except Exception as e:
                md_content = f"# Error\n\nCould not read file: {str(e)}"
                current_mtime = 0
            
            # Escape for JSON
            md_json = json.dumps(md_content)
            filename = os.path.basename(MarkdownHandler.md_file_path)
            
            html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{filename}</title>
    <script src="https://cdn.jsdelivr.net/npm/marked@11.1.1/marked.min.js"></script>
    <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css">
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #e6edf3;
            background: #0d1117;
        }}
        
        /* Navbar Styles */
        #navbar {{
            position: sticky;
            top: 0;
            background: #161b22;
            border-bottom: 1px solid #21262d;
            padding: 12px 20px;
            z-index: 1000;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .navbar-title {{
            color: #f0f6fc;
            font-size: 14px;
            font-weight: 600;
            font-family: monospace;
            flex: 1;
        }}
        #toc-toggle {{
            background: transparent;
            color: #8b949e;
            border: none;
            padding: 4px;
            cursor: pointer;
            font-size: 24px;
            line-height: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: color 0.2s;
        }}
        #toc-toggle:hover {{
            color: #f0f6fc;
        }}
        #toc-toggle:active {{
            color: #58a6ff;
        }}
        
        /* TOC Dropdown */
        #toc-dropdown {{
            position: sticky;
            top: 49px;
            background: #161b22;
            border-bottom: 1px solid #21262d;
            z-index: 999;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease;
        }}
        #toc-dropdown.show {{
            max-height: 60vh;
            overflow-y: auto;
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
        }}
        #toc-content {{
            padding: 12px 20px;
        }}
        #toc-content ul {{
            list-style: none;
            padding-left: 0;
        }}
        #toc-content li {{
            margin: 4px 0;
        }}
        #toc-content a {{
            color: #58a6ff;
            text-decoration: none;
            display: block;
            padding: 4px 8px;
            border-radius: 4px;
        }}
        #toc-content a:hover {{
            background: #21262d;
        }}
        #toc-content .toc-h1 {{ padding-left: 0; font-weight: 600; }}
        #toc-content .toc-h2 {{ padding-left: 16px; }}
        #toc-content .toc-h3 {{ padding-left: 32px; font-size: 0.9em; }}
        
        /* Content Styles */
        #content {{
            background: #161b22;
            max-width: 900px;
            margin: 0 auto;
        }}
        #markdown {{
            padding: 20px;
        }}
        h1, h2, h3, h4, h5, h6 {{
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
            color: #f0f6fc;
            scroll-margin-top: 80px;
        }}
        h1 {{
            font-size: 2em;
            border-bottom: 1px solid #21262d;
            padding-bottom: 0.3em;
        }}
        h2 {{
            font-size: 1.5em;
            border-bottom: 1px solid #21262d;
            padding-bottom: 0.3em;
        }}
        p {{
            margin-bottom: 16px;
        }}
        code {{
            background: #0d1117;
            padding: 3px 6px;
            border-radius: 6px;
            font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;
            font-size: 0.9em;
        }}
        
        /* Code Block with Copy Button */
        .code-wrapper {{
            position: relative;
            margin-bottom: 16px;
        }}
        .code-wrapper pre {{
            background: #0d1117;
            padding: 16px;
            padding-top: 40px;
            border-radius: 6px;
            overflow-x: auto;
            margin: 0;
        }}
        .code-wrapper pre code {{
            background: none;
            padding: 0;
        }}
        .copy-button {{
            position: absolute;
            top: 8px;
            right: 8px;
            background: #238636;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            opacity: 0.8;
            transition: opacity 0.2s;
        }}
        .copy-button:hover {{
            opacity: 1;
        }}
        .copy-button:active {{
            background: #2ea043;
        }}
        .copy-button.copied {{
            background: #1f6feb;
        }}
        
        a {{
            color: #58a6ff;
            text-decoration: none;
        }}
        a:hover {{
            text-decoration: underline;
        }}
        ul, ol {{
            margin-bottom: 16px;
            padding-left: 2em;
        }}
        li {{
            margin-bottom: 4px;
        }}
        blockquote {{
            border-left: 4px solid #21262d;
            padding-left: 16px;
            color: #8b949e;
            margin-bottom: 16px;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 16px;
        }}
        th, td {{
            border: 1px solid #21262d;
            padding: 8px 12px;
            text-align: left;
        }}
        th {{
            background: #0d1117;
            font-weight: 600;
        }}
        img {{
            max-width: 100%;
            height: auto;
        }}

    </style>
</head>
<body>
    <div id="navbar">
        <div class="navbar-title">{filename}</div>
        <button id="toc-toggle">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="3" y1="6" x2="21" y2="6"></line>
                <line x1="3" y1="12" x2="21" y2="12"></line>
                <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
        </button>
    </div>
    <div id="toc-dropdown">
        <div id="toc-content"></div>
    </div>
    <div id="content">
        <div id="markdown"></div>
    </div>
    <script>
        // Configure marked for GitHub-flavored markdown
        marked.setOptions({{
            gfm: true,
            breaks: true,
            highlight: function(code, lang) {{
                if (lang && hljs.getLanguage(lang)) {{
                    return hljs.highlight(code, {{ language: lang }}).value;
                }}
                return hljs.highlightAuto(code).value;
            }}
        }});
        
        // Render markdown
        const mdContent = {md_json};
        document.getElementById('markdown').innerHTML = marked.parse(mdContent);
        
        // Generate Table of Contents
        function generateTOC() {{
            const headers = document.querySelectorAll('#markdown h1, #markdown h2, #markdown h3');
            if (headers.length === 0) return;
            
            const tocContent = document.getElementById('toc-content');
            const ul = document.createElement('ul');
            
            headers.forEach((header, index) => {{
                // Add ID to header for linking
                const id = 'header-' + index;
                header.id = id;
                
                // Create TOC item
                const li = document.createElement('li');
                const a = document.createElement('a');
                a.href = '#' + id;
                a.textContent = header.textContent;
                a.className = 'toc-' + header.tagName.toLowerCase();
                
                // Smooth scroll
                a.addEventListener('click', (e) => {{
                    e.preventDefault();
                    header.scrollIntoView({{ behavior: 'smooth' }});
                    // Close TOC dropdown after click
                    document.getElementById('toc-dropdown').classList.remove('show');
                }});
                
                li.appendChild(a);
                ul.appendChild(li);
            }});
            
            tocContent.appendChild(ul);
        }}
        
        // Toggle TOC dropdown
        document.getElementById('toc-toggle').addEventListener('click', () => {{
            document.getElementById('toc-dropdown').classList.toggle('show');
        }});
        
        // Add copy buttons to code blocks
        function addCopyButtons() {{
            const codeBlocks = document.querySelectorAll('#markdown pre code');
            
            codeBlocks.forEach((codeBlock) => {{
                const pre = codeBlock.parentElement;
                
                // Wrap in div for positioning
                const wrapper = document.createElement('div');
                wrapper.className = 'code-wrapper';
                pre.parentNode.insertBefore(wrapper, pre);
                wrapper.appendChild(pre);
                
                // Create copy button
                const button = document.createElement('button');
                button.className = 'copy-button';
                button.textContent = 'Copy';
                
                button.addEventListener('click', async () => {{
                    try {{
                        await navigator.clipboard.writeText(codeBlock.textContent);
                        button.textContent = 'Copied!';
                        button.classList.add('copied');
                        setTimeout(() => {{
                            button.textContent = 'Copy';
                            button.classList.remove('copied');
                        }}, 2000);
                    }} catch (err) {{
                        button.textContent = 'Failed';
                        setTimeout(() => {{
                            button.textContent = 'Copy';
                        }}, 2000);
                    }}
                }});
                
                wrapper.insertBefore(button, pre);
            }});
        }}
        
        // Initialize features
        generateTOC();
        addCopyButtons();
    </script>
</body>
</html>"""
            # Cache the rendered HTML
            html_bytes = html.encode()
            MarkdownHandler.cached_html = html_bytes
            MarkdownHandler.cached_mtime = current_mtime
            
            self.wfile.write(html_bytes)
        else:
            self.send_error(404)

def get_local_ip():
    """Get local IP address"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def main():
    if len(sys.argv) != 2:
        print("Usage: md-server.py <markdown-file>")
        sys.exit(1)
    
    md_file = sys.argv[1]
    
    if not os.path.exists(md_file):
        print(f"Error: File not found: {md_file}")
        sys.exit(1)
    
    # Set markdown file path as class variable
    MarkdownHandler.md_file_path = md_file
    
    # Find available port in range 8765-8864
    port_start = 8765
    port_end = 8864
    httpd = None
    port = port_start
    
    for port in range(port_start, port_end + 1):
        try:
            httpd = socketserver.TCPServer(("0.0.0.0", port), MarkdownHandler)
            break
        except OSError:
            if port == port_end:
                print(f"ERROR:Could not find available port in range {port_start}-{port_end}")
                sys.exit(1)
            continue
    
    if httpd is None:
        print("ERROR:Could not create server")
        sys.exit(1)
    
    ip = get_local_ip()
    url = f"http://{ip}:{port}"
    
    # Output info for Neovim to parse
    print(f"URL:{url}")
    print(f"PORT:{port}")
    if port != port_start:
        print(f"NOTE:Using port {port} (default {port_start} was busy)")
    sys.stdout.flush()
    
    # Start server
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.shutdown()

if __name__ == "__main__":
    main()
