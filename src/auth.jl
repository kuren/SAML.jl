"""
    Main SAML Authentication handler for Service Provider operations.
"""

"""
    SAMLAuth(settings::SAMLSettings, request_data::Dict)

Initialize a SAML authentication handler.

# Arguments
- `settings::SAMLSettings`: SAML configuration
- `request_data::Dict`: HTTP request data (http_host, script_name, get_data, post_data, etc.)

# Returns
- SAMLAuth object
"""
function SAMLAuth(settings::SAMLSettings, request_data::Dict)::SAMLAuth
    return SAMLAuth(
        settings,
        request_data,
        "",
        nothing,
        false,
        Dict{String, Vector{String}}(),
        String[]
    )
end

"""
    login(auth::SAMLAuth, return_to::String="", force_authn::Bool=false, 
          is_passive::Bool=false, set_nameid_policy::Bool=true)::String

Initiate a SAML login flow.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler
- `return_to::String`: URL to redirect after successful login (becomes RelayState)
- `force_authn::Bool`: Force reauthentication
- `is_passive::Bool`: Passive authentication
- `set_nameid_policy::Bool`: Include NameIDPolicy

# Returns
- Redirect URL to send user to IdP
"""
function login(auth::SAMLAuth, return_to::String="", force_authn::Bool=false, 
              is_passive::Bool=false, set_nameid_policy::Bool=true)::String
    
    # Build AuthnRequest
    authn_request = build_authn_request(auth.settings, force_authn, is_passive, set_nameid_policy)
    
    # Store request ID for later validation
    auth.last_request_id = authn_request.id
    
    # Get redirect URL
    url = get_authn_request_url(authn_request, return_to)
    
    return url
end

"""
    process_response(auth::SAMLAuth)::Bool

Process a SAML Response from the IdP.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- true if response is valid and user is authenticated, false otherwise
"""
function process_response(auth::SAMLAuth)::Bool
    
    empty!(auth.errors)
    auth.authenticated = false
    empty!(auth.user_attributes)
    
    # Parse response
    response = parse_saml_response(auth.settings, auth.request_data)
    auth.last_response = response
    
    if !isempty(response.errors)
        append!(auth.errors, response.errors)
        return false
    end
    
    # Validate response
    if !validate_saml_response(response, auth.settings, auth.last_request_id)
        append!(auth.errors, response.errors)
        return false
    end
    
    # Extract attributes
    auth.user_attributes = get_assertion_attributes(response)
    auth.authenticated = true
    
    return true
end

"""
    process_slo(auth::SAMLAuth)::Bool

Process a Single Logout Response/Request from the IdP.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- true if logout processing succeeded, false otherwise
"""
function process_slo(auth::SAMLAuth)::Bool
    
    empty!(auth.errors)
    
    # Check if we have a SAMLResponse (logout response) or SAMLRequest (logout request)
    if haskey(auth.request_data, "SAMLResponse")
        # Process logout response
        # In a real implementation, would decode and validate
        return true
    elseif haskey(auth.request_data, "SAMLRequest")
        # Process logout request
        # In a real implementation, would decode and validate
        return true
    else
        push!(auth.errors, "No SAML logout message found")
        return false
    end
end

"""
    is_authenticated(auth::SAMLAuth)::Bool

Check if user is authenticated.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- true if user is authenticated
"""
function is_authenticated(auth::SAMLAuth)::Bool
    return auth.authenticated
end

"""
    get_attributes(auth::SAMLAuth)::Dict{String, Vector{String}}

Get user attributes from authenticated session.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- Dictionary of attribute names to values
"""
function get_attributes(auth::SAMLAuth)::Dict{String, Vector{String}}
    return auth.user_attributes
end

"""
    get_attribute(auth::SAMLAuth, name::String)::Vector{String}

Get a specific user attribute.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler
- `name::String`: Attribute name

# Returns
- Attribute values or empty vector if not found
"""
function get_attribute(auth::SAMLAuth, name::String)::Vector{String}
    return get(auth.user_attributes, name, String[])
end

"""
    get_nameid(auth::SAMLAuth)::String

Get the NameID of the authenticated user.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- NameID or empty string if not available
"""
function get_nameid(auth::SAMLAuth)::String
    if auth.last_response === nothing || auth.last_response.assertion === nothing
        return ""
    end
    
    return auth.last_response.assertion.subject_name_id
end

"""
    get_errors(auth::SAMLAuth)::Vector{String}

Get accumulated errors.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- Vector of error messages
"""
function get_errors(auth::SAMLAuth)::Vector{String}
    return auth.errors
end

"""
    get_last_error_reason(auth::SAMLAuth)::String

Get the reason for the last error.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- Error reason or empty string if no errors
"""
function get_last_error_reason(auth::SAMLAuth)::String
    if isempty(auth.errors)
        return ""
    end
    
    return auth.errors[end]
end

"""
    get_last_request_id(auth::SAMLAuth)::String

Get the ID of the last generated SAML request.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- Request ID
"""
function get_last_request_id(auth::SAMLAuth)::String
    return auth.last_request_id
end

"""
    get_sp_metadata(auth::SAMLAuth)::String

Get the SP metadata XML.

# Arguments
- `auth::SAMLAuth`: SAML authentication handler

# Returns
- XML metadata string
"""
function get_sp_metadata(auth::SAMLAuth)::String
    
    settings = auth.settings
    
    metadata = """<?xml version="1.0" encoding="UTF-8"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
    ID="$(generate_unique_id())"
    entityID="$(settings.sp.entity_id)"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata">
    <SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
            <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
                <X509Data>
                    <X509Certificate>$(strip(replace(settings.sp.x509_cert, r"-----[^-]*-----" => "")))</X509Certificate>
                </X509Data>
            </KeyInfo>
        </KeyDescriptor>
"""
    
    # Add assertion consumer service
    if haskey(settings.sp.assertion_consumer_service, "url")
        binding = get(settings.sp.assertion_consumer_service, "binding", BINDING_HTTP_POST)
        url = settings.sp.assertion_consumer_service["url"]
        metadata *= """
        <AssertionConsumerService Binding=\"$binding\"
            Location=\"$url\"
            index=\"0\" isDefault=\"true\"/>
"""
    end
    
    # Add single logout service
    if haskey(settings.sp.single_logout_service, "url")
        binding = get(settings.sp.single_logout_service, "binding", BINDING_HTTP_REDIRECT)
        url = settings.sp.single_logout_service["url"]
        metadata *= """
        <SingleLogoutService Binding=\"$binding\"
            Location=\"$url\"/>
"""
    end
    
    metadata *= """
    </SPSSODescriptor>
</EntityDescriptor>
"""
    
    return metadata
end
