"""
    SPSettings

Service Provider configuration.

# Fields
- `entity_id::String`: SP entity identifier (URI)
- `assertion_consumer_service::Dict`: ACS endpoint configuration
- `single_logout_service::Dict`: SLS endpoint configuration
- `name_id_format::String`: NameID format
- `x509_cert::String`: SP X.509 certificate
- `private_key::String`: SP private key
"""
mutable struct SPSettings
    entity_id::String
    assertion_consumer_service::Dict{String, Any}
    single_logout_service::Dict{String, Any}
    name_id_format::String
    x509_cert::String
    private_key::String
end

"""
    IdPSettings

Identity Provider configuration.

# Fields
- `entity_id::String`: IdP entity identifier (URI)
- `single_sign_on_service::Dict`: SSO endpoint configuration
- `single_logout_service::Dict`: SLS endpoint configuration
- `x509_cert::String`: IdP X.509 certificate
- `cert_fingerprint::String`: IdP certificate fingerprint (alternative to cert)
- `cert_fingerprint_algorithm::String`: Algorithm used for fingerprint
"""
mutable struct IdPSettings
    entity_id::String
    single_sign_on_service::Dict{String, Any}
    single_logout_service::Dict{String, Any}
    x509_cert::String
    cert_fingerprint::String
    cert_fingerprint_algorithm::String
end

"""
    SecuritySettings

Security configuration for SAML messages and assertions.

# Fields
- `authn_requests_signed::Bool`: Whether AuthnRequests should be signed
- `logout_requests_signed::Bool`: Whether LogoutRequests should be signed
- `want_assertions_signed::Bool`: Require assertions to be signed
- `want_messages_signed::Bool`: Require messages to be signed
- `signature_algorithm::String`: Algorithm for signing
- `digest_algorithm::String`: Algorithm for digest
- `reject_deprecated_algorithm::Bool`: Reject deprecated algorithms
"""
mutable struct SecuritySettings
    authn_requests_signed::Bool
    logout_requests_signed::Bool
    want_assertions_signed::Bool
    want_messages_signed::Bool
    signature_algorithm::String
    digest_algorithm::String
    reject_deprecated_algorithm::Bool
end

"""
    SAML type definitions and data structures for Service Provider implementations.
"""

"""
    SAMLSettings

Main configuration container for SAML Service Provider.

# Fields
- `sp::SPSettings`: Service Provider configuration
- `idp::IdPSettings`: Identity Provider configuration
- `security::SecuritySettings`: Security settings for signing/encryption
- `strict::Bool`: Whether to enforce strict SAML compliance
- `debug::Bool`: Whether to enable debug output
"""
mutable struct SAMLSettings
    sp::SPSettings
    idp::IdPSettings
    security::SecuritySettings
    strict::Bool
    debug::Bool
end

"""
    SAMLRequest

Represents a SAML request (AuthnRequest or LogoutRequest).

# Fields
- `id::String`: Request unique identifier
- `issue_instant::String`: Timestamp when request was issued
- `xml::String`: XML representation of the request
- `encoded::String`: Base64-encoded and deflated request
"""
mutable struct SAMLRequest
    id::String
    issue_instant::String
    xml::String
    encoded::String
end

"""
    SAMLAssertion

Represents an assertion within a SAML response.

# Fields
- `id::String`: Assertion unique identifier
- `issuer::String`: Entity that issued the assertion
- `subject_name_id::String`: NameID of the subject
- `not_on_or_after::String`: Assertion expiration time
- `not_before::String`: Assertion validity start time
- `attributes::Dict`: User attributes from assertion
"""
mutable struct SAMLAssertion
    id::String
    issuer::String
    subject_name_id::String
    not_on_or_after::String
    not_before::String
    attributes::Dict{String, Vector{String}}
end

"""
    SAMLResponse

Represents a SAML response from the IdP.

# Fields
- `id::String`: Response unique identifier
- `in_response_to::String`: Request ID this response is replying to
- `issuer::String`: Entity that issued the response
- `status_code::String`: Status of the response
- `status_message::String`: Status message
- `assertion::SAMLAssertion`: The contained assertion
- `xml::String`: XML representation
- `is_valid::Bool`: Whether response has been validated
- `errors::Vector{String}`: Validation errors
"""
mutable struct SAMLResponse
    id::String
    in_response_to::String
    issuer::String
    status_code::String
    status_message::String
    assertion::Union{SAMLAssertion, Nothing}
    xml::String
    is_valid::Bool
    errors::Vector{String}
end

"""
    SAMLAttribute

Represents a single SAML attribute.

# Fields
- `name::String`: Attribute name
- `friendly_name::String`: User-friendly name
- `values::Vector{String}`: Attribute values
"""
struct SAMLAttribute
    name::String
    friendly_name::String
    values::Vector{String}
end

"""
    SAMLAuth

Main authentication handler for SAML Service Provider operations.

# Fields
- `settings::SAMLSettings`: SAML configuration
- `request_data::Dict`: HTTP request data
- `last_request_id::String`: ID of last generated request
- `last_response::Union{SAMLResponse, Nothing}`: Last processed response
- `authenticated::Bool`: Whether user is authenticated
- `user_attributes::Dict`: Authenticated user's attributes
- `errors::Vector{String}`: Accumulated errors
"""
mutable struct SAMLAuth
    settings::SAMLSettings
    request_data::Dict{String, Any}
    last_request_id::String
    last_response::Union{SAMLResponse, Nothing}
    authenticated::Bool
    user_attributes::Dict{String, Vector{String}}
    errors::Vector{String}
end
