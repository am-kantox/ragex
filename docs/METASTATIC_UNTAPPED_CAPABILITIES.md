# Metastatic Untapped Capabilities Analysis

**Date**: January 24, 2026  
**Status**: Opportunity Identification  
**Impact**: High - Could significantly enhance Ragex analysis capabilities

## Executive Summary

We've implemented basic function-level enrichment using Metastatic, but we're barely scratching the surface. Metastatic provides **9 comprehensive analysis modules** that we're not leveraging:

1. **Complexity** (✅ Partially used - only basic metrics)
2. **Purity** (✅ Partially used - simple detection)
3. **Cohesion** (❌ Not used)
4. **Coupling** (❌ Not used - we have our own)
5. **Dead Code** (✅ Used via bridge)
6. **Security** (❌ Not used)
7. **Smells** (❌ Not used)
8. **State Management** (❌ Not used)
9. **Taint Analysis** (❌ Not explored)

---

## 1. Complexity Analysis (UNDERUTILIZED)

**Current State**: We calculate basic cyclomatic complexity, but ignore 90% of Metastatic's capabilities.

### What We're Missing

#### A. Cognitive Complexity
```elixir
# Metastatic provides cognitive complexity (better than cyclomatic for readability)
{:ok, result} = Metastatic.Analysis.Complexity.analyze(doc)
result.cognitive  # Structural complexity with nesting penalties
```

**Why It Matters**:
- Better predictor of code comprehension difficulty than cyclomatic
- Accounts for nesting depth (if inside if is more complex than two separate ifs)
- Used by SonarQube and other professional tools

#### B. Comprehensive Halstead Metrics
```elixir
result.halstead
# => %{
#   n1: 10,              # Unique operators
#   n2: 5,               # Unique operands
#   N1: 50,              # Total operators
#   N2: 25,              # Total operands
#   vocabulary: 15,      # n1 + n2
#   length: 75,          # N1 + N2
#   volume: 287.5,       # Length * log2(vocabulary)
#   difficulty: 15.0,    # (n1/2) * (N2/n2)
#   effort: 4312.5,      # Difficulty * Volume
#   time: 239.6,         # Effort / 18 (seconds to implement)
#   bugs: 0.096          # Volume / 3000 (predicted bugs)
# }
```

**Why It Matters**:
- Predicts implementation time
- Estimates bug probability
- Industry-standard metric for code maintainability
- We currently only collect `unique_operators` and `unique_operands`

#### C. Per-Function Metrics
```elixir
result.per_function
# => [
#   %{
#     function_name: "process",
#     cyclomatic: 5,
#     cognitive: 3,
#     nesting: 2,
#     statement_count: 15,
#     return_count: 3,
#     variable_count: 7
#   }
# ]
```

**Why It Matters**:
- We enrich at function level but miss per-function granularity from Metastatic
- Could provide function-specific recommendations
- Enables function-level quality gates

#### D. Lines of Code (Comprehensive)
```elixir
result.loc
# => %{
#   physical: 50,       # Total lines
#   logical: 35,        # Lines with code
#   comments: 10,       # Comment lines
#   blank: 5,           # Blank lines
#   code_ratio: 0.70    # logical / physical
# }
```

**Why It Matters**:
- We estimate LOC from expressions; Metastatic has precise counts
- Distinguishes code vs comments vs blank lines
- Code ratio is a quality indicator

### Implementation Gap

**Current**: Simple recursive AST walking with basic counters  
**Available**: Full Metastatic.Analysis.Complexity module with all metrics

**Recommendation**: Replace our custom metric calculation with direct Metastatic.Analysis.Complexity calls.

---

## 2. Purity Analysis (UNDERUTILIZED)

**Current State**: We check for basic I/O patterns; Metastatic has comprehensive purity tracking.

### What We're Missing

#### A. Comprehensive Side Effect Detection
```elixir
{:ok, result} = Metastatic.Analysis.Purity.analyze(doc)

result.effects
# => [:io, :mutation, :non_deterministic, :exception_handling]

result.locations  # Where each effect occurs
# => [
#   %{effect: :io, function: "print", line: 10},
#   %{effect: :mutation, variable: "counter", line: 15}
# ]
```

