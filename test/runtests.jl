using Test
using SAML

@testset "SAML Utils" begin
    # Test Base64 and Deflate
    test_string = "Hello, SAML!"
    encoded = deflate_and_base64_encode(test_string)
    decoded = decode_base64_and_inflate(encoded)
    
    @test decoded == test_string
end

@testset "SAML Certificate Fingerprint" begin
    # Test fingerprint calculation (with a sample cert structure)
    # This would need a real certificate in production
    cert = """-----BEGIN CERTIFICATE-----
MIICajCCAdOgAwIBAgIBATANBgkqhkiG9w0BAQQFADBNMQswCQYDVQQGEwJ1czEV
MBMGA1UEChMMRGlnaXRhbCBDZXJ0MQswCQYDVQQLEwJDQTEVMBMGA1UEAxMMRGln
aXRhbCBDZXJ0MB4XDTk2MDMwODAxNDI0M1oXDTA2MDMwNjAxNDI0M1owTTELMAkG
A1UEBhMCdXMxFTATBgNVBAoTDERpZ2l0YWwgQ2VydDELMAkGA1UECxMCQ0ExFTAT
BgNVBAMTDERpZ2l0YWwgQ2VydDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA
l5f1sUcTaM3Z1xV2HVBS8p1hMc9C+VNFCrVr7mRgKArBlI9FNGxk4lfAqDG8ysqQ
V6P1PfKDQPQ9yfbv2NxLkK6QjGVS7PaTrNLEZVq2/OoTLM4V5SJVVnC/Q5zCxGLs
K3lZyQCZP5qXlCWnTK6bJvFvJYKfXfB5nfr6sL/1QxMCAwEAAaMTMBEwDwYDVR0T
AQH/BAUwAwEB/zANBgkqhkiG9w0BAQQFAAOBgQBvP5z3pjmKc8z8ixqqwGDQbQFH
BqhyLl7Jxb3DYxbSwAVqp0HqiJcCGYNViFVm6dJi4e2ueRJm8j8X9n5MzqWMkDhX
lLRyEj4pEqqLDWHxMGjg3i0H4X3s8dKVkLJRWQIr0B8ydIxFqJT6F7cKzKiqksFe
ELdqPeNZrG/tJL7RGQ==
-----END CERTIFICATE-----"""
    
    # Test that function exists and doesn't crash
    fingerprint = calculate_x509_fingerprint(cert, "sha1")
    @test !isempty(fingerprint)
    @test contains(fingerprint, ":")  # Fingerprints have colons
end

@testset "SAML Settings Creation" begin
    sp_settings = SPSettings(
        "https://example.com/metadata/",
        Dict("url" => "https://example.com/acs", "binding" => BINDING_HTTP_POST),
        Dict("url" => "https://example.com/sls", "binding" => BINDING_HTTP_REDIRECT),
        NAMEID_FORMAT_UNSPECIFIED,
        "",
        ""
    )
    
    idp_settings = IdPSettings(
        "https://idp.example.com/metadata/",
        Dict("url" => "https://idp.example.com/sso"),
        Dict("url" => "https://idp.example.com/slo"),
        "",
        "",
        "sha1"
    )
    
    security_settings = SecuritySettings(
        false,
        false,
        false,
        false,
        SAML.RSA_SHA256,
        SAML.SHA256,
        true
    )
    
    settings = SAMLSettings(sp_settings, idp_settings, security_settings, true, false)
    
    @test settings.sp.entity_id == "https://example.com/metadata/"
    @test settings.idp.entity_id == "https://idp.example.com/metadata/"
    @test settings.security.signature_algorithm == SAML.RSA_SHA256
end

@testset "SAML Auth Handler" begin
    sp_settings = SPSettings(
        "https://example.com/metadata/",
        Dict("url" => "https://example.com/acs", "binding" => BINDING_HTTP_POST),
        Dict("url" => "https://example.com/sls", "binding" => BINDING_HTTP_REDIRECT),
        NAMEID_FORMAT_UNSPECIFIED,
        "",
        ""
    )
    
    idp_settings = IdPSettings(
        "https://idp.example.com/metadata/",
        Dict("url" => "https://idp.example.com/sso"),
        Dict("url" => "https://idp.example.com/slo"),
        "",
        "",
        "sha1"
    )
    
    security_settings = SecuritySettings(
        false,
        false,
        false,
        false,
        SAML.RSA_SHA256,
        SAML.SHA256,
        true
    )
    
    settings = SAMLSettings(sp_settings, idp_settings, security_settings, true, false)
    
    request_data = Dict(
        "http_host" => "example.com",
        "script_name" => "/acs",
        "get_data" => Dict(),
        "post_data" => Dict(),
        "https" => "on"
    )
    
    auth = SAMLAuth(settings, request_data)
    
    @test !is_authenticated(auth)
    @test isempty(get_errors(auth))
    
    # Test login URL generation
    login_url = login(auth)
    @test !isempty(login_url)
    @test contains(login_url, "SAMLRequest")
    @test !isempty(auth.last_request_id)
end
