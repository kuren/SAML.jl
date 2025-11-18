# SAML Julia Package - Quick Reference

## Essential Information

### What This Package Does
- ✅ SP-only SAML 2.0 implementation (client-side)
- ✅ AuthnRequest generation for login
- ✅ SAML Response parsing and validation
- ✅ User attribute extraction
- ✅ Metadata generation
- ✅ Certificate handling

### What It Doesn't Do
- ❌ Identity Provider functionality
- ❌ Signature validation (needs OpenSSL binding)
- ❌ Assertion encryption
- ❌ Built-in session management

## 5-Minute Setup

```julia
using SAML

# 1. Create settings
sp = SPSettings(
    "https://app.example.com/metadata/",
    Dict("url" => "https://app.example.com/acs", "binding" => BINDING_HTTP_POST),
    Dict("url" => "https://app.example.com/sls", "binding" => BINDING_HTTP_REDIRECT),
    NAMEID_FORMAT_UNSPECIFIED, "", ""
)

idp = IdPSettings(
    "https://idp.example.com/metadata/",
    Dict("url" => "https://idp.example.com/sso"),
    Dict("url" => "https://idp.example.com/slo"),
    "", "", "sha1"
)

sec = SecuritySettings(false, false, false, false, RSA_SHA256, SHA256, true)
settings = SAMLSettings(sp, idp, sec, true, false)

# 2. Login
request_data = Dict("http_host" => "app.example.com", "script_name" => "/acs", 
                    "get_data" => Dict(), "post_data" => Dict(), "https" => "on")
auth = SAMLAuth(settings, request_data)
redirect_url = login(auth)

# 3. Process response
request_data["post_data"]["SAMLResponse"] = saml_response_param
auth = SAMLAuth(settings, request_data)
if process_response(auth)
    user_email = get_attribute(auth, "email")[1]
end
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `SAMLAuth(settings, request_data)` | Create auth handler |
| `login(auth, return_to)` | Get login redirect URL |
| `process_response(auth)` | Parse and validate IdP response |
| `is_authenticated(auth)` | Check if user is logged in |
| `get_attributes(auth)` | Get all user attributes |
| `get_attribute(auth, name)` | Get specific attribute |
| `get_nameid(auth)` | Get user NameID |
| `get_errors(auth)` | Get error messages |
| `get_sp_metadata(auth)` | Generate SP metadata |

## Essential Constants

```julia
# Bindings
BINDING_HTTP_POST
BINDING_HTTP_REDIRECT

# NameID Formats
NAMEID_FORMAT_UNSPECIFIED
NAMEID_FORMAT_EMAIL_ADDRESS
NAMEID_FORMAT_PERSISTENT

# Signature Algorithms
RSA_SHA256
RSA_SHA384
RSA_SHA512

# Status
STATUS_SUCCESS
STATUS_FAILURE
```

## Configuration Template

```julia
settings = SAMLSettings(
    SPSettings(
        "https://yourapp.com/metadata/",
        Dict("url" => "https://yourapp.com/saml/acs", "binding" => BINDING_HTTP_POST),
        Dict("url" => "https://yourapp.com/saml/sls", "binding" => BINDING_HTTP_REDIRECT),
        NAMEID_FORMAT_UNSPECIFIED,
        sp_cert,  # from file
        sp_key    # from file
    ),
    IdPSettings(
        "https://idp.com/metadata/",
        Dict("url" => "https://idp.com/sso"),
        Dict("url" => "https://idp.com/slo"),
        idp_cert,  # from file
        "",
        "sha1"
    ),
    SecuritySettings(false, false, false, false, RSA_SHA256, SHA256, true),
    true,   # strict
    false   # debug
)
```

## Request Data Structure

```julia
request_data = Dict(
    "http_host" => "app.example.com",
    "script_name" => "/path",
    "get_data" => Dict(),           # query string params
    "post_data" => Dict(),          # POST body params
    "https" => "on",                # "on" or "off"
    "request_uri" => "/path",       # optional
    "query_string" => "foo=bar"     # optional
)
```

## Common Workflows

### Login Redirect
```julia
auth = SAMLAuth(settings, request_data)
login_url = login(auth, return_to="/dashboard")
# redirect(login_url)
```

### Handle ACS Response
```julia
auth = SAMLAuth(settings, request_data)
if process_response(auth)
    # Logged in
    email = get_attribute(auth, "email")[1]
    # Create user session
else
    # Error
    errors = get_errors(auth)
