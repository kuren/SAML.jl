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

# ============================================================================
# Example 8: Validating SAML Responses with Certificate Verification
# ============================================================================

"""
    validate_with_certificate(saml_response_b64::String, idp_cert::String)

Validate a SAML response using the IdP's full X.509 certificate.

This function performs complete validation including:
- Certificate structure validation
- XML signature verification
- Assertion validation
- Time condition checks
- User attribute extraction

# Arguments
- `saml_response_b64`: The SAMLResponse value from browser (base64-encoded)
- `idp_cert`: The IdP's X.509 certificate in PEM format

# Returns
- `(is_valid::Bool, auth::SAMLAuth)`: Validation result and auth handler
"""
function validate_with_certificate(saml_response_b64::String, idp_cert::String)
    # Configure SAML settings with the IdP certificate
    settings = SAMLSettings(
        SPSettings(
            "https://myapp.example.com/metadata/",
            Dict("url" => "https://myapp.example.com/saml/acs",
                 "binding" => BINDING_HTTP_POST),
            Dict("url" => "https://myapp.example.com/saml/sls",
                 "binding" => BINDING_HTTP_REDIRECT),
            NAMEID_FORMAT_UNSPECIFIED,
            "", ""  # SP cert/key only needed if SP signs
        ),
        IdPSettings(
            "https://idp.example.com/metadata/",
            Dict("url" => "https://idp.example.com/sso"),
            Dict("url" => "https://idp.example.com/slo"),
            idp_cert,  # The certificate for signature verification
            "",        # No fingerprint
            "sha1"
        ),
        SecuritySettings(
            false, false,          # Don't require SP to sign
            true, true,            # Require assertions and messages to be signed
            RSA_SHA256, SHA256,    # Use SHA256 for signatures/digests
            true                   # Reject deprecated algorithms
        ),
        strict = true,   # Enforce strict SAML compliance
        debug = false    # Set to true for detailed validation logs
    )
    
    # Create request data from the POST
    request_data = Dict(
        "http_host" => "myapp.example.com",
        "script_name" => "/saml/acs",
        "get_data" => Dict(),
        "post_data" => Dict("SAMLResponse" => saml_response_b64),
        "https" => "on",
        "request_uri" => "/saml/acs"
    )
    
    # Initialize SAML handler
    auth = SAMLAuth(settings, request_data)
    
    # Process and validate the response (verifies signature using certificate)
    is_valid = process_response(auth)
    
    # Print results
    if is_valid
        println("\n✅ SUCCESS! SAML Response is VALID and signature verified\n")
        println("Authenticated user attributes:")
        
        attributes = get_attributes(auth)
        for (key, values) in attributes
            println("  $key => $(join(values, ", "))")
        end
        
    else
        println("\n❌ FAILED! SAML Response validation failed\n")
        println("Errors:")
        for error in auth.errors
            println("  - $error")
        end
    end
    
    return is_valid, auth
end

"""
    validate_with_fingerprint(saml_response_b64::String, idp_fingerprint::String, algorithm::String="sha256")

Validate a SAML response using a certificate fingerprint (more secure).

The certificate is extracted from the response and its fingerprint is verified
against the expected fingerprint. This avoids storing the full certificate.

# Arguments
- `saml_response_b64`: The SAMLResponse value from browser (base64)
- `idp_fingerprint`: Expected certificate fingerprint (e.g., "AA:BB:CC:DD:...")
- `algorithm`: Hash algorithm ("sha1" or "sha256")

# Returns
- `(is_valid::Bool, auth::SAMLAuth)`: Validation result and auth handler
"""
function validate_with_fingerprint(saml_response_b64::String, idp_fingerprint::String, algorithm::String="sha256")
    settings = SAMLSettings(
        SPSettings(
            "https://myapp.example.com/metadata/",
            Dict("url" => "https://myapp.example.com/saml/acs",
                 "binding" => BINDING_HTTP_POST),
            Dict("url" => "https://myapp.example.com/saml/sls",
                 "binding" => BINDING_HTTP_REDIRECT),
            NAMEID_FORMAT_UNSPECIFIED,
            "", ""
        ),
        IdPSettings(
            "https://idp.example.com/metadata/",
            Dict("url" => "https://idp.example.com/sso"),
            Dict("url" => "https://idp.example.com/slo"),
            "",                    # No full certificate
            idp_fingerprint,       # Use fingerprint instead
            algorithm              # SHA1 or SHA256
        ),
        SecuritySettings(
            false, false, true, true,
            RSA_SHA256, SHA256, true
        ),
        strict = true,
        debug = false
    )
    
    request_data = Dict(
        "http_host" => "myapp.example.com",
        "script_name" => "/saml/acs",
        "get_data" => Dict(),
        "post_data" => Dict("SAMLResponse" => saml_response_b64),
        "https" => "on",
        "request_uri" => "/saml/acs"
    )
    
    auth = SAMLAuth(settings, request_data)
    is_valid = process_response(auth)
    
    if is_valid
        println("\n✅ SUCCESS! SAML Response is VALID (fingerprint verified)\n")
        println("Authenticated user attributes:")
        
        attributes = get_attributes(auth)
        for (key, values) in attributes
            println("  $key => $(join(values, ", "))")
        end
        
    else
        println("\n❌ FAILED! SAML Response validation failed\n")
        println("Errors:")
        for error in auth.errors
            println("  - $error")
        end
    end
    
    return is_valid, auth
