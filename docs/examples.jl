"""
Example SAML Configuration

This file demonstrates how to configure the SAML client for your IdP.
"""

using SAML

# Example 1: Basic Configuration
function create_example_settings()
    # Service Provider Configuration
    sp_settings = SPSettings(
        "https://myapp.example.com/metadata/",  # Entity ID (must be a URI)
        Dict(
            "url" => "https://myapp.example.com/saml/acs",
            "binding" => BINDING_HTTP_POST
        ),
        Dict(
            "url" => "https://myapp.example.com/saml/sls",
            "binding" => BINDING_HTTP_REDIRECT
        ),
        NAMEID_FORMAT_UNSPECIFIED,
        # For actual certs, read from files:
        # sp_cert = read("/path/to/sp.crt"),
        # sp_key = read("/path/to/sp.key")
        "",  # x509_cert placeholder
        ""   # private_key placeholder
    )
    
    # Identity Provider Configuration
    idp_settings = IdPSettings(
        "https://idp.example.com/app/metadata/",  # IdP Entity ID
        Dict(
            "url" => "https://idp.example.com/app/sso"
        ),
        Dict(
            "url" => "https://idp.example.com/app/slo"
        ),
        # Read IdP certificate from IdP metadata or provide directly:
        # idp_cert = read("/path/to/idp.crt"),
        "",  # x509_cert placeholder
        "",  # cert_fingerprint (alternative to full cert)
        "sha1"  # fingerprint_algorithm
    )
    
    # Security Settings
    security_settings = SecuritySettings(
        false,              # Don't sign AuthnRequests (IdP may not require)
        false,              # Don't sign LogoutRequests
        false,              # Don't require signed assertions (adjust as needed)
        false,              # Don't require signed messages
        RSA_SHA256,         # Use SHA256 for signatures
        SHA256,             # Use SHA256 for digest
        true                # Reject deprecated algorithms
    )
    
    # Create main settings object
    settings = SAMLSettings(
        sp_settings,
        idp_settings,
        security_settings,
        true,               # Strict mode (validate everything)
        false               # Debug mode (set to true for development)
    )
    
    return settings
end

# Example 2: Configuration with Certificates
function create_settings_with_certs(sp_cert_path, sp_key_path, idp_cert_path)
    sp_cert = read(sp_cert_path, String)
    sp_key = read(sp_key_path, String)
    idp_cert = read(idp_cert_path, String)
    
    sp_settings = SPSettings(
        "https://myapp.example.com/metadata/",
        Dict("url" => "https://myapp.example.com/saml/acs", "binding" => BINDING_HTTP_POST),
        Dict("url" => "https://myapp.example.com/saml/sls", "binding" => BINDING_HTTP_REDIRECT),
        NAMEID_FORMAT_UNSPECIFIED,
        sp_cert,
        sp_key
    )
    
    idp_settings = IdPSettings(
        "https://idp.example.com/app/metadata/",
        Dict("url" => "https://idp.example.com/app/sso"),
        Dict("url" => "https://idp.example.com/app/slo"),
        idp_cert,
        "",
        "sha1"
    )
    
    security_settings = SecuritySettings(
        true,               # Sign AuthnRequests
        true,               # Sign LogoutRequests
        true,               # Require signed assertions
        true,               # Require signed messages
        RSA_SHA256,
        SHA256,
        true
    )
    
    return SAMLSettings(sp_settings, idp_settings, security_settings, true, false)
end

# Example 3: Configuration with Fingerprint
function create_settings_with_fingerprint(sp_cert_path, sp_key_path, idp_fingerprint)
    sp_cert = read(sp_cert_path, String)
    sp_key = read(sp_key_path, String)
    
    sp_settings = SPSettings(
        "https://myapp.example.com/metadata/",
        Dict("url" => "https://myapp.example.com/saml/acs", "binding" => BINDING_HTTP_POST),
        Dict("url" => "https://myapp.example.com/saml/sls", "binding" => BINDING_HTTP_REDIRECT),
        NAMEID_FORMAT_UNSPECIFIED,
        sp_cert,
        sp_key
    )
    
    idp_settings = IdPSettings(
        "https://idp.example.com/app/metadata/",
        Dict("url" => "https://idp.example.com/app/sso"),
        Dict("url" => "https://idp.example.com/app/slo"),
        "",                 # No full cert, using fingerprint instead
        idp_fingerprint,    # e.g., "AA:BB:CC:DD:..."
        "sha256"            # SHA256 fingerprint
    )
    
    security_settings = SecuritySettings(true, true, true, true, RSA_SHA256, SHA256, true)
    
    return SAMLSettings(sp_settings, idp_settings, security_settings, true, false)
end

# Example 4: Using in a Web Framework

