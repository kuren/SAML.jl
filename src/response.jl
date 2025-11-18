"""
    SAML Response parsing and validation.
"""

"""
    parse_saml_response(settings::SAMLSettings, request_data::Dict)::SAMLResponse

Parse and decode a SAML Response from HTTP request data.

# Arguments
- `settings::SAMLSettings`: SAML configuration
- `request_data::Dict`: HTTP request data (POST data from IdP)

# Returns
- SAMLResponse object
"""
function parse_saml_response(settings::SAMLSettings, request_data::Dict)::SAMLResponse
    response = SAMLResponse(
        "",
        "",
        "",
        "",
        "",
        nothing,
        "",
        false,
        String[]
    )
    
    if !haskey(request_data, "SAMLResponse")
        push!(response.errors, "SAML Response not found in request")
        return response
    end
    
    # Decode the SAMLResponse parameter
    saml_response_encoded = request_data["SAMLResponse"]
    
    try
        # The response comes base64-encoded in POST binding
        saml_response_xml = String(base64decode(saml_response_encoded))
        response.xml = saml_response_xml
        
        # Parse XML
        xml_doc = parse_xml(saml_response_xml)
        if xml_doc === nothing
            push!(response.errors, "Invalid SAML Response XML")
            return response
        end
        
        root = root_element(xml_doc)
        
        # Extract basic response attributes
        response.id = get_attribute_value(root, "ID")
        response.in_response_to = get_attribute_value(root, "InResponseTo")
        
        # Extract issuer
        issuer_elem = query_element(root, "Issuer")
        if issuer_elem !== nothing
            response.issuer = get_element_text(issuer_elem)
        end
        
        # Extract status
        status_elem = query_element(root, "Status")
        if status_elem !== nothing
            status_code_elem = query_element(status_elem, "StatusCode")
            if status_code_elem !== nothing
                response.status_code = get_attribute_value(status_code_elem, "Value")
            end
            
            status_msg_elem = query_element(status_elem, "StatusMessage")
            if status_msg_elem !== nothing
                response.status_message = get_element_text(status_msg_elem)
            end
        end
        
        # Extract assertion
        assertion = _parse_assertion(root)
        if assertion !== nothing
            response.assertion = assertion
        end
        
    catch e
        push!(response.errors, "Failed to parse SAML Response: $(e.msg)")
    end
    
    return response
end

"""
    _parse_assertion(response_root::XMLElement)::Union{SAMLAssertion, Nothing}

Parse an assertion from the response XML.

# Arguments
- `response_root::XMLElement`: Root element of SAML Response

# Returns
- SAMLAssertion or nothing if not found
"""
function _parse_assertion(response_root::XMLElement)::Union{SAMLAssertion, Nothing}
    assertion_elem = query_element(response_root, "Assertion")
    
    if assertion_elem === nothing
        return nothing
    end
    
    assertion = SAMLAssertion(
        get_attribute_value(assertion_elem, "ID"),
        "",
        "",
        "",
        "",
        Dict{String, Vector{String}}()
    )
    
    # Extract issuer
    issuer_elem = query_element(assertion_elem, "Issuer")
    if issuer_elem !== nothing
        assertion.issuer = get_element_text(issuer_elem)
    end
    
    # Extract subject name ID
    subject_elem = query_element(assertion_elem, "Subject")
    if subject_elem !== nothing
        name_id_elem = query_element(subject_elem, "NameID")
        if name_id_elem !== nothing
            assertion.subject_name_id = get_element_text(name_id_elem)
        end
        
        # Extract SubjectConfirmationData for time validation
        subj_conf_elem = query_element(subject_elem, "SubjectConfirmation")
        if subj_conf_elem !== nothing
            subj_conf_data_elem = query_element(subj_conf_elem, "SubjectConfirmationData")
            if subj_conf_data_elem !== nothing
                assertion.not_on_or_after = get_attribute_value(subj_conf_data_elem, "NotOnOrAfter")
            end
        end
    end
    
    # Extract conditions for time validation
    conditions_elem = query_element(assertion_elem, "Conditions")
    if conditions_elem !== nothing
        assertion.not_before = get_attribute_value(conditions_elem, "NotBefore")
        assertion.not_on_or_after = get_attribute_value(conditions_elem, "NotOnOrAfter")
    end
    
    # Extract attributes
    attr_stmt_elem = query_element(assertion_elem, "AttributeStatement")
    if attr_stmt_elem !== nothing
        attr_elems = query_elements(attr_stmt_elem, "Attribute")
        for attr_elem in attr_elems
            attr_name = get_attribute_value(attr_elem, "Name")
            if !isempty(attr_name)
                attr_values = String[]
                value_elems = query_elements(attr_elem, "AttributeValue")
                for val_elem in value_elems
                    push!(attr_values, get_element_text(val_elem))
                end
                assertion.attributes[attr_name] = attr_values
            end
        end
    end
    
    return assertion
