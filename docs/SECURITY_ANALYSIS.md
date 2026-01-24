# Security Analysis Documentation

## Overview

The Security Analysis module provides automated vulnerability detection for codebases using Metastatic's cross-language AST analysis capabilities. It identifies common security vulnerabilities including injection attacks, unsafe deserialization, hardcoded secrets, weak cryptography, and insecure protocols.

## Features

### Vulnerability Detection

The module detects the following vulnerability categories:

1. **Unsafe Deserialization** (CWE-95, CWE-502)
   - `Code.eval_string` (Elixir)
   - `eval`, `exec` (Python)
   - `pickle.loads` (Python)
   - `erl_eval:expr` (Erlang)
   - Severity: Critical

2. **Injection Attacks** (CWE-78)
   - `System.cmd` (Elixir)
   - `:os.cmd` (Elixir/Erlang)
   - `os.system`, `subprocess.call`, `subprocess.run` (Python)
   - Severity: Critical to High

3. **Hardcoded Secrets** (CWE-798)
   - API keys, passwords, tokens in source code
   - Pattern matching for common secret formats
   - Severity: High

4. **Weak Cryptography** (CWE-327)
   - MD5, SHA1, DES usage
   - Severity: Medium

5. **Insecure Protocols** (CWE-319)
   - HTTP URLs (should use HTTPS)
   - Severity: Medium

### Language Support

Currently supported languages:
- **Elixir**: Full support for module and function analysis
- **Python**: Partial support (parser infrastructure in place)
- **Erlang**: Partial support (pending parser fixes)

## API Reference

### Ragex.Analysis.Security

#### analyze_file/2

Analyzes a single file for security vulnerabilities.

```elixir
alias Ragex.Analysis.Security

{:ok, result} = Security.analyze_file("lib/my_module.ex")

result.has_vulnerabilities?  # => true/false
result.total_vulnerabilities # => integer
result.vulnerabilities       # => list of vulnerability maps
result.critical_count        # => integer
result.high_count           # => integer
result.medium_count         # => integer
result.low_count            # => integer
```

**Options:**
- `:language` - Explicit language (default: auto-detect from extension)
- `:categories` - List of categories to check (default: all)
- `:min_severity` - Minimum severity to report (`:critical`, `:high`, `:medium`, `:low`)

**Returns:**
- `{:ok, analysis_result()}` - Success with results
- `{:error, term()}` - File not found or parsing error

#### analyze_directory/2

Analyzes all source files in a directory.

```elixir
{:ok, results} = Security.analyze_directory("lib/", 
  recursive: true,
  parallel: true,
  max_concurrency: 8
)

# Filter results
files_with_issues = Enum.filter(results, & &1.has_vulnerabilities?)
```

**Options:**
- `:recursive` - Scan subdirectories (default: `true`)
- `:parallel` - Use parallel processing (default: `true`)
- `:max_concurrency` - Max concurrent analyses (default: `System.schedulers_online()`)
- Plus all options from `analyze_file/2`

**Returns:**
- `{:ok, [analysis_result()]}` - List of results for each file
- `{:error, term()}` - Directory access error

#### audit_report/1

Generates a comprehensive security audit report.

```elixir
{:ok, results} = Security.analyze_directory("lib/")
report = Security.audit_report(results)

# Access report sections
report.summary                    # => formatted summary string
report.by_severity                # => vulnerabilities grouped by severity
report.by_category                # => vulnerabilities grouped by category
report.by_file                    # => vulnerabilities grouped by file
report.recommendations            # => list of remediation recommendations
report.total_files                # => total files scanned
report.files_with_vulnerabilities # => count of vulnerable files
report.timestamp                  # => when report was generated
```

### Vulnerability Structure

Each vulnerability in the results contains:

```elixir
%{
  category: :unsafe_deserialization,           # atom
  severity: :critical,                         # :critical | :high | :medium | :low
  description: "Dangerous function...",        # string
  recommendation: "Use safe alternatives...",  # string
  cwe: 95,                                     # CWE ID (integer or nil)
  context: %{function: "Code.eval_string"},   # additional context
  file: "lib/unsafe.ex",                      # file path
  language: :elixir                           # language atom
}
```

## MCP Tools

Three MCP tools are available for integration with AI assistants:

### 1. scan_security

Scans files or directories for security vulnerabilities.

```json
{
  "name": "scan_security",
  "arguments": {
    "path": "lib/",
    "recursive": true,
    "min_severity": "high",
    "categories": ["unsafe_deserialization", "injection"]
  }
}
```

**Parameters:**
- `path` (required): File or directory path
- `recursive`: Scan subdirectories (default: true)
- `min_severity`: Minimum severity filter
- `categories`: List of categories to check

**Returns:** JSON with scan results including vulnerabilities found.

### 2. security_audit

Generates a comprehensive security audit report.