"""
    configure_saml_handler(settings::SAMLSettings, request)

Helper function to set up SAML handler for a web request.
"""
function configure_saml_handler(settings::SAMLSettings, request)
    # Parse HTTP request into SAML request format
    request_data = Dict(
        "http_host" => request.host,
        "script_name" => request.path,
        "get_data" => request.query,
        "post_data" => request.body,
        "https" => request.scheme == "https" ? "on" : "off",
        "request_uri" => request.uri
    )
    
    return SAMLAuth(settings, request_data)
end

# Example 5: Loading from JSON Configuration

"""
    load_settings_from_json(json_file::String)

Load SAML settings from a JSON configuration file.
"""
function load_settings_from_json(json_file::String)
    using JSON
    
    config = JSON.parsefile(json_file)
    
    # Parse configuration
    sp_config = config["sp"]
    idp_config = config["idp"]
    security_config = get(config, "security", Dict())
    
    # Create settings objects
    sp_settings = SPSettings(
        sp_config["entity_id"],
        sp_config["assertion_consumer_service"],
        sp_config["single_logout_service"],
        get(sp_config, "name_id_format", NAMEID_FORMAT_UNSPECIFIED),
        get(sp_config, "x509_cert", ""),
        get(sp_config, "private_key", "")
    )
    
    idp_settings = IdPSettings(
        idp_config["entity_id"],
        idp_config["single_sign_on_service"],
        idp_config["single_logout_service"],
        get(idp_config, "x509_cert", ""),
        get(idp_config, "cert_fingerprint", ""),
        get(idp_config, "cert_fingerprint_algorithm", "sha1")
    )
    
    security_settings = SecuritySettings(
        get(security_config, "authn_requests_signed", false),
        get(security_config, "logout_requests_signed", false),
        get(security_config, "want_assertions_signed", false),
        get(security_config, "want_messages_signed", false),
        get(security_config, "signature_algorithm", RSA_SHA256),
        get(security_config, "digest_algorithm", SHA256),
        get(security_config, "reject_deprecated_algorithm", true)
    )
    
    return SAMLSettings(
        sp_settings,
        idp_settings,
        security_settings,
        get(config, "strict", true),
        get(config, "debug", false)
    )
end

# Example 6: Common IdP Configurations

"""
Okta Configuration Template
"""
function okta_config(app_domain::String, org_domain::String)
    IdPSettings(
        "https://$org_domain/app/okta/$app_domain",
        Dict("url" => "https://$org_domain/app/okta/$app_domain/sso/saml"),
        Dict("url" => "https://$org_domain/app/okta/$app_domain/slo/saml"),
        "",
        "",
        "sha1"
    )
end

"""
Okta requires certificate download from their SAML metadata.
See https://developer.okta.com/docs/guides/saml-application-setup/overview/
"""

"""
Azure AD Configuration Template
"""
function azure_ad_config(tenant_id::String, app_id::String)
    IdPSettings(
        "urn:microsoft:adfs:claimsxray",
        Dict("url" => "https://login.microsoftonline.com/$tenant_id/saml2"),
        Dict("url" => "https://login.microsoftonline.com/$tenant_id/saml2"),
        "",
        "",
        "sha1"
    )
end

"""
Other popular IdPs may have similar configurations available in their documentation.
"""

# Example 7: Testing Your Configuration

function test_configuration(settings::SAMLSettings)
    println("Testing SAML Configuration...")
    println("=" * 50)
    
    println("Service Provider:")
    println("  Entity ID: $(settings.sp.entity_id)")
    println("  ACS URL: $(settings.sp.assertion_consumer_service["url"])")
    println("  SLS URL: $(settings.sp.single_logout_service["url"])")
    
    println("\nIdentity Provider:")
    println("  Entity ID: $(settings.idp.entity_id)")
    println("  SSO URL: $(settings.idp.single_sign_on_service["url"])")
    println("  SLO URL: $(settings.idp.single_logout_service["url"])")
    
    println("\nSecurity Settings:")
    println("  Strict Mode: $(settings.strict)")
    println("  AuthnRequests Signed: $(settings.security.authn_requests_signed)")
    println("  Assertions Signed: $(settings.security.want_assertions_signed)")
    
    println("\nTesting login URL generation...")
    request_data = Dict(
        "http_host" => "example.com",
        "script_name" => "/acs",
        "get_data" => Dict(),
        "post_data" => Dict(),
        "https" => "on"
    )
    
    auth = SAMLAuth(settings, request_data)
    login_url = login(auth)
    
    if contains(login_url, "SAMLRequest")
        println("✓ Login URL generated successfully")
        println("  URL length: $(length(login_url)) chars")
    else
        println("✗ Failed to generate login URL")
    end
    
    println("=" * 50)
    println("Configuration test complete!")
end
