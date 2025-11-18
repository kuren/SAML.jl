# Contributing to SAML Julia Package

Thank you for considering contributing to the SAML Julia package! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and inclusive in all interactions.

## How to Contribute

### Reporting Bugs

Before creating bug reports, check the issue list. When creating a bug report, include:

- **Clear description**: What the bug is
- **Reproduction steps**: How to reproduce the issue
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: Julia version, OS, relevant package versions
- **Screenshots**: If applicable
- **Code examples**: Minimal code that reproduces the issue

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear description**: What the enhancement is
- **Use case**: Why you need this feature
- **Current behavior**: How things work now
- **Proposed behavior**: How you'd like it to work
- **Examples**: Other packages/projects with similar features

### Pull Requests

1. **Fork the repository** and create a branch from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Set up development environment**:
   ```bash
   cd SAMLClient
   julia --project -e "using Pkg; Pkg.instantiate()"
   ```

3. **Make your changes**:
   - Follow Julia style guidelines
   - Write clear commit messages
   - Add tests for new functionality
   - Update documentation as needed

4. **Run tests**:
   ```bash
   julia --project -e "using Pkg; Pkg.test()"
   ```

5. **Commit and push**:
   ```bash
   git commit -am "Add feature: description"
   git push origin feature/my-feature
   ```

6. **Create Pull Request**:
   - Link to related issues
   - Describe changes clearly
   - Explain why changes are needed
   - Reference any documentation updates

## Development Setup

### Prerequisites

- Julia 1.6 or later
- Git
- Basic knowledge of SAML and Julia

### Project Structure

```
src/           # Source code
test/          # Unit tests
docs/          # Documentation
Project.toml   # Package manifest
```

### Running Tests

```julia
julia> using Pkg
julia> Pkg.test()
```

### Building Documentation

Documentation is generated from markdown files in the `docs/` directory.

## Coding Standards

### Julia Style Guidelines

- Use 4-space indentation
- Use meaningful variable names
- Write docstrings for all public functions
- Use type annotations for clarity
- Keep functions focused and modular

### Example Function Documentation

```julia
"""
    my_function(arg1::String, arg2::Int)::String

Brief description of what the function does.

# Arguments
- `arg1::String`: Description of arg1
- `arg2::Int`: Description of arg2

# Returns
- Description of return value

# Example
```julia
result = my_function("hello", 42)
```
"""
function my_function(arg1::String, arg2::Int)::String
    # Implementation
end
```

### Error Handling

- Use meaningful error messages
- Avoid throwing exceptions for normal control flow
- Use `@assert` for development checks
- Document error conditions

## Testing Guidelines

### Test Structure

- One test file per module
- Clear test names describing what's being tested
- Setup and teardown where needed
- Both positive and negative test cases

### Test Example

```julia
@testset "Function behavior" begin
    @testset "Normal operation" begin
        result = my_function("input")
        @test result == "expected"
    end
    
    @testset "Edge cases" begin
        @test_throws ErrorType my_function("")
    end
end
```

## Documentation Standards

### Docstring Format

Use Julia's markdown-based docstring format:

```julia
"""
    function_name(args)

Description here.

# Arguments
- `arg::Type`: Description

# Returns
- Return type and description

# See Also
- [`related_function`](@ref)

# Example
```julia
example_code()
```
"""
```

### Documentation Files

- **README.md**: User overview and quick start
- **docs/IMPLEMENTATION.md**: Architecture and design
- **docs/DEPLOYMENT.md**: Production deployment
- **CHANGELOG.md**: Version history

## Commit Messages

Write clear, concise commit messages:

```
Add feature: brief description

More detailed explanation if needed. Reference issues with #123.
```

## Branching Strategy

- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches
- `fix/*`: Bug fix branches
- `docs/*`: Documentation branches

## Release Process

1. Update version in `Project.toml`
2. Update `CHANGELOG.md` with changes
3. Create release commit
4. Tag release: `git tag v0.x.y`
5. Push to GitHub
6. Create release notes on GitHub

## Areas for Contribution

### High Priority

- [ ] OpenSSL binding for signature validation
- [ ] Assertion encryption/decryption
- [ ] Complete Single Logout implementation
- [ ] IdP metadata discovery

### Medium Priority

- [ ] Performance optimizations
- [ ] Additional authentication profiles
- [ ] Session management helpers
- [ ] Logging framework integration

### Low Priority

- [ ] Additional documentation examples
- [ ] Educational resources
- [ ] Performance benchmarking
- [ ] Integration examples

## Questions?

- Create an issue with the `question` label
- Check existing documentation
- Review the source code comments

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Acknowledgments

Thank you for contributing to make SAML support better for the Julia community!