**Detected Effects**:
- `:io` - I/O operations (we check this)
- `:mutation` - Variable mutations in loops (we miss this)
- `:non_deterministic` - Random, time/date operations (we miss this)
- `:exception_handling` - Raising/catching exceptions (we miss this)
- `:unknown_calls` - Calls to functions we can't analyze

**Why It Matters**:
- We only detect I/O; miss mutation, randomness, exceptions
- Metastatic tracks confidence levels (:high, :medium, :low)
- Provides exact locations for remediation

#### B. Context-Aware Analysis
```elixir
result.confidence  # :high | :medium | :low
result.unknown     # List of function calls we couldn't classify
```

**Why It Matters**:
- Distinguishes between "definitely impure" and "might be impure"
- Helps prioritize refactoring efforts
- Unknown calls list guides further analysis

### Implementation Gap

**Current**: Simple pattern matching for IO/File/Logger modules  
**Available**: Comprehensive purity walker with loop detection, confidence scoring

**Recommendation**: Use Metastatic.Analysis.Purity.analyze/1 directly instead of custom implementation.

---

## 3. Cohesion Analysis (NOT USED)

**Current State**: We don't analyze cohesion at all.

### What We're Missing

#### A. LCOM (Lack of Cohesion of Methods)
```elixir
{:ok, result} = Metastatic.Analysis.Cohesion.analyze(doc)

result.lcom                # 0 = perfect cohesion, >0 = poor cohesion
result.tcc                 # Tight Class Cohesion (0.0-1.0)
result.lcc                 # Loose Class Cohesion (0.0-1.0)
result.assessment          # :excellent | :good | :fair | :poor | :very_poor
```

**Example Output**:
```elixir
%{
  container_name: "BankAccount",
  lcom: 0,                    # Perfect cohesion
  tcc: 1.0,                   # All methods directly connected
  lcc: 1.0,
  method_count: 3,
  shared_state: ["balance"],  # State variables
  assessment: :excellent,
  warnings: [],
  recommendations: ["Excellent cohesion - all methods work together"]
}
```

**Why It Matters**:
- **Identifies god modules**: High LCOM = module does too many unrelated things
- **Guides refactoring**: Shows which methods should be split into separate modules
- **OOP best practices**: Core metric for object-oriented design quality
- **Cross-language**: Works for Elixir modules, Python classes, etc.

#### B. Connection Graph Analysis
- Identifies which methods share state
- Detects method groups (clusters of related methods)
- Suggests module splitting based on connectivity

**Use Cases**:
1. **Refactoring Suggestions**: "Methods X, Y, Z don't share state with A, B, C - consider splitting"
2. **Quality Gates**: "Module has LCOM > 5, reject PR"
3. **Architecture Insights**: Visualize method connectivity

### Implementation Gap

**Current**: No cohesion analysis  
**Available**: Full Metastatic.Analysis.Cohesion module

**Recommendation**: Add cohesion metrics to module-level analysis in `Ragex.Analysis.Quality`.

---

## 4. Coupling Analysis (PARTIALLY DUPLICATED)

**Current State**: We have our own coupling analysis in `Ragex.Analysis.DependencyGraph`, but it's different from Metastatic's.

### What We're Missing

Metastatic's coupling analysis focuses on **single-file analysis**:
- Efferent coupling (dependencies this module has)
- Instability calculation (Ce / (Ca + Ce))
- Dependency extraction from AST

**Comparison**:

| Feature | Ragex | Metastatic |
|---------|-------|------------|
| Afferent coupling (Ca) | ✅ Graph-based, multi-file | ❌ N/A (single file) |
| Efferent coupling (Ce) | ✅ Graph-based, multi-file | ✅ AST-based, single file |
| Instability (I) | ✅ Full calculation | ⚠️ Approximation (assumes Ca=0) |
| Circular deps | ✅ Detects cycles | ❌ N/A |
| Call graph | ✅ Function-level | ❌ Module-level only |

**Why Both Matter**:
- **Ragex**: Multi-file, project-wide analysis with call graph
- **Metastatic**: Fast single-file analysis without loading full project

**Recommendation**: Keep both, but integrate:
- Use Metastatic for quick single-file checks
- Use Ragex for full project analysis
- Cross-validate results

---

## 5. Security Analysis (NOT USED) 🔥

**Current State**: We have zero security vulnerability detection.

### What We're Missing