```json
{
  "name": "security_audit",
  "arguments": {
    "path": "lib/",
    "format": "markdown",
    "min_severity": "medium"
  }
}
```

**Parameters:**
- `path` (required): Directory to audit
- `format`: Output format - `"json"`, `"markdown"`, or `"text"` (default: "json")
- `min_severity`: Minimum severity filter

**Returns:** Formatted audit report with summary, grouped vulnerabilities, and recommendations.

### 3. check_secrets

Specialized tool for detecting hardcoded secrets.

```json
{
  "name": "check_secrets",
  "arguments": {
    "path": "lib/"
  }
}
```

**Parameters:**
- `path` (required): File or directory path

**Returns:** List of files with hardcoded secrets detected.

## Usage Examples

### Basic File Analysis

```elixir
alias Ragex.Analysis.Security

# Analyze a single file
case Security.analyze_file("lib/my_module.ex") do
  {:ok, result} when result.has_vulnerabilities? ->
    IO.puts("Found #{result.total_vulnerabilities} vulnerabilities:")
    
    Enum.each(result.vulnerabilities, fn vuln ->
      IO.puts("  [#{vuln.severity}] #{vuln.description}")
      IO.puts("    → #{vuln.recommendation}")
    end)
    
  {:ok, _result} ->
    IO.puts("No vulnerabilities found!")
    
  {:error, reason} ->
    IO.puts("Analysis failed: #{inspect(reason)}")
end
```

### Directory Scanning with Filtering

```elixir
# Scan only for critical and high severity issues
{:ok, results} = Security.analyze_directory("lib/", 
  min_severity: :high,
  parallel: true
)

# Find files with critical vulnerabilities
critical_files = 
  results
  |> Enum.filter(&(&1.critical_count > 0))
  |> Enum.map(& &1.file)

IO.puts("Files with critical vulnerabilities:")
Enum.each(critical_files, &IO.puts("  - #{&1}"))
```

### Generating Reports

```elixir
# Full audit
{:ok, results} = Security.analyze_directory("lib/")
report = Security.audit_report(results)

# Summary
IO.puts(report.summary)

# Critical issues by file
report.by_file
|> Enum.filter(fn {_file, vulns} ->
  Enum.any?(vulns, &(&1.severity == :critical))
end)
|> Enum.each(fn {file, vulns} ->
  IO.puts("\n#{file}:")
  Enum.each(vulns, &IO.puts("  - #{&1.description}"))
end)

# Remediation recommendations
IO.puts("\nRecommendations:")
Enum.each(report.recommendations, fn rec ->
  IO.puts("  [#{rec.severity}] #{rec.category}: #{rec.count} occurrences")
  IO.puts("    → #{rec.recommendation}")
end)
```

### Category-Specific Analysis

```elixir
# Check only for injection vulnerabilities
{:ok, results} = Security.analyze_directory("lib/",
  categories: [:injection, :unsafe_deserialization]
)

injection_count = 
  results
  |> Enum.flat_map(& &1.vulnerabilities)
  |> Enum.count(&(&1.category == :injection))

IO.puts("Found #{injection_count} injection vulnerabilities")
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19'
          otp-version: '27'
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Run security scan
        run: |
          mix run -e '
            alias Ragex.Analysis.Security
            {:ok, results} = Security.analyze_directory("lib/", min_severity: :high)
            report = Security.audit_report(results)
            
            if report.files_with_vulnerabilities > 0 do
              IO.puts(report.summary)
              System.halt(1)
            end
          '
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running security scan..."

mix run -e '
  alias Ragex.Analysis.Security
  
  # Get staged files
  staged_files = System.cmd("git", ["diff", "--cached", "--name-only", "--diff-filter=ACM"])
    |> elem(0)
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.ends_with?(&1, ".ex"))
  
  results = Enum.map(staged_files, fn file ->
    case Security.analyze_file(file, min_severity: :high) do
      {:ok, result} -> result
      _ -> nil
    end
  end)
  |> Enum.reject(&is_nil/1)
  
  critical_count = Enum.sum(Enum.map(results, & &1.critical_count))
  
  if critical_count > 0 do
    IO.puts("❌ Found #{critical_count} critical vulnerabilities. Commit blocked.")
    System.halt(1)
  else
    IO.puts("✅ Security scan passed")
  end
'
```

## Configuration

### Custom Severity Thresholds

You can configure different severity thresholds for different environments:

```elixir
# config/config.exs
config :ragex, :security,
  min_severity: :medium,
  parallel: true,
  max_concurrency: 8

# config/prod.exs
config :ragex, :security,
  min_severity: :high  # Stricter in production
```

### Custom Patterns

While the default patterns cover common vulnerabilities, you can extend detection by working directly with Metastatic:

```elixir
# Custom analysis combining security with other metrics
defmodule MyApp.SecurityAnalysis do
  alias Ragex.Analysis.Security
  alias Ragex.Graph.Store
  
  def analyze_with_context(path) do
    # Get security issues
    {:ok, sec_result} = Security.analyze_file(path)
    
    # Get call graph context
    callers = Store.get_callers(:MyModule, :dangerous_function, 1)
    
    # Combine information
    %{
      vulnerabilities: sec_result.vulnerabilities,
      call_graph: callers,
      risk_score: calculate_risk(sec_result, callers)
    }
  end
  
  defp calculate_risk(sec_result, callers) do
    # Custom risk calculation
    vulnerability_score = sec_result.critical_count * 10 + 
                         sec_result.high_count * 5
    exposure_score = length(callers)
    
    vulnerability_score * exposure_score
  end
end
```

## Known Limitations

### 1. Module Attributes

Elixir module attributes (`@api_key "secret"`) are not detected by the hardcoded secrets scanner because they don't produce `:literal` nodes in the MetaAST. This is a limitation of the current AST walking implementation.

**Workaround:** Use variable assignments instead:
```elixir
# Not detected
@api_key "sk-1234..."

# Would be detected (if :inline_match support were added)
api_key = "sk-1234..."
```

### 2. Multi-Language Support

Currently, only Elixir has full support. Python and Erlang analysis have parser limitations:
- **Python**: Parser infrastructure exists but requires setup
- **Erlang**: Parser errors with certain syntax patterns

### 3. False Positives

Some legitimate uses of "dangerous" functions may be flagged:

```elixir
# Flagged as dangerous, but may be safe in context
defmodule SafeEval do
  # Controlled evaluation with validated input
  def eval_math_only(expr) do
    if safe_math_expression?(expr) do
      Code.eval_string(expr)
    end
  end
end
```

**Mitigation:** Use filtering and manual review of results.

### 4. Dynamic Analysis

This is a static analysis tool and cannot detect:
- Runtime-constructed dangerous calls
- Vulnerabilities in dependencies
- Logic flaws requiring dynamic execution

## Performance

### Benchmarks

On a typical Elixir project:
- **Single file**: ~10-50ms
- **Medium project** (100 files): ~1-2 seconds (parallel)
- **Large project** (1000 files): ~10-15 seconds (parallel)

### Optimization Tips

1. **Use parallel processing** for directory scans (enabled by default)
2. **Filter by severity** to reduce processing for non-critical reports
3. **Use category filtering** when looking for specific vulnerability types
4. **Cache results** for unchanged files in CI/CD pipelines

```elixir
# Efficient large project scanning
{:ok, results} = Security.analyze_directory(
  "lib/",
  min_severity: :high,          # Skip low/medium
  categories: [:injection],      # Focus on specific type
  max_concurrency: 16           # Use more cores
)
```

## Troubleshooting

### "No vulnerabilities detected" for known issues

1. Check that the file is being parsed correctly:
   ```elixir
   {:ok, doc} = Metastatic.Builder.from_source(code, :elixir)
   IO.inspect(doc.ast, limit: :infinity)
   ```

2. Verify the function name matches patterns exactly (case-sensitive)

3. Ensure the code isn't in a skipped language-specific structure

### Parser errors

For Erlang parser errors:
```
{:parsing_source_failed, "Parse error: ..."}
```

This indicates the Erlang adapter needs fixes. File an issue with the specific code pattern.

### Performance issues

If scanning is slow:
1. Enable parallel processing (default)
2. Increase `max_concurrency`
3. Use severity/category filtering
4. Check for very large files that may timeout

## Future Enhancements

Planned improvements:
1. Full Python and Erlang support (Phase 2)
2. Additional vulnerability patterns
3. Custom pattern configuration
4. Incremental analysis with caching
5. Integration with Quality analysis module
6. Dataflow analysis for tracking tainted input
7. Configuration file support for project-specific rules

## See Also

- [METASTATIC_INTEGRATION_ROADMAP.md](./METASTATIC_INTEGRATION_ROADMAP.md) - Full integration plan
- [METASTATIC_UNTAPPED_CAPABILITIES.md](./METASTATIC_UNTAPPED_CAPABILITIES.md) - Available Metastatic features
- [Metastatic Documentation](https://hexdocs.pm/metastatic/) - Metastatic library docs
- [CWE Database](https://cwe.mitre.org/) - Common Weakness Enumeration reference

## Contributing

To add new vulnerability patterns:

1. Add the pattern to `@dangerous_functions` in `lib/ragex/analysis/security.ex`
2. Add test cases in `test/analysis/security_test.exs`
3. Document the new pattern in this file
4. Submit a pull request

Example:
```elixir
# In lib/ragex/analysis/security.ex
@dangerous_functions %{
  elixir: %{
    # Add new pattern
    "File.write!" => {:path_traversal, :high, 22}
  }
}
```