end

"""
    extract_and_save_idp_certificate(saml_response_b64::String, output_file::String)

Extract the IdP certificate from a SAML response and save it to a file.

This is useful for getting the certificate from the first successful login.

# Arguments
- `saml_response_b64`: The SAMLResponse from browser (base64-encoded)
- `output_file`: File path to save the certificate

# Returns
- Certificate string or nothing if extraction fails
"""
function extract_and_save_idp_certificate(saml_response_b64::String, output_file::String)
    try
        decoded = base64decode(saml_response_b64)
        xml_string = String(decoded)
        
        cert = extract_certificate_from_xml(xml_string)
        
        if cert !== nothing
            write(output_file, cert)
            println("✅ Certificate extracted and saved to: $output_file")
            return cert
        else
            println("❌ Could not extract certificate from response")
            return nothing
        end
        
    catch e
        println("❌ Error extracting certificate: $(e.msg)")
        return nothing
    end
end

"""
    verify_certificate_fingerprint(cert::String, expected_fingerprint::String, algorithm::String="sha256")

Verify that a certificate's fingerprint matches the expected value.

Useful for manual verification or testing.

# Arguments
- `cert`: X.509 certificate in PEM format
- `expected_fingerprint`: Expected fingerprint value
- `algorithm`: Hash algorithm ("sha1" or "sha256")

# Returns
- true if fingerprint matches, false otherwise
"""
function verify_certificate_fingerprint(cert::String, expected_fingerprint::String, algorithm::String="sha256")
    actual_fingerprint = calculate_x509_fingerprint(cert, algorithm)
    
    if actual_fingerprint == expected_fingerprint
        println("✅ Certificate fingerprint MATCHES!")
        return true
    else
        println("❌ Certificate fingerprint DOES NOT match!")
        println("  Expected: $expected_fingerprint")
        println("  Actual:   $actual_fingerprint")
        return false
    end
end

# ============================================================================
# Example 9: How to Extract and Validate SAML Responses
# ============================================================================

"""
    decode_saml_response(saml_response_b64::String)

Decode a base64-encoded SAML response to see the actual XML.

Useful for debugging or extracting the certificate manually.

# Arguments
- `saml_response_b64`: Base64-encoded SAML response

# Prints
- The decoded XML content
"""
function decode_saml_response(saml_response_b64::String)
    decoded = base64decode(saml_response_b64)
    xml_string = String(decoded)
    println(xml_string)
end

"""
SAML Response Validation Workflow:

1. EXTRACT the SAML Response from browser:
   - Open Dev Tools (F12)
   - Go to Network tab
   - Find POST request to /saml/acs
   - Copy the SAMLResponse parameter (long base64 string)

2. GET the IdP certificate:
   Option A: Extract from response (automated)
      decoded = base64decode(saml_response)
      cert = extract_certificate_from_xml(String(decoded))
   
   Option B: Get from IdP metadata or provider
      Ask your IdP for their SAML metadata or certificate
   
   Option C: Use certificate fingerprint (most secure)
      Ask your IdP for their certificate fingerprint (SHA1 or SHA256)

3. VALIDATE the response:
   # Using full certificate:
   idp_cert = read("idp-certificate.pem", String)
   is_valid, auth = validate_with_certificate(saml_response, idp_cert)
   
   # OR using fingerprint:
   fingerprint = "AA:BB:CC:DD:..."
   is_valid, auth = validate_with_fingerprint(saml_response, fingerprint)

4. EXTRACT user information:
   if is_valid
       attributes = get_attributes(auth)
       email = get_attribute(auth, "email")
       # Create session, set cookies, etc.
   end

BENEFITS OF THE THREE VALIDATION APPROACHES:

- Full Certificate: Works with any IdP, but requires storing/managing certificates
- Fingerprint: Most secure, simpler, but requires IdP to provide fingerprint upfront
- Extract from Response: Good for initial setup, but fingerprint method is safer for ongoing use
"""