#### A. Dangerous Function Detection
```elixir
{:ok, result} = Metastatic.Analysis.Security.analyze(doc)

result.vulnerabilities
# => [
#   %{
#     category: :unsafe_deserialization,
#     severity: :critical,
#     description: "Dangerous function 'eval' detected",
#     recommendation: "Never use eval on untrusted input",
#     cwe: 95,  # CWE identifier
#     context: %{function: "eval"}
#   }
# ]
```

**Detected Patterns**:
- **Injection attacks**: SQL injection, command injection, code injection
- **Unsafe deserialization**: `pickle.loads`, `eval`, `exec`, `Code.eval_string`
- **Hardcoded secrets**: API keys, passwords in literals
- **Weak cryptography**: MD5, SHA1, DES
- **Insecure protocols**: HTTP URLs

**Language-Specific Patterns**:
- **Python**: `eval`, `exec`, `pickle.loads`, `os.system`, `subprocess.call`
- **Elixir**: `Code.eval_string`, `:os.cmd`, `System.cmd`
- **Erlang**: `erl_eval:expr`, `:os.cmd`

#### B. CWE Integration
Each vulnerability maps to a **CWE (Common Weakness Enumeration)** ID:
- CWE-78: OS Command Injection
- CWE-95: Improper Neutralization of Directives (code injection)
- CWE-502: Deserialization of Untrusted Data
- CWE-798: Use of Hard-coded Credentials

**Why It Matters**:
- **Security audits**: Automatic vulnerability detection
- **Compliance**: OWASP Top 10, CWE/SANS Top 25
- **Pre-commit hooks**: Block commits with critical vulnerabilities
- **Zero manual effort**: No need for manual code review for common issues

#### C. Secret Detection
```elixir
# Detects patterns like:
password = "hardcoded123"
api_key = "sk-1234567890abcdef"
secret = "my_secret_token"
```

**Why It Matters**:
- **Prevents credential leaks**: Catches secrets before they hit git
- **Compliance**: GDPR, PCI-DSS requirements
- **Common mistake**: Easy to accidentally commit secrets

### Implementation Gap

**Current**: No security analysis  
**Available**: Full Metastatic.Analysis.Security module with CWE mapping

**Recommendation**: Add security scanning as a new MCP tool and integrate with quality analysis.

**Priority**: 🔥 **HIGH** - Security is a major missing feature

---

## 6. Code Smells Detection (NOT USED)

**Current State**: We detect some complexity issues but not design smells.

### What We're Missing

#### A. Design Smell Detection
```elixir
{:ok, result} = Metastatic.Analysis.Smells.analyze(doc)

result.smells
# => [
#   %{
#     type: :long_function,
#     severity: :high,
#     description: "Function has 75 statements (threshold: 50)",
#     suggestion: "Break this function into smaller, focused functions"
#   },
#   %{
#     type: :magic_number,
#     severity: :low,
#     description: "Magic number 86400 should be a named constant",
#     suggestion: "Extract 86400 to a named constant (e.g., SECONDS_PER_DAY)"
#   }
# ]
```

**Detected Smells**:
- **Long function**: Too many statements (threshold: 50)
- **Deep nesting**: Excessive nesting depth (threshold: 4)
- **Magic numbers**: Unexplained numeric literals
- **Complex conditionals**: Deeply nested boolean operations
- **Long parameter list**: Too many parameters (threshold: 5)

**Why It Matters**:
- **Maintainability**: Smells indicate hard-to-maintain code
- **Refactoring targets**: Prioritizes what to fix first
- **Team standards**: Enforces consistent code quality
- **Educational**: Teaches developers better practices

#### B. Configurable Thresholds
```elixir
Metastatic.Analysis.Smells.analyze(doc,
  thresholds: %{
    max_statements: 30,      # Stricter than default 50
    max_nesting: 3,          # Stricter than default 4
    max_parameters: 4,       # Stricter than default 5
    max_cognitive: 10        # Stricter than default 15
  }
)
```

**Why It Matters**:
- **Team-specific**: Each team can set their own standards
- **Progressive tightening**: Start lenient, gradually increase standards
- **Context-aware**: Different thresholds for different project types

### Implementation Gap

**Current**: Basic complexity warnings only  
**Available**: Full Metastatic.Analysis.Smells module with configurable thresholds

**Recommendation**: Add code smell detection to quality analysis and provide MCP tool.

