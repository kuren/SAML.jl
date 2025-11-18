"""
    Constants used in SAML protocol.
"""

# HTTP Bindings
const BINDING_HTTP_REDIRECT = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
const BINDING_HTTP_POST = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

# NameID Formats
const NAMEID_FORMAT_UNSPECIFIED = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
const NAMEID_FORMAT_EMAIL_ADDRESS = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
const NAMEID_FORMAT_X509_SUBJECT = "urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName"
const NAMEID_FORMAT_WINDOWS_DOMAIN_QUALIFIED_NAME = "urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName"
const NAMEID_FORMAT_KERBEROS = "urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos"
const NAMEID_FORMAT_ENTITY = "urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
const NAMEID_FORMAT_TRANSIENT = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
const NAMEID_FORMAT_PERSISTENT = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"

# Status Codes
const STATUS_SUCCESS = "urn:oasis:names:tc:SAML:2.0:status:Success"
const STATUS_REQUESTER = "urn:oasis:names:tc:SAML:2.0:status:Requester"
const STATUS_RESPONDER = "urn:oasis:names:tc:SAML:2.0:status:Responder"
const STATUS_VERSION_MISMATCH = "urn:oasis:names:tc:SAML:2.0:status:VersionMismatch"
const STATUS_FAILURE = "urn:oasis:names:tc:SAML:2.0:status:AuthnFailed"

# Signature Algorithms
const RSA_SHA1 = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
const RSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
const RSA_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
const RSA_SHA512 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"

# Digest Algorithms
const SHA1 = "http://www.w3.org/2000/09/xmldsig#sha1"
const SHA256 = "http://www.w3.org/2001/04/xmlenc#sha256"
const SHA384 = "http://www.w3.org/2001/04/xmldsig-more#sha384"
const SHA512 = "http://www.w3.org/2001/04/xmlenc#sha512"

# XML Namespaces
const NS_SAML = "urn:oasis:names:tc:SAML:2.0:assertion"
const NS_SAMLP = "urn:oasis:names:tc:SAML:2.0:protocol"
const NS_XMLDSIG = "http://www.w3.org/2000/09/xmldsig#"
const NS_XMLENC = "http://www.w3.org/2001/04/xmlenc#"

# Default Settings
const DEFAULT_SIGNATURE_ALGORITHM = RSA_SHA256
const DEFAULT_DIGEST_ALGORITHM = SHA256
const DEFAULT_NAME_ID_FORMAT = NAMEID_FORMAT_UNSPECIFIED
