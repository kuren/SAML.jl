# SAML Julia Package - Deployment Guide

## Preparation Checklist

Before deploying a Julia application with SAML support, ensure you have:

- [ ] IdP metadata (XML file) or endpoint
- [ ] IdP X.509 certificate (or certificate fingerprint)
- [ ] Service Provider entity ID (typically your app domain)
- [ ] Assertion Consumer Service (ACS) URL
- [ ] Single Logout Service (SLS) URL
- [ ] Service Provider certificate and private key (if signing is required)

## Step 1: Obtain IdP Metadata

### Option A: From IdP Website
Most IdPs provide metadata as an XML file at a public URL:
- Okta: `https://[org].okta.com/app/[appid]/sso/saml/metadata`
- Azure AD: `https://login.microsoftonline.com/[tenant]/samlp/metadata`
- Google: `https://accounts.google.com/o/saml2/idp?idpid=[id]`
- OneLogin: See connector settings for metadata URL

### Option B: Request from Administrator
If the IdP doesn't publish metadata, request:
- Single Sign-On URL
- Single Logout URL
- X.509 Certificate

## Step 2: Extract IdP Information

From the metadata XML, extract:

```xml
<!-- Identity Provider URL -->
<SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="..."/>

<!-- Certificate -->
<KeyDescriptor use="signing">
    <KeyInfo>
        <X509Certificate>...</X509Certificate>
    </KeyInfo>
</KeyDescriptor>
```

## Step 3: Generate Service Provider Certificates

If the IdP requires signed requests:

```bash
# Generate private key
openssl genrsa -out sp.key 2048

# Generate certificate (self-signed, valid for 1 year)
openssl req -new -x509 -key sp.key -out sp.crt -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

# Or for 10 years (production)
openssl req -new -x509 -key sp.key -out sp.crt -days 3650 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"
```

Then configure IdP with:
- SP Entity ID: `https://yourapp.com/metadata/`
- ACS URL: `https://yourapp.com/saml/acs`
- SLS URL: `https://yourapp.com/saml/sls` (optional, for logout)
- SP Certificate: Upload `sp.crt` file

## Step 4: Store Certificates Securely

```julia
# In your application configuration
config = Dict(
    "sp" => Dict(
        "entity_id" => "https://yourapp.com/metadata/",
        "assertion_consumer_service" => Dict(
            "url" => "https://yourapp.com/saml/acs",
            "binding" => BINDING_HTTP_POST
        ),
        "single_logout_service" => Dict(
            "url" => "https://yourapp.com/saml/sls",
            "binding" => BINDING_HTTP_REDIRECT
        ),
        "x509_cert" => read("./certs/sp.crt", String),
        "private_key" => read("./certs/sp.key", String)
    ),
    "idp" => Dict(
        "entity_id" => "https://idp.example.com/metadata/",
        "single_sign_on_service" => Dict(
            "url" => "https://idp.example.com/sso"
        ),
        "x509_cert" => read("./certs/idp.crt", String)
    )
)
```

## Step 5: Implement SAML Endpoints

### Login Endpoint

```julia
function saml_login(request)
    settings = load_saml_settings()
    request_data = parse_request(request)
    
    auth = SAMLAuth(settings, request_data)
    
    # Store request ID for validation
    session["saml_request_id"] = get_last_request_id(auth)
    
    # Get redirect URL
    redirect_url = login(auth, return_to="/dashboard")
    
    return redirect(redirect_url)
end
```

### Assertion Consumer Service (ACS) Endpoint

```julia
function saml_acs(request)
    settings = load_saml_settings()
    request_data = parse_request(request)
    
    # Parse and validate SAML Response
    auth = SAMLAuth(settings, request_data)
    auth.last_request_id = session["saml_request_id"]
    
    if !process_response(auth)
        errors = get_errors(auth)
        return error_response("SAML validation failed: $(join(errors, ", "))")
    end
    
    # Extract user information
    nameid = get_nameid(auth)
    attributes = get_attributes(auth)
    email = get(attributes, "email", [""])[1]
    name = get(attributes, "name", [""])[1]
    
    # Create or update user session
    session["user_id"] = nameid
    session["email"] = email
    session["name"] = name
    
    # Redirect to requested page or dashboard
    return redirect(get(request_data["get_data"], "RelayState", "/dashboard"))
end
```

### Metadata Endpoint

```julia
function saml_metadata(request)
    settings = load_saml_settings()
    request_data = parse_request(request)
    
    auth = SAMLAuth(settings, request_data)
    metadata = get_sp_metadata(auth)
    
    return response(metadata, content_type="application/xml")
end
```

### Single Logout Endpoint (Optional)

```julia
function saml_sls(request)
    settings = load_saml_settings()
    request_data = parse_request(request)
    
    auth = SAMLAuth(settings, request_data)
    
    if process_slo(auth)
        # Clear session
        session.clear()
        return redirect("/")
    else
        errors = get_errors(auth)
        return error_response("Logout failed: $(join(errors, ", "))")
    end
end
```

## Step 6: Configure Web Framework Routes

### For Genie.jl