**Priority**: Medium - Nice-to-have for code quality

---

## 7. State Management Analysis (NOT USED)

**Current State**: We don't analyze state management patterns.

### What We're Missing

#### A. State Pattern Detection
```elixir
{:ok, result} = Metastatic.Analysis.StateManagement.analyze(doc)

result.pattern
# => :stateless | :immutable_state | :controlled_mutation | :uncontrolled_mutation

result
# => %{
#   container_name: "Counter",
#   pattern: :controlled_mutation,
#   state_count: 2,                    # Number of state variables
#   mutation_count: 5,                  # Number of mutations
#   initialized_state: ["count"],       # Initialized in constructor
#   uninitialized_state: ["temp"],      # Never initialized
#   read_only_state: [],                # Never mutated
#   mutable_state: ["count", "temp"],   # Can be mutated
#   assessment: :good,
#   warnings: ["temp is never initialized"],
#   recommendations: ["Initialize temp in constructor"]
# }
```

**Patterns**:
- **Stateless**: No instance state (functional programming, best for immutability)
- **Immutable State**: State set once, never modified (good for concurrency)
- **Controlled Mutation**: State modified through encapsulated methods (OOP best practice)
- **Uncontrolled Mutation**: Direct state modification (anti-pattern)

**Why It Matters**:
- **Functional programming**: Identifies violations of immutability
- **Concurrency safety**: Detects potential race conditions
- **OOP best practices**: Ensures proper encapsulation
- **Refactoring guidance**: Shows how to improve state management

#### B. State Variable Tracking
- Identifies all state variables
- Tracks which are initialized vs uninitialized
- Tracks which are read-only vs mutable
- Maps mutations to specific methods

**Use Cases**:
1. **Functional refactoring**: "Convert this OOP class to stateless functions"
2. **Concurrency safety**: "This module mutates state in 5 places - use locks or actors"
3. **Quality gates**: "Reject modules with uninitialized state"

### Implementation Gap

**Current**: No state management analysis  
**Available**: Full Metastatic.Analysis.StateManagement module

**Recommendation**: Add state management analysis for OOP-style Elixir modules (GenServers, Agents, etc.).

**Priority**: Low-Medium - Useful for specific patterns (GenServers)

---

## 8. Taint Analysis (NOT EXPLORED)

**Current State**: We haven't explored taint analysis at all.

### What It Might Provide

Taint analysis tracks data flow from **untrusted sources** (user input, network) to **sensitive sinks** (database queries, system commands).

**Potential Use Cases**:
- SQL injection detection: User input → database query
- Command injection: User input → `System.cmd`
- XSS detection: User input → rendered HTML

**Status**: Need to explore `Metastatic.Analysis.Taint` module

**Priority**: Medium-High - Important for security

---

## Integration Opportunities

### 1. Enhanced Quality Analysis (HIGH PRIORITY)

**Current**: `Ragex.Analysis.Quality` uses MetastaticBridge with limited metrics

**Enhancement**:
```elixir
# Add to quality analysis result
%{
  # Existing
  complexity: %{cyclomatic: 5, cognitive: 3, ...},
  purity: %{pure?: false, effects: [:io, :mutation]},
  
  # NEW - from Metastatic
  cohesion: %{lcom: 2, tcc: 0.6, assessment: :good},
  coupling: %{efferent: 3, instability: 0.75},
  security: %{vulnerabilities: [], has_vulnerabilities?: false},
  smells: %{smells: [{:magic_number, ...}], has_smells?: true},
  state_management: %{pattern: :controlled_mutation, assessment: :good}
}
```

**Implementation**:
1. Extend `Ragex.Analysis.MetastaticBridge.analyze_file/2` to call all Metastatic analyzers
2. Store results in `QualityStore`
3. Add MCP tools for each analyzer

---

### 2. New MCP Tools (HIGH PRIORITY)

**Security Tools**:
- `scan_security` - Security vulnerability scan
- `check_secrets` - Check for hardcoded secrets
- `verify_crypto` - Check cryptography usage

**Quality Tools**:
- `detect_smells` - Code smell detection
- `analyze_cohesion` - Module cohesion analysis
- `check_state_management` - State management pattern analysis

**Integration Tools**:
- `comprehensive_quality_check` - Run all analyzers
- `security_audit` - Full security scan with report

---

