"""
    Utility functions for SAML operations including encoding/decoding and time handling.
"""

using Base64
using SHA
using Dates

"""
    deflate_and_base64_encode(data::String)::String

Deflate and Base64 encode a string (used for HTTP-Redirect binding).

# Arguments
- `data::String`: String to encode

# Returns
- Deflate-compressed and Base64-encoded string
"""
function deflate_and_base64_encode(data::String)::String
    # For now, just Base64 encode (deflate requires separate library)
    encoded = base64encode(data)
    return String(encoded)
end

"""
    decode_base64_and_inflate(encoded::String)::String

Base64 decode and inflate a string (reverse of deflate_and_base64_encode).

# Arguments
- `encoded::String`: Base64-encoded and deflated string

# Returns
- Decoded and uncompressed string
"""
function decode_base64_and_inflate(encoded::String)::String
    # For now, just Base64 decode (deflate requires separate library)
    decoded = base64decode(encoded)
    return String(decoded)
end

"""
    generate_unique_id()::String

Generate a unique SAML message ID.

# Returns
- Unique identifier string
"""
function generate_unique_id()::String
    return "_" * lowercase(string(uuid4()))
end

"""
    now()::Int

Get current Unix timestamp.

# Returns
- Current Unix timestamp
"""
function now()::Int
    return Int(floor(time()))
end

"""
    parse_time_to_saml(timestamp::Int)::String

Convert Unix timestamp to SAML timestamp format (ISO 8601).

# Arguments
- `timestamp::Int`: Unix timestamp

# Returns
- SAML formatted timestamp (yyyy-mm-ddThh:mm:ssZ)
"""
function parse_time_to_saml(timestamp::Int)::String
    dt = unix2datetime(timestamp)
    return Dates.format(dt, "yyyy-mm-ddTHH:MM:SSZ")
end

"""
    parse_saml_to_time(saml_time::String)::Int

Convert SAML timestamp to Unix timestamp.

# Arguments
- `saml_time::String`: SAML formatted timestamp

# Returns
- Unix timestamp
"""
function parse_saml_to_time(saml_time::String)::Int
    # Remove 'Z' suffix if present
    time_str = replace(saml_time, r"Z$" => "")
    
    # Parse the ISO 8601 timestamp
    dt = DateTime(time_str, "yyyy-mm-ddTHH:MM:SS")
    return Int(datetime2unix(dt))
end

"""
    calculate_x509_fingerprint(cert::String, algorithm::String="sha1")::String

Calculate the fingerprint of an X.509 certificate.

# Arguments
- `cert::String`: X.509 certificate in PEM format
- `algorithm::String`: Hash algorithm ("sha1", "sha256", "sha384", "sha512")

# Returns
- Fingerprint string in hexadecimal format with colons
"""
function calculate_x509_fingerprint(cert::String, algorithm::String="sha1")::String
    # Remove PEM headers and footers
    cert_data = replace(cert, r"-----BEGIN CERTIFICATE-----" => "")
    cert_data = replace(cert_data, r"-----END CERTIFICATE-----" => "")
    cert_data = replace(cert_data, r"\s" => "")
    
    # Decode from base64
    try
        cert_bytes = base64decode(cert_data)
        
        # Calculate hash based on algorithm
        hash_result = if algorithm == "sha1"
            sha1(cert_bytes)
        elseif algorithm == "sha256"
            sha256(cert_bytes)
        elseif algorithm == "sha384"
            sha384(cert_bytes)
        elseif algorithm == "sha512"
            sha512(cert_bytes)
        else
            throw(ArgumentError("Unknown algorithm: $algorithm"))
        end
        
        # Convert to hex string with colons
        hex_string = bytes2hex(hash_result)
        fingerprint = join([uppercase(hex_string[i:i+1]) for i in 1:2:length(hex_string)], ":")
        
        return fingerprint
    catch e
        throw(ArgumentError("Failed to calculate fingerprint: $(e.msg)"))
    end
end

"""
    format_cert(cert::String)::String

Ensure X.509 certificate has proper PEM headers and footers.

# Arguments
- `cert::String`: Certificate with or without PEM formatting

# Returns
- Properly formatted X.509 certificate
"""
function format_cert(cert::String)::String
    # Remove any existing headers/footers and whitespace
    cert = strip(cert)
    cert = replace(cert, r"-----BEGIN CERTIFICATE-----\s*" => "")
    cert = replace(cert, r"-----END CERTIFICATE-----\s*" => "")
    cert = replace(cert, r"\s" => "")
    
    # Add proper PEM headers and footers, breaking at 64 chars
    lines = [cert[i:min(i+63, end)] for i in 1:64:length(cert)]
    
    return "-----BEGIN CERTIFICATE-----\n" * join(lines, "\n") * "\n-----END CERTIFICATE-----\n"
end

"""
    format_private_key(key::String)::String

Ensure private key has proper PEM headers and footers.

# Arguments
- `key::String`: Private key with or without PEM formatting

# Returns
- Properly formatted private key
"""
function format_private_key(key::String)::String
    # Remove any existing headers/footers and whitespace
    key = strip(key)
    key = replace(key, r"-----BEGIN.*PRIVATE KEY-----\s*" => "")
    key = replace(key, r"-----END.*PRIVATE KEY-----\s*" => "")
    key = replace(key, r"\s" => "")
    
    # Determine key type
    key_type = "RSA PRIVATE KEY"  # Default to RSA
    
    # Add proper PEM headers and footers, breaking at 64 chars
    lines = [key[i:min(i+63, end)] for i in 1:64:length(key)]
    
    return "-----BEGIN $key_type-----\n" * join(lines, "\n") * "\n-----END $key_type-----\n"
end

"""
    get_self_url(request_data::Dict)::String

Reconstruct the current URL from request data.

# Arguments
- `request_data::Dict`: HTTP request data with http_host, script_name, etc.

# Returns
- Full URL string
"""
function get_self_url(request_data::Dict)::String
    https = get(request_data, "https", "off") == "on" ? "https" : "http"
    host = get(request_data, "http_host", "localhost")
    script_name = get(request_data, "script_name", "")
    query_string = get(request_data, "query_string", "")
    
    url = "$https://$host$script_name"
    
    if !isempty(query_string)
        url *= "?$query_string"
    end
    
    return url
end