```julia
using Genie, Genie.Router

route("/login", method=POST, saml_login)
route("/saml/acs", method=POST, saml_acs)
route("/saml/metadata", method=GET, saml_metadata)
route("/saml/sls", method=GET, saml_sls)
```

### For HTTP.jl

```julia
using HTTP

HTTP.listen("0.0.0.0", 8000) do req
    if req.method == "POST" && req.target == "/saml/acs"
        return saml_acs(req)
    elseif req.method == "GET" && req.target == "/saml/metadata"
        return saml_metadata(req)
    elseif req.method == "POST" && req.target == "/login"
        return saml_login(req)
    end
end
```

## Step 7: Security Configuration

### Production Settings

```julia
security_settings = SecuritySettings(
    true,               # Sign AuthnRequests
    true,               # Sign LogoutRequests
    true,               # Require signed assertions
    true,               # Require signed messages
    RSA_SHA256,
    SHA256,
    true                # Reject deprecated algorithms
)
```

### Important Security Practices

1. **HTTPS Only**: Never use HTTP for SAML
   ```julia
   @assert settings.request_data["https"] == "on"
   ```

2. **Validate RelayState**:
   ```julia
   relay_state = request_data["post_data"]["RelayState"]
   valid_urls = ["/dashboard", "/profile", "/home"]
   @assert relay_state in valid_urls
   ```

3. **Prevent Replay Attacks**:
   ```julia
   # Store processed message IDs with expiration
   processed_ids[message_id] = (timestamp, ttl)
   @assert !haskey(processed_ids, message_id)
   ```

4. **Protect Certificates**:
   - Store in secure file system
   - Use environment variables for secrets
   - Rotate regularly
   - Use strong key sizes (>= 2048 bits)

5. **Validate Timestamps**:
   ```julia
   # SAML automatically validates, but check:
   @assert response.assertion.not_on_or_after > now()
   ```

## Step 8: Testing

### Unit Tests

```julia
using Test, SAML

@testset "SAML Integration" begin
    settings = load_test_settings()
    
    @testset "Login URL generation" begin
        auth = SAMLAuth(settings, test_request_data)
        url = login(auth)
        @test contains(url, "SAMLRequest")
    end
    
    @testset "Response validation" begin
        # Use test SAML response from IdP
        auth = SAMLAuth(settings, test_response_data)
        @test process_response(auth)
    end
end
```

### Integration Testing with IdP

1. Configure test user account at IdP
2. Test login flow end-to-end
3. Verify attributes are correctly mapped
4. Test single logout if implemented
5. Test certificate rotation

## Step 9: Monitoring and Maintenance

### Log Key Events

```julia
function log_saml_event(event::String, details::Dict)
    @info "SAML Event" event=event details=details timestamp=now()
end

log_saml_event("login_initiated", Dict("user_agent" => request.headers["User-Agent"]))
log_saml_event("auth_success", Dict("nameid" => nameid, "attributes" => keys(attributes)))
log_saml_event("auth_failure", Dict("error" => error_reason))
```

### Monitor Error Rates

```julia
# Track failed authentications
failed_logins[nameid] = [timestamp, timestamp, ...]

# Alert if too many failures
if length(failed_logins[nameid]) > 5
    send_alert("Multiple failed logins for $nameid")
end
```

### Certificate Expiration

```julia
function check_certificate_expiration(cert_path::String)
    # Check certificate expiration
    # Warn 30 days before expiration
end

schedule_check(() -> check_certificate_expiration("./certs/sp.crt"), every=24*60*60)
```

## Step 10: Troubleshooting

### Common Issues

1. **"Invalid issuer" error**
   - Check IdP entity ID matches configuration
   - Verify metadata is up to date

2. **"SAML Response not found" error**
   - Ensure ACS URL in IdP configuration matches app URL
   - Check that POST binding is being used

3. **"Assertion expired" error**
   - Check server time synchronization (NTP)
   - Increase time tolerance if needed

4. **Signature validation failures**
   - Verify IdP certificate is correct
   - Check that signing algorithms match IdP settings
   - Regenerate certificates if old

5. **"Destination mismatch" error**
   - Ensure ACS URL in response matches request
   - Check for trailing slashes or protocol differences

### Debug Mode

```julia
# Enable debug output
settings.debug = true

# Log all request/response details
auth = SAMLAuth(settings, request_data)
@debug "SAML Request" request=auth.last_request_id
if !process_response(auth)
    @warn "SAML validation failed" errors=get_errors(auth)
end
```

## Deployment Checklist

- [ ] IdP is configured with your SP metadata
- [ ] HTTPS is enabled (required for SAML)
- [ ] Certificates are generated and securely stored
- [ ] All endpoints are configured and accessible
- [ ] Logging is set up for monitoring
- [ ] Error handling is comprehensive
- [ ] Security settings are appropriate for production
- [ ] Testing with IdP has been successful
- [ ] Monitoring and alerts are configured
- [ ] Backup plan for certificate rotation exists
- [ ] Team is trained on troubleshooting
- [ ] Documentation is updated for your setup

## Post-Deployment

1. Monitor login success rates
2. Track error patterns
3. Plan certificate renewal (90 days before expiration)
4. Review security settings quarterly
5. Keep IdP metadata synchronized
6. Monitor for suspicious login patterns