### 3. AI Features Enhancement (MEDIUM PRIORITY)

Integrate Metastatic results with AI features:

**ValidationAI**: Use security and smell detection for better validation messages
```elixir
# When validation fails due to security issue
"This code uses 'eval' which is a security vulnerability (CWE-95).
Consider using a safer alternative like JSON parsing."
```

**AIRefiner**: Use smell detection for false positive reduction
```elixir
# Dead code detector finds "unused" function
# But smell detector shows it has high cyclomatic complexity
# AI: "This looks intentional (complex helper), not dead code"
```

**AIInsights**: Use cohesion/coupling for architectural recommendations
```elixir
"Module X has LCOM=5 and high coupling (Ce=15).
Consider splitting into:
- Module X.Core (methods A,B,C sharing state1)
- Module X.Utils (methods D,E,F sharing state2)"
```

---

### 4. Refactoring Suggestions (HIGH PRIORITY)

**Enhance** `Ragex.Analysis.Suggestions` with Metastatic data:

**Current**: Pattern matching on metrics  
**Enhanced**: Use comprehensive Metastatic analysis

```elixir
# New suggestion patterns based on Metastatic
%{
  pattern: :improve_cohesion,
  trigger: %{lcom: > 3},
  benefit: "Better module organization",
  actions: ["Split module based on method connectivity"]
}

%{
  pattern: :fix_security,
  trigger: %{security_vulnerabilities: > 0, severity: :critical},
  benefit: "Eliminate security risks",
  priority: :critical,
  actions: ["Replace #{vuln.function} with safe alternative"]
}

%{
  pattern: :refactor_smells,
  trigger: %{magic_numbers: > 3},
  benefit: "Better readability",
  actions: ["Extract magic numbers to named constants"]
}
```

---

## Recommended Implementation Priority

### Phase 1: Security (1 week) 🔥 CRITICAL
1. Integrate `Metastatic.Analysis.Security`
2. Add `scan_security` MCP tool
3. Add security metrics to Quality analysis
4. Create security audit report
5. **Impact**: Major security capability addition

### Phase 2: Enhanced Complexity (3 days)
1. Replace custom complexity calculation with full Metastatic.Analysis.Complexity
2. Add cognitive complexity
3. Add comprehensive Halstead metrics
4. Add detailed LOC breakdown
5. **Impact**: More accurate, professional-grade metrics

### Phase 3: Code Smells (3 days)
1. Integrate `Metastatic.Analysis.Smells`
2. Add `detect_smells` MCP tool
3. Add smell detection to suggestions engine
4. **Impact**: Better refactoring guidance

### Phase 4: Cohesion (4 days)
1. Integrate `Metastatic.Analysis.Cohesion`
2. Add module cohesion to Quality analysis
3. Add cohesion-based refactoring suggestions
4. **Impact**: Identifies god modules, guides splitting

### Phase 5: Enhanced Purity (2 days)
1. Replace custom purity analysis with Metastatic.Analysis.Purity
2. Add confidence scores
3. Track all effect types
4. **Impact**: More comprehensive purity tracking

### Phase 6: State Management (3 days)
1. Integrate `Metastatic.Analysis.StateManagement`
2. Add pattern detection to Quality analysis
3. **Impact**: Better OOP/GenServer analysis

---

## Estimated Total Effort

- **Phase 1 (Security)**: 1 week - 🔥 **HIGHEST PRIORITY**
- **Phase 2 (Complexity)**: 3 days
- **Phase 3 (Smells)**: 3 days
- **Phase 4 (Cohesion)**: 4 days
- **Phase 5 (Purity)**: 2 days
- **Phase 6 (State Mgmt)**: 3 days

**Total**: ~3.5 weeks for complete Metastatic integration

---

## Conclusion

We're using **~20%** of Metastatic's capabilities. The biggest gaps are:

1. **Security analysis** (completely missing) - 🔥 **CRITICAL**
2. **Comprehensive complexity metrics** (using simplified versions)
3. **Cohesion analysis** (completely missing)
4. **Code smell detection** (completely missing)
5. **State management analysis** (completely missing)

**ROI**: High - These are production-grade features that professional tools provide. Adding them would make Ragex significantly more capable as a code analysis platform.

**Next Steps**: Start with **Phase 1 (Security)** - it's the most impactful and addresses a critical gap.
