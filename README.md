# SAML Client - Julia SAML Service Provider Package

A Julia implementation of SAML 2.0 Service Provider (client-side) functionality for single sign-on (SSO) integration with SAML Identity Providers.

## Features

- ✅ **AuthnRequest Generation**: Create and encode SAML authentication requests
- ✅ **HTTP Bindings**: Support for HTTP-Redirect and HTTP-POST bindings
- ✅ **Response Parsing**: Decode and parse SAML responses from Identity Providers
- ✅ **Assertion Validation**: Validate assertions including time conditions
- ✅ **Certificate Support**: X.509 certificate handling and fingerprint calculation
- ✅ **Metadata Generation**: Generate SP metadata for IdP configuration
- ✅ **Attribute Extraction**: Extract and access user attributes from assertions
- ⚠️ **Signature Validation**: Framework in place (requires OpenSSL/xmlsec1 bindings)
- ⚠️ **Single Logout**: Logout flow framework (full implementation requires signature support)

## Service Provider Scope

This package focuses exclusively on **client-side Service Provider logic**:
- Initiating SAML login flows
- Processing SAML responses from Identity Providers
- Validating assertions and user attributes
- Managing SP metadata and certificates

**Out of Scope**: Identity Provider implementation, assertion issuance, or IdP-specific functionality.

## Installation

```julia
# Add to your project (once registered)
using Pkg
Pkg.add("SAML")

# Or add from local directory
Pkg.add(path="/path/to/SAMLClient")
```

## Quick Start

### Initialize SAML Settings

```julia
using SAML

# Configure Service Provider
sp_settings = SPSettings(
    "https://myapp.example.com/metadata/",  # SP entity ID
    Dict("url" => "https://myapp.example.com/acs", "binding" => BINDING_HTTP_POST),
    Dict("url" => "https://myapp.example.com/sls", "binding" => BINDING_HTTP_REDIRECT),
    NAMEID_FORMAT_UNSPECIFIED,
    sp_cert,  # X.509 certificate
    sp_key    # Private key
)

# Configure Identity Provider
idp_settings = IdPSettings(
    "https://idp.example.com/metadata/",
    Dict("url" => "https://idp.example.com/sso"),
    Dict("url" => "https://idp.example.com/slo"),
    idp_cert,  # X.509 certificate
    "",        # or use cert_fingerprint
    ""         # fingerprint_algorithm
)

# Security settings
security_settings = SecuritySettings(
    false,              # authn_requests_signed
    false,              # logout_requests_signed
    false,              # want_assertions_signed
    false,              # want_messages_signed
    RSA_SHA256,         # signature_algorithm
    SHA256,             # digest_algorithm
    true                # reject_deprecated_algorithm
)

settings = SAMLSettings(sp_settings, idp_settings, security_settings, true, false)
```

### Initiate Login

```julia
# Build HTTP request data structure
request_data = Dict(
    "http_host" => "myapp.example.com",
    "script_name" => "/acs",
    "get_data" => Dict(),
    "post_data" => Dict(),
    "https" => "on"
)

auth = SAMLAuth(settings, request_data)

# Get the redirect URL for the IdP
login_url = login(auth, return_to="https://myapp.example.com/dashboard")

# Redirect user to IdP
# redirect(login_url)
```

### Process Response

```julia
# After IdP redirects user back with SAMLResponse
request_data["post_data"] = Dict("SAMLResponse" => saml_response_param)

auth = SAMLAuth(settings, request_data)

if process_response(auth)
    # Authentication successful
    attributes = get_attributes(auth)
    nameid = get_nameid(auth)
    
    # Extract specific attributes
    email = get_attribute(auth, "email")
    groups = get_attribute(auth, "groups")
else
    errors = get_errors(auth)
    error_reason = get_last_error_reason(auth)
end
```

## API Reference

### Main Types

#### `SAMLAuth`
Main authentication handler for SP operations.

```julia
auth = SAMLAuth(settings::SAMLSettings, request_data::Dict)
```

### Authentication Methods

#### `login(auth, return_to, force_authn, is_passive, set_nameid_policy)`
Initiate SAML login flow.

```julia
login_url = login(auth, return_to="https://app.example.com/redirect")
```

#### `process_response(auth)`
Process SAML Response from IdP.

```julia
if process_response(auth)
    attrs = get_attributes(auth)
end
```

#### `is_authenticated(auth)`
Check if user is authenticated.

```julia
if is_authenticated(auth)
    # User is logged in
end
```

### Attribute Methods

#### `get_attributes(auth)`
Get all user attributes.

```julia
attributes = get_attributes(auth)
# Returns: Dict{String, Vector{String}}
```

#### `get_attribute(auth, name)`
Get specific user attribute.

```julia
emails = get_attribute(auth, "email")
```

#### `get_nameid(auth)`
Get the NameID of authenticated user.

```julia
nameid = get_nameid(auth)
```

### Error Handling

#### `get_errors(auth)`
Get all accumulated errors.

```julia
errors = get_errors(auth)
```

