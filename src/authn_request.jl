"""
    SAML AuthnRequest generation and handling.
"""

using UUIDs
using Dates
using HTTP

"""
    AuthnRequest

Represents a SAML Authentication Request.
"""
mutable struct AuthnRequest
    id::String
    issue_instant::String
    destination::String
    issuer::String
    assertion_consumer_service_url::String
    protocol_binding::String
    force_authn::Bool
    is_passive::Bool
    name_id_policy::Bool
    xml::String
    
    function AuthnRequest()
        return new(
            "_" * string(uuid4()),
            Dates.format(Dates.now(Dates.UTC), "yyyy-mm-ddTHH:MM:SSZ"),
            "",
            "",
            "",
            BINDING_HTTP_POST,
            false,
            false,
            false,
            ""
        )
    end
end

"""
    build_authn_request(settings::SAMLSettings, force_authn::Bool=false, 
                       is_passive::Bool=false, set_nameid_policy::Bool=true)::AuthnRequest

Build a SAML AuthnRequest.

# Arguments
- `settings::SAMLSettings`: SAML configuration
- `force_authn::Bool`: Whether to force reauthentication
- `is_passive::Bool`: Whether authentication should be passive
- `set_nameid_policy::Bool`: Whether to include NameIDPolicy

# Returns
- Constructed AuthnRequest object
"""
function build_authn_request(settings::SAMLSettings, force_authn::Bool=false, 
                            is_passive::Bool=false, set_nameid_policy::Bool=true)::AuthnRequest
    
    request = AuthnRequest()
    request.destination = settings.idp.single_sign_on_service["url"]
    request.issuer = settings.sp.entity_id
    request.assertion_consumer_service_url = settings.sp.assertion_consumer_service["url"]
    request.force_authn = force_authn
    request.is_passive = is_passive
    request.name_id_policy = set_nameid_policy
    
    # Get protocol binding
    if haskey(settings.sp.assertion_consumer_service, "binding")
        request.protocol_binding = settings.sp.assertion_consumer_service["binding"]
    end
    
    # Build XML
    request.xml = _build_authn_request_xml(request, settings)
    
    return request
end

"""
    _build_authn_request_xml(request::AuthnRequest, settings::SAMLSettings)::String

Build the XML representation of an AuthnRequest.

# Arguments
- `request::AuthnRequest`: Request object
- `settings::SAMLSettings`: SAML configuration

# Returns
- XML string
"""
function _build_authn_request_xml(request::AuthnRequest, settings::SAMLSettings)::String
    
    force_authn_attr = request.force_authn ? "true" : "false"
    is_passive_attr = request.is_passive ? "true" : "false"
    
    xml = """<?xml version="1.0" encoding="UTF-8"?>
<samlp:AuthnRequest xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"
    xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\"
    ID=\"$(request.id)\"
    Version=\"2.0\"
    IssueInstant=\"$(request.issue_instant)\"
    Destination=\"$(request.destination)\"
    AssertionConsumerServiceURL=\"$(request.assertion_consumer_service_url)\"
    ProtocolBinding=\"$(request.protocol_binding)\"
    ForceAuthn=\"$force_authn_attr\"
    IsPassive=\"$is_passive_attr\">
    <saml:Issuer>$(request.issuer)</saml:Issuer>"""
    
    if request.name_id_policy
        xml *= "\n    <samlp:NameIDPolicy Format=\"$(settings.sp.name_id_format)\" AllowCreate=\"true\"/>"
    end
    
    xml *= "\n</samlp:AuthnRequest>"
    
    return xml
end

"""
    get_authn_request_url(request::AuthnRequest, relay_state::String="")::String

Get the URL for redirecting to the IdP (HTTP-Redirect binding).

# Arguments
- `request::AuthnRequest`: AuthnRequest object
- `relay_state::String`: Optional RelayState parameter

# Returns
- Full redirect URL with encoded request
"""
function get_authn_request_url(request::AuthnRequest, relay_state::String="")::String
    
    encoded_request = deflate_and_base64_encode(request.xml)
    
    url = "$(request.destination)?SAMLRequest=$(HTTP.escapeuri(encoded_request))"
    
    if !isempty(relay_state)
        url *= "&RelayState=$(HTTP.escapeuri(relay_state))"
    end
    
    return url
end

"""
    get_authn_request_post_form(request::AuthnRequest, relay_state::String="")::String

Get an HTML form for POST binding.

# Arguments
- `request::AuthnRequest`: AuthnRequest object
- `relay_state::String`: Optional RelayState parameter

# Returns
- HTML form string
"""
function get_authn_request_post_form(request::AuthnRequest, relay_state::String="")::String
    
    encoded_request = base64encode(request.xml)
    
    form = """
    <html>
    <head>
        <title>SAML Authentication Request</title>
    </head>
    <body onload=\"document.forms[0].submit()\">
        <form method=\"post\" action=\"$(request.destination)\">
            <input type=\"hidden\" name=\"SAMLRequest\" value=\"$(encoded_request)\" />"""
    
    if !isempty(relay_state)
        form *= "\n            <input type=\"hidden\" name=\"RelayState\" value=\"$(relay_state)\" />"
    end
    
    form *= """
            <noscript>
                <button type=\"submit\">Click here to continue</button>
            </noscript>
        </form>
    </body>
    </html>
    """
    
    return form
end