end

"""
    validate_saml_response(response::SAMLResponse, settings::SAMLSettings, 
                          request_id::String="")::Bool

Validate a SAML Response.

# Arguments
- `response::SAMLResponse`: Response to validate
- `settings::SAMLSettings`: SAML configuration
- `request_id::String`: Expected request ID for InResponseTo matching

# Returns
- true if response is valid, false otherwise
"""
function validate_saml_response(response::SAMLResponse, settings::SAMLSettings, 
                               request_id::String="")::Bool
    
    # Check for parsing errors
    if !isempty(response.errors)
        return false
    end
    
    # Check issuer
    if response.issuer != settings.idp.entity_id
        push!(response.errors, "Invalid issuer: expected $(settings.idp.entity_id), got $(response.issuer)")
        return false
    end
    
    # Check status
    if response.status_code != STATUS_SUCCESS
        push!(response.errors, "SAML Response status is not success: $(response.status_code)")
        return false
    end
    
    # Check InResponseTo if request_id provided
    if !isempty(request_id) && response.in_response_to != request_id
        push!(response.errors, "Invalid InResponseTo: expected $request_id, got $(response.in_response_to)")
        return false
    end
    
    # Validate assertion if present
    if response.assertion !== nothing
        if !_validate_assertion(response.assertion, settings)
            push!(response.errors, "Assertion validation failed")
            return false
        end
    else
        if settings.security.want_assertions_signed
            push!(response.errors, "Assertion expected but not found")
            return false
        end
    end
    
    # Signature validation would go here
    # This requires cryptographic verification with xmlsec1 bindings
    
    response.is_valid = true
    return true
end

"""
    _validate_assertion(assertion::SAMLAssertion, settings::SAMLSettings)::Bool

Validate an assertion's conditions and attributes.

# Arguments
- `assertion::SAMLAssertion`: Assertion to validate
- `settings::SAMLSettings`: SAML configuration

# Returns
- true if assertion is valid
"""
function _validate_assertion(assertion::SAMLAssertion, settings::SAMLSettings)::Bool
    
    # Check issuer
    if assertion.issuer != settings.idp.entity_id
        return false
    end
    
    # Validate time conditions if present
    now_timestamp = now()
    
    if !isempty(assertion.not_before)
        try
            not_before_ts = parse_saml_to_time(assertion.not_before)
            if now_timestamp < not_before_ts
                return false
            end
        catch
            return false
        end
    end
    
    if !isempty(assertion.not_on_or_after)
        try
            not_on_or_after_ts = parse_saml_to_time(assertion.not_on_or_after)
            if now_timestamp >= not_on_or_after_ts
                return false
            end
        catch
            return false
        end
    end
    
    return true
end

"""
    get_assertion_attributes(response::SAMLResponse)::Dict{String, Vector{String}}

Extract attributes from a SAML Response.

# Arguments
- `response::SAMLResponse`: Response to extract attributes from

# Returns
- Dictionary of attribute names to values
"""
function get_assertion_attributes(response::SAMLResponse)::Dict{String, Vector{String}}
    if response.assertion === nothing
        return Dict{String, Vector{String}}()
    end
    
    return response.assertion.attributes
end

"""
    get_nameid(response::SAMLResponse)::String

Get the NameID from the response.

# Arguments
- `response::SAMLResponse`: Response to extract from

# Returns
- NameID string or empty string if not found
"""
function get_nameid(response::SAMLResponse)::String
    if response.assertion === nothing
        return ""
    end
    
    return response.assertion.subject_name_id
end