#### `get_last_error_reason(auth)`
Get the reason for the last error.

```julia
reason = get_last_error_reason(auth)
```

### Metadata

#### `get_sp_metadata(auth)`
Generate SP metadata XML for IdP configuration.

```julia
metadata_xml = get_sp_metadata(auth)
```

## Constants

### HTTP Bindings
- `BINDING_HTTP_REDIRECT` - HTTP Redirect binding
- `BINDING_HTTP_POST` - HTTP POST binding

### NameID Formats
- `NAMEID_FORMAT_UNSPECIFIED` - Unspecified format
- `NAMEID_FORMAT_EMAIL_ADDRESS` - Email address format
- `NAMEID_FORMAT_PERSISTENT` - Persistent identifier
- `NAMEID_FORMAT_TRANSIENT` - Transient identifier

### Status Codes
- `STATUS_SUCCESS` - Successful SAML response
- `STATUS_FAILURE` - Authentication failed

### Algorithms
- `RSA_SHA256`, `RSA_SHA384`, `RSA_SHA512` - Signature algorithms
- `SHA256`, `SHA384`, `SHA512` - Digest algorithms

## Configuration

### SPSettings Fields
- `entity_id::String` - SP entity identifier (URI)
- `assertion_consumer_service::Dict` - ACS endpoint config
- `single_logout_service::Dict` - SLS endpoint config
- `name_id_format::String` - NameID format preference
- `x509_cert::String` - SP X.509 certificate
- `private_key::String` - SP private key

### IdPSettings Fields
- `entity_id::String` - IdP entity identifier
- `single_sign_on_service::Dict` - SSO endpoint config
- `single_logout_service::Dict` - SLS endpoint config
- `x509_cert::String` - IdP X.509 certificate
- `cert_fingerprint::String` - Certificate fingerprint
- `cert_fingerprint_algorithm::String` - Fingerprint algorithm

### SecuritySettings Fields
- `authn_requests_signed::Bool` - Sign AuthnRequests
- `logout_requests_signed::Bool` - Sign LogoutRequests
- `want_assertions_signed::Bool` - Require signed assertions
- `want_messages_signed::Bool` - Require signed messages
- `signature_algorithm::String` - Algorithm for signing
- `digest_algorithm::String` - Algorithm for digest
- `reject_deprecated_algorithm::Bool` - Reject deprecated algorithms

## Utility Functions

### Encoding/Decoding

```julia
# Base64 + Deflate encoding (HTTP-Redirect binding)
encoded = deflate_and_base64_encode(xml_string)
decoded = decode_base64_and_inflate(encoded)
```

### Certificate Operations

```julia
# Calculate certificate fingerprint
fingerprint = calculate_x509_fingerprint(cert, "sha256")

# Format certificate with proper PEM headers
formatted_cert = format_cert(cert)

# Format private key
formatted_key = format_private_key(key)
```

### Time Operations

```julia
# Convert Unix timestamp to SAML format
saml_time = parse_time_to_saml(time())

# Convert SAML timestamp to Unix timestamp
unix_ts = parse_saml_to_time("2025-11-18T12:00:00Z")
```

## Security Considerations

1. **Always use HTTPS** - SAML requires secure transport
2. **Verify IdP Certificate** - Validate IdP X.509 certificates
3. **Validate Timestamps** - Check assertion validity times
4. **Protect Private Keys** - Keep SP private keys secure
5. **Strict Mode** - Enable strict validation in production
6. **RelayState Validation** - Validate RelayState URLs to prevent open redirect attacks

## Limitations and Future Work

### Current Limitations
- Signature validation requires external OpenSSL/xmlsec1 bindings (not yet implemented)
- Assertion encryption/decryption requires additional cryptographic libraries
- Single Logout (SLO) is partially implemented pending signature support

### Planned Enhancements
- [ ] OpenSSL binding integration for signature validation
- [ ] XML signature generation and verification
- [ ] Assertion encryption/decryption support
- [ ] Complete Single Logout (SLO) implementation
- [ ] Metadata parsing and caching
- [ ] IdP metadata discovery and caching
- [ ] Additional attribute mapping and transformation
- [ ] Session management helpers

## Testing

```bash
cd /path/to/SAMLClient
julia --project -e "using Pkg; Pkg.test()"
```

## Contributing

Contributions are welcome! Areas of particular interest:
- OpenSSL/xmlsec1 binding implementations
- Encryption support
- Additional protocol bindings
- Improved error handling and logging

## References

- [OASIS SAML 2.0 Standard](https://www.oasis-open.org/committees/tc_home.php?wg_abbrev=security)
- [python3-saml](https://github.com/SAML-Toolkits/python3-saml) - Reference implementation
- [SAML 2.0 Web Browser SSO Profile](https://en.wikipedia.org/wiki/SAML_2.0)

## License

MIT License - See LICENSE file for details

## Disclaimer

This is a community-maintained package. While it follows SAML 2.0 standards, always test thoroughly before deploying to production. Security is critical - consider having the implementation reviewed by security experts.
