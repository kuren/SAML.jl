# SAML Julia Package

[![Tests](https://github.com/yourusername/SAML.jl/workflows/Tests/badge.svg)](https://github.com/yourusername/SAML.jl/actions)
[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://github.com/yourusername/SAML.jl#documentation)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A pure Julia implementation of SAML 2.0 Service Provider (SP) client-side functionality for single sign-on (SSO) integration with SAML Identity Providers.

## Features

- ✅ **AuthnRequest Generation** - Create SAML authentication requests
- ✅ **HTTP Bindings** - HTTP-Redirect and HTTP-POST support
- ✅ **Response Parsing** - Decode and parse SAML responses
- ✅ **Assertion Validation** - Validate assertions including time conditions
- ✅ **Certificate Support** - X.509 certificate handling and fingerprinting
- ✅ **Metadata Generation** - Generate SP metadata for IdP configuration
- ✅ **Attribute Extraction** - Extract user attributes from assertions
- ✅ **Framework Agnostic** - Works with any Julia web framework
- ⚠️ **Signature Validation** - Framework in place (requires OpenSSL bindings)
- ⚠️ **Single Logout** - Basic framework (full implementation requires signatures)

## Installation

This package can be installed using Julia's package manager:

```julia
using Pkg
Pkg.add("SAML")
```

Or add directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/yourusername/SAML.jl.git")
```

## Quick Start

```julia
using SAML

# Configure Service Provider and Identity Provider
sp_settings = SPSettings(
    "https://myapp.example.com/metadata/",
    Dict("url" => "https://myapp.example.com/acs", "binding" => BINDING_HTTP_POST),
    Dict("url" => "https://myapp.example.com/sls", "binding" => BINDING_HTTP_REDIRECT),
    NAMEID_FORMAT_UNSPECIFIED,
    sp_cert,
    sp_key
)

idp_settings = IdPSettings(
    "https://idp.example.com/metadata/",
    Dict("url" => "https://idp.example.com/sso"),
    Dict("url" => "https://idp.example.com/slo"),
    idp_cert,
    "",
    ""
)

security_settings = SecuritySettings(
    false, false, false, false,
    RSA_SHA256, SHA256, true
)

settings = SAMLSettings(sp_settings, idp_settings, security_settings, true, false)

# Initiate login
request_data = Dict(
    "http_host" => "myapp.example.com",
    "script_name" => "/acs",
    "get_data" => Dict(),
    "post_data" => Dict(),
    "https" => "on"
)

auth = SAMLAuth(settings, request_data)
login_url = login(auth, return_to="/dashboard")
# Redirect user to login_url

# Process response from IdP
request_data["post_data"]["SAMLResponse"] = saml_response_from_idp
auth = SAMLAuth(settings, request_data)

if process_response(auth)
    attributes = get_attributes(auth)
    email = get_attribute(auth, "email")[1]
    # Create user session
end
```

## Documentation

- **[README.md](README.md)** - Complete API reference
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute quick start guide
- **[docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md)** - Architecture and design
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Production deployment guide
- **[docs/examples.jl](docs/examples.jl)** - Configuration examples
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contributing guidelines

## Supported Identity Providers

This package is compatible with any SAML 2.0 compliant Identity Provider, including:

- Okta
- Azure Active Directory / Microsoft 365
- Google Workspace
- Salesforce
- OneLogin
- Ping Identity
- AWS Single Sign-On
- Keycloak
- And many more...

## Architecture

The package is organized as follows:

```
src/
├── SAML.jl              # Main module
├── types.jl             # Type definitions
├── constants.jl         # SAML constants
├── utils.jl             # Utility functions
├── xml_utils.jl         # XML processing
├── crypto.jl            # Cryptographic stubs
├── authn_request.jl     # Request generation
├── response.jl          # Response processing
└── auth.jl              # Main auth handler
```

## Security

This package implements SAML 2.0 with:

- ✅ Assertion validation (issuer, status, timing)
- ✅ Certificate fingerprinting
- ✅ Strict mode for SAML compliance
- ⚠️ Signature validation (requires OpenSSL bindings)

**Important**: Always use HTTPS in production. SAML is designed for secure transport.

## Limitations

- Signature validation requires external OpenSSL bindings (stubs provided)
- Assertion encryption/decryption not yet implemented
- Single Logout (SLO) is framework-only pending signature support

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Priority areas for contribution:
- OpenSSL integration for signature validation
- Assertion encryption/decryption
- Additional authentication profiles
- Performance optimizations

## Development

### Setup

```bash
git clone https://github.com/yourusername/SAML.jl.git
cd SAML.jl
julia --project -e "using Pkg; Pkg.instantiate()"
```

### Testing

```bash
julia --project -e "using Pkg; Pkg.test()"
```

### Building Documentation

Documentation is in markdown format in the `docs/` directory.

## Roadmap

- [ ] OpenSSL integration for full signature support
- [ ] Assertion encryption/decryption
- [ ] Complete Single Logout implementation
- [ ] IdP metadata discovery and caching
- [ ] Session management helpers
- [ ] Logging framework integration
- [ ] Performance optimizations
- [ ] Julia Registry publication

## Comparison with python3-saml

This Julia implementation follows the architecture of the [python3-saml](https://github.com/onelogin/python3-saml) library but:

**Similarities:**
- SP-focused (client-side only)
- Settings-based configuration
- SAML 2.0 compliant
- Support for multiple bindings

**Differences:**
- Pure Julia (no C dependencies)
- Type-safe configuration
- Framework-agnostic
- Error handling without exceptions
- Minimal stdlib-only dependencies

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [python3-saml](https://github.com/onelogin/python3-saml)
- Built with [LightXML.jl](https://github.com/JuliaIO/LightXML.jl)
- Following SAML 2.0 specifications from OASIS

## Support

For issues, questions, or contributions, please:

1. Check existing [Issues](https://github.com/yourusername/SAML.jl/issues)
2. Review the [Documentation](docs/)
3. Create a new issue with detailed information

## Disclaimer

This is a community-maintained package. While it follows SAML 2.0 standards, always test thoroughly before deploying to production. Security is critical - consider having the implementation reviewed by security experts.

---

**Note**: Replace `yourusername` with your actual GitHub username in the URLs above.