end
```

### Get SP Metadata
```julia
auth = SAMLAuth(settings, Dict())
metadata = get_sp_metadata(auth)
# Return as XML to browser
```

### Check Attributes
```julia
attrs = get_attributes(auth)
# attrs is Dict{String, Vector{String}}
email = get(attrs, "email", [""])[1]
groups = get(attrs, "groups", String[])
```

## Error Handling

```julia
if !process_response(auth)
    errors = get_errors(auth)  # Vector of error strings
    reason = get_last_error_reason(auth)  # Last error
    
    # Handle errors
    for error in errors
        @warn "SAML Error: $error"
    end
end
```

## Utility Functions

```julia
# Encoding
encoded = deflate_and_base64_encode(xml_string)
decoded = decode_base64_and_inflate(encoded)

# Timestamps
saml_ts = parse_time_to_saml(1700000000)
unix_ts = parse_saml_to_time("2025-11-18T12:00:00Z")

# Certificates
fp = calculate_x509_fingerprint(cert, "sha256")
cert = format_cert(cert)
key = format_private_key(key)

# IDs
unique_id = generate_unique_id()
```

## Typical File Structure

```
myapp/
├── src/
│   └── saml.jl              # Your SAML handlers
├── config/
│   ├── saml_settings.json   # SAML config
│   └── certs/
│       ├── sp.crt           # SP certificate
│       ├── sp.key           # SP private key
│       └── idp.crt          # IdP certificate
└── routes.jl                # Web framework routes
```

## Documentation Files

| File | Purpose |
|------|---------|
| README.md | Quick start and API reference |
| docs/IMPLEMENTATION.md | Architecture and design |
| docs/DEPLOYMENT.md | Production deployment guide |
| docs/examples.jl | Configuration examples |
| CHANGELOG.md | Version history |

## Getting Help

1. **API Questions** → Check README.md
2. **How do I configure X?** → Check docs/examples.jl
3. **How do I deploy?** → Check docs/DEPLOYMENT.md
4. **How does it work?** → Check docs/IMPLEMENTATION.md
5. **What's a function signature?** → Check source code docstrings

## Security Checklist

- [ ] Using HTTPS (required for SAML)
- [ ] IdP certificate is validated
- [ ] Strict mode enabled in production
- [ ] RelayState URLs are validated
- [ ] Error messages don't leak sensitive info
- [ ] Certificates stored securely
- [ ] Certificate expiration monitored
- [ ] Authentication attempts logged

## Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid issuer" | Check IdP entity ID matches config |
| "Assertion expired" | Verify server time (NTP) is correct |
| "SAML Response not found" | Ensure POST binding is used |
| "Signature validation failed" | Verify IdP certificate is correct |
| "Destination mismatch" | Check ACS URL matches IdP config |

## Examples Directory Contents

- `examples.jl` - Configuration examples for:
  - Basic setup
  - Using certificates
  - Using fingerprints
  - Okta configuration
  - Azure AD configuration
  - Loading from JSON
  - Testing configuration

## Dependencies

```toml
LightXML   # XML parsing
HTTP       # URL utilities
SHA        # Fingerprints (stdlib)
Base64     # Encoding (stdlib)
Dates      # Timestamps (stdlib)
UUIDs      # ID generation (stdlib)
```

## Running Tests

```julia
# In SAMLClient directory
using Pkg
Pkg.test()

# Or manually
include("test/runtests.jl")
```

## Package Version

- **Current**: 0.1.0 (Beta)
- **Status**: Feature-complete for client-side SP
- **Next Release**: When signature validation implemented
- **License**: MIT

## Key Capabilities

| Feature | Status | Notes |
|---------|--------|-------|
| AuthnRequest generation | ✅ Complete | All options supported |
| HTTP-Redirect binding | ✅ Complete | Base64 + DEFLATE |
| HTTP-POST binding | ✅ Complete | HTML form generation |
| Response parsing | ✅ Complete | XML decoding and extraction |
| Assertion validation | ✅ Complete | Issuer, status, timing |
| Attribute extraction | ✅ Complete | Multi-valued attributes |
| Certificate handling | ✅ Complete | Formatting and fingerprints |
| Signature validation | ⚠️ Stub | Requires OpenSSL binding |
| Metadata generation | ✅ Complete | Valid SP metadata XML |
| Single Logout | ⚠️ Framework | Needs signature support |
| Assertion encryption | ❌ Not implemented | Future work |

## Next Steps

1. Configure with your IdP
2. Implement SAML handlers in your app
3. Test with staging IdP account
4. Deploy to production with HTTPS
5. Monitor authentication success rates
6. Plan certificate rotation

---

**For more information, see the comprehensive documentation in the docs/ directory.**
