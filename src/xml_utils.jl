"""
    XML parsing and manipulation utilities for SAML messages.
"""

using LightXML

"""
    escape_xml(text::String)::String

Escape special XML characters.

# Arguments
- `text::String`: Text to escape

# Returns
- XML-escaped string
"""
function escape_xml(text::String)::String
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    text = replace(text, "'" => "&apos;")
    return text
end

"""
    unescape_xml(text::String)::String

Unescape XML entities.

# Arguments
- `text::String`: XML text to unescape

# Returns
- Unescaped string
"""
function unescape_xml(text::String)::String
    text = replace(text, "&apos;" => "'")
    text = replace(text, "&quot;" => "\"")
    text = replace(text, "&gt;" => ">")
    text = replace(text, "&lt;" => "<")
    text = replace(text, "&amp;" => "&")
    return text
end

"""
    parse_xml(xml_string::String)::Union{XMLDocument, Nothing}

Parse an XML string into an XML document.

# Arguments
- `xml_string::String`: XML string to parse

# Returns
- XMLDocument or nothing if parsing fails
"""
function parse_xml(xml_string::String)::Union{XMLDocument, Nothing}
    try
        xdoc = parse_string(xml_string)
        return xdoc
    catch e
        return nothing
    end
end

"""
    query_element(root::XMLElement, xpath::String)::Union{XMLElement, Nothing}

Query for an element using XPath-like syntax (simplified).

# Arguments
- `root::XMLElement`: Root element to search from
- `xpath::String`: Simple XPath query (e.g., "ns:Issuer")

# Returns
- First matching XMLElement or nothing
"""
function query_element(root::XMLElement, xpath::String)::Union{XMLElement, Nothing}
    # Simple XPath implementation for common SAML paths
    parts = split(xpath, "/")
    current = root
    
    for part in parts
        if isempty(part)
            continue
        end
        
        # Handle namespace prefixes
        if contains(part, ":")
            prefix, localname = split(part, ":", limit=2)
            # In a real implementation, would look up namespace
            # For now, just search by local name
            found = false
            for child in child_elements(current)
                if name(child) == localname || name(child) == part
                    current = child
                    found = true
                    break
                end
            end
            if !found
                return nothing
            end
        else
            found = false
            for child in child_elements(current)
                if name(child) == part
                    current = child
                    found = true
                    break
                end
            end
            if !found
                return nothing
            end
        end
    end
    
    return current
end

"""
    query_elements(root::XMLElement, xpath::String)::Vector{XMLElement}

Query for multiple elements.

# Arguments
- `root::XMLElement`: Root element to search from
- `xpath::String`: Simple XPath query

# Returns
- Vector of matching XMLElements
"""
function query_elements(root::XMLElement, xpath::String)::Vector{XMLElement}
    results = XMLElement[]
    
    # Simple implementation for common patterns
    parts = split(xpath, "/")
    current = root
    
    # Navigate to parent element if multi-part path
    if length(parts) > 1
        for part in parts[1:end-1]
            if !isempty(part)
                found = false
                for child in child_elements(current)
                    if name(child) == part || endswith(name(child), ":" * part)
                        current = child
                        found = true
                        break
                    end
                end
                if !found
                    return results
                end
            end
        end
    end
    
    # Find all matching final elements
    target = parts[end]
    for child in child_elements(current)
        if name(child) == target || endswith(name(child), ":" * target)
            push!(results, child)
        end
    end
    
    return results
end

"""
    get_element_text(elem::XMLElement)::String

Get text content of an element.

# Arguments
- `elem::XMLElement`: Element to get text from

# Returns
- Text content
"""
function get_element_text(elem::XMLElement)::String
    content = ""
    for node in child_nodes(elem)
        if isa(node, XMLText)
            content *= text(node)
        end
    end
    return strip(content)
end

"""
    get_attribute_value(elem::XMLElement, attr_name::String)::String

Get attribute value from an element.

# Arguments
- `elem::XMLElement`: Element to query
- `attr_name::String`: Attribute name

# Returns
- Attribute value or empty string if not found
"""
function get_attribute_value(elem::XMLElement, attr_name::String)::String
    attrs = attributes_dict(elem)
    return get(attrs, attr_name, "")
end

"""
    to_string(root::XMLElement)::String

Serialize an XML element to string.

# Arguments
- `root::XMLElement`: Element to serialize

# Returns
- XML string representation
"""
function to_string(root::XMLElement)::String
    return string(root)
end

"""
    create_element(name::String, attrs::Dict{String,String}="", text::String="")::XMLElement

Create a new XML element.

# Arguments
- `name::String`: Element name
- `attrs::Dict{String,String}`: Element attributes
- `text::String`: Element text content

# Returns
- New XMLElement
"""
function create_element(name::String, attrs::Dict{String,String}=Dict(), text::String="")::XMLElement
    elem = new_element(name)
    
    for (key, value) in attrs
        set_attribute(elem, key, value)
    end
    
    if !isempty(text)
        add_text(elem, text)
    end
    
    return elem
end
