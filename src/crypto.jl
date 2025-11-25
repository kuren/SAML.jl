"""
    Cryptographic operations for SAML (signing and verification).
    
Implements RSA signature operations using OpenSSL.jl for SAML assertions.
"""

using OpenSSL
using Base64

"""
    sign_data(data::String, private_key::String, algorithm::String)::String

Sign data with a private key using RSA.

# Arguments
- `data::String`: Data to sign
- `private_key::String`: Private key in PEM format
- `algorithm::String`: Signature algorithm ("RSA-SHA256", "RSA-SHA1", etc.)

# Returns
- Base64-encoded signature
"""
function sign_data(data::String, private_key::String, algorithm::String)::String
    try
        # Parse the private key - create EvpPKey from PEM
        key = OpenSSL.EvpPKey(private_key)
        
        # Determine hash algorithm
        hash_type = if startswith(algorithm, "RSA-SHA256")
            OpenSSL.EvpSHA256
        elseif startswith(algorithm, "RSA-SHA1")
            OpenSSL.EvpSHA1
        elseif startswith(algorithm, "RSA-SHA512")
            OpenSSL.EvpSHA512
        else
            OpenSSL.EvpSHA256  # Default to SHA256
        end
        
        # Create digest context and sign
        ctx = OpenSSL.EvpDigestContext(hash_type)
        OpenSSL.digest_init(ctx)
        OpenSSL.digest_update(ctx, Vector{UInt8}(data))
        digest = OpenSSL.digest_final(ctx)
        
        # Sign the digest - use RSA
        signature_bytes = OpenSSL.sign(key, digest)
        
        # Return Base64-encoded signature
        return String(base64encode(signature_bytes))
        
    catch e
        throw(ArgumentError("Failed to sign data: $(e.msg)"))
    end
end

"""
    verify_signature(data::String, signature::String, certificate::String, algorithm::String)::Bool

Verify a signature on data using a certificate's public key.

# Arguments
- `data::String`: Original data that was signed
- `signature::String`: Base64-encoded signature
- `certificate::String`: X.509 certificate in PEM format
- `algorithm::String`: Signature algorithm

# Returns
- true if signature is valid, false otherwise
"""
function verify_signature(data::String, signature::String, certificate::String, algorithm::String)::Bool
    try
        # Decode the signature from Base64
        signature_bytes = base64decode(signature)
        
        # For robust RSA signature verification, we use the openssl command-line tool
        # This is more reliable than trying to use OpenSSL.jl's limited API
        
        # Write temporary files for verification
        data_file = tempname()
        sig_file = tempname()
        cert_file = tempname()
        
        try
            # Write data to file
            write(data_file, data)
            
            # Write signature to file
            write(sig_file, signature_bytes)
            
            # Write certificate to file
            write(cert_file, certificate)
            
            # Use openssl command to verify the signature
            # Convert signature algorithm to openssl format
            digest_algo = if startswith(algorithm, "RSA-SHA256")
                "sha256"
            elseif startswith(algorithm, "RSA-SHA1")
                "sha1"
            elseif startswith(algorithm, "RSA-SHA512")
                "sha512"
            else
                "sha256"
            end
            
            # Run openssl verify command
            cmd = `openssl dgst -$digest_algo -verify <(openssl x509 -in $cert_file -noout -pubkey) -signature $sig_file $data_file`
            
            try
                run(cmd, wait=true)
                return true
            catch
                return false
            end
            
        finally
            # Clean up temporary files
            try; rm(data_file); catch; end
            try; rm(sig_file); catch; end
            try; rm(cert_file); catch; end
        end
        
    catch e
        # Signature verification failed
        return false
    end
end

"""
    sign_xml_element(element_xml::String, reference_uri::String, private_key::String, 
                     certificate::String, algorithm::String)::String

Sign an XML element and return the modified XML with an embedded signature.

# Arguments
- `element_xml::String`: XML element to sign
- `reference_uri::String`: URI reference for the signature (e.g., "#_request_id")
- `private_key::String`: Private key in PEM format
- `certificate::String`: Certificate in PEM format
- `algorithm::String`: Signature algorithm

# Returns
- XML with embedded Signature element
"""
function sign_xml_element(element_xml::String, reference_uri::String, private_key::String, 
                         certificate::String, algorithm::String)::String
    try
        # For full XML signing, we need proper canonicalization
        # This is a simplified implementation
        
        signature_b64 = sign_data(element_xml, private_key, algorithm)
        
        # Create the Signature element
        cert_b64 = replace(certificate, r"-----BEGIN CERTIFICATE-----" => "", 
                                       r"-----END CERTIFICATE-----" => "",
                                       r"\s" => "")
        
        # Calculate digest of the signed element
        ctx = OpenSSL.EvpDigestContext(OpenSSL.EvpSHA256)
        OpenSSL.digest_init(ctx)
        OpenSSL.digest_update(ctx, Vector{UInt8}(element_xml))
        digest_bytes = OpenSSL.digest_final(ctx)
        digest_b64 = String(base64encode(digest_bytes))
        
        signature_xml = """
        <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
            <ds:SignedInfo>
                <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                <ds:Reference URI="$reference_uri">
                    <ds:Transforms>
                        <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                    </ds:Transforms>
                    <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                    <ds:DigestValue>$digest_b64</ds:DigestValue>\n                </ds:Reference>
            </ds:SignedInfo>
            <ds:SignatureValue>$signature_b64</ds:SignatureValue>
            <ds:KeyInfo>
                <ds:X509Data>
                    <ds:X509Certificate>$cert_b64</ds:X509Certificate>
                </ds:X509Data>
            </ds:KeyInfo>
        </ds:Signature>
        """
        
        # Return the signed XML
        return element_xml * signature_xml
        
    catch e
        throw(ArgumentError("Failed to sign XML element: $(e.msg)"))
    end
