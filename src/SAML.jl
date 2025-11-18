module SAML

# Core modules
include("types.jl")
include("constants.jl")
include("utils.jl")
include("xml_utils.jl")
include("crypto.jl")
include("authn_request.jl")
include("response.jl")
include("auth.jl")

export
    # Types
    SAMLSettings,
    SPSettings,
    IdPSettings,
    SecuritySettings,
    SAMLRequest,
    SAMLResponse,
    SAMLAssertion,
    SAMLAttribute,
    
    # Main Auth class
    SAMLAuth,
    
    # Methods
    login,
    process_response,
    process_slo,
    get_attributes,
    get_attribute,
    get_nameid,
    is_authenticated,
    get_errors,
    get_last_error_reason,
    get_sp_metadata,
    
    # Utilities
    deflate_and_base64_encode,
    decode_base64_and_inflate,
    generate_unique_id,
    calculate_x509_fingerprint,
    format_cert,
    parse_saml_to_time,
    parse_time_to_saml,
    
    # Constants
    BINDING_HTTP_REDIRECT,
    BINDING_HTTP_POST,
    NAMEID_FORMAT_UNSPECIFIED,
    STATUS_SUCCESS,
    STATUS_FAILURE

end # module SAML