end

"""
    verify_xml_signature(xml::String, certificate::String)::Bool

Verify an XML signature in a SAML assertion.

# Arguments
- `xml::String`: XML document with Signature element
- `certificate::String`: Certificate to verify against (PEM format)

# Returns
- true if signature is valid, false otherwise

# Note:
The Signature element can be nested inside other elements (like Assertion).
This function searches recursively to find it.
"""
function verify_xml_signature(xml::String, certificate::String)::Bool
    try
        # Parse the XML to extract signature and reference
        xml_doc = parse_xml(xml)
        if xml_doc === nothing
            return false
        end
        
        root = root_element(xml_doc)
        
        # Find the Signature element (may be nested inside Assertion or Response)
        signature_elem = query_element(root, "Signature")
        
        # If not found at root level, search inside Assertion
        if signature_elem === nothing
            assertion_elem = query_element(root, "Assertion")
            if assertion_elem !== nothing
                signature_elem = query_element(assertion_elem, "Signature")
            end
        end
        
        # If still not found, search inside Response (for Response-level signatures)
        if signature_elem === nothing
            response_elem = query_element(root, "Response")
            if response_elem !== nothing
                signature_elem = query_element(response_elem, "Signature")
            end
        end
        
        if signature_elem === nothing
            return false
        end
        
        # Extract SignatureValue
        sig_value_elem = query_element(signature_elem, "SignatureValue")
        if sig_value_elem === nothing
            return false
        end
        signature_b64 = get_element_text(sig_value_elem)
        
        # Extract the data that was signed (the parent element without the signature)
        # For SAML assertions, this is typically the Assertion element
        signed_data_xml = string(root)  # Simplified - in production, need proper canonicalization
        
        # Verify the signature
        return verify_signature(signed_data_xml, signature_b64, certificate, "RSA-SHA256")
        
    catch e
        return false
    end
end

"""
    extract_certificate_from_xml(xml::String)::Union{String, Nothing}

Extract X.509 certificate from an XML Signature element.

# Arguments
- `xml::String`: XML containing embedded certificate in KeyInfo/X509Certificate

# Returns
- Certificate in PEM format or nothing if not found
"""
function extract_certificate_from_xml(xml::String)::Union{String, Nothing}
    try
        xml_doc = parse_xml(xml)
        if xml_doc === nothing
            return nothing
        end
        
        root = root_element(xml_doc)
        
        # Look for Signature/KeyInfo/X509Data/X509Certificate
        # Try at root level first
        signature = query_element(root, "Signature")
        
        # If not found at root, search inside Assertion
        if signature === nothing
            assertion_elem = query_element(root, "Assertion")
            if assertion_elem !== nothing
                signature = query_element(assertion_elem, "Signature")
            end
        end
        
        # If still not found, search inside Response
        if signature === nothing
            response_elem = query_element(root, "Response")
            if response_elem !== nothing
                signature = query_element(response_elem, "Signature")
            end
        end
        
        if signature === nothing
            return nothing
        end
        
        key_info = query_element(signature, "KeyInfo")
        if key_info === nothing
            return nothing
        end
        
        x509_data = query_element(key_info, "X509Data")
        if x509_data === nothing
            return nothing
        end
        
        x509_cert = query_element(x509_data, "X509Certificate")
        if x509_cert === nothing
            return nothing
        end
        
        cert_content = get_element_text(x509_cert)
        
        # Format as PEM certificate
        if !isempty(cert_content)
            # Clean up the content
            cert_clean = replace(cert_content, r"\s" => "")
            
            # Add PEM headers
            pem_lines = [cert_clean[i:min(i+63, end)] for i in 1:64:length(cert_clean)]
            return "-----BEGIN CERTIFICATE-----\n" * join(pem_lines, "\n") * "\n-----END CERTIFICATE-----\n"
        end
        
    catch e
        # Return nothing if extraction fails
    end
    
    return nothing
end

"""
    verify_certificate_with_pubkey(certificate::String, signature::String, data::String, algorithm::String)::Bool

Direct certificate verification with public key extraction.

# Arguments
- `certificate::String`: X.509 certificate in PEM format
- `signature::String`: Base64-encoded signature
- `data::String`: Original data that was signed
- `algorithm::String`: Signature algorithm

# Returns
- true if signature is valid, false otherwise
"""
function verify_certificate_with_pubkey(certificate::String, signature::String, data::String, algorithm::String)::Bool
    return verify_signature(data, signature, certificate, algorithm)
end
