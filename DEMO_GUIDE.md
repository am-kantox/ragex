# Ragex Power Demonstration Guide

A comprehensive walkthrough demonstrating Ragex's capabilities using the `calculator` project as a toy example.

## Overview

This guide showcases Ragex's key features:
1. **Static Code Analysis** - AST parsing and knowledge graph construction
2. **Semantic Search** - ML-powered code understanding
3. **Hybrid Retrieval** - Combining symbolic and semantic search
4. **Graph Algorithms** - Code structure analysis
5. **Safe Code Editing** - Atomic operations with validation
6. **Semantic Refactoring** - AST-aware transformations
7. **Code Quality Analysis** - Duplication, dead code, complexity
8. **Impact Analysis** - Risk assessment and refactoring guidance
9. **Automated Suggestions** - AI-powered refactoring recommendations

## Prerequisites

```bash
# Ensure Ragex is compiled
cd /opt/Proyectos/Oeditus/ragex
mix deps.get
mix compile

# Verify calculator project exists
ls -la /opt/Proyectos/Elixir/calculator
```

## Demo Scenario: Enhancing the Calculator

The calculator project is a simple Elixir module with 4 basic operations. We'll use Ragex to:
- Analyze its structure
- Search for patterns
- Detect potential issues
- Safely add new features
- Refactor code
- Generate insights

---

## Part 1: Initial Analysis & Knowledge Graph

### 1.1 Start Ragex MCP Server

```bash
# Terminal 1: Start Ragex
cd /opt/Proyectos/Oeditus/ragex
mix run --no-halt
```

```bash
# Terminal 2: Send MCP commands (or use your MCP client)
# For manual testing, you can use stdio with JSON-RPC
```

### 1.2 Analyze the Calculator Project

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "analyze_directory",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib",
      "language": "elixir"
    }
  }
}
```

**Expected Output:**
- 1 file analyzed (calculator.ex)
- 5 entities discovered (Calculator module + 4 functions)
- Knowledge graph populated with:
  - 1 `:module` node
  - 4 `:function` nodes
  - Relationship edges

**What This Demonstrates:**
- AST parsing for Elixir
- Knowledge graph construction
- Automatic entity extraction

### 1.3 Inspect Knowledge Graph

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "graph_stats",
    "arguments": {}
  }
}
```

**Expected Output:**
```json
{
  "nodes": 5,
  "edges": 4,
  "node_types": {
    "module": 1,
    "function": 4
  },
  "edge_types": {
    "defines": 4
  }
}
```

**What This Demonstrates:**
- Knowledge graph introspection
- Entity counting and categorization

---

## Part 2: Semantic Search & Embeddings

### 2.1 Generate Embeddings

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "generate_embeddings",
    "arguments": {
      "force": false
    }
  }
}
```

**Expected Output:**
- 5 embeddings generated
- Model: `sentence-transformers/all-MiniLM-L6-v2` (default)
- Cache saved to `~/.ragex/embeddings/<project_hash>/`

**What This Demonstrates:**
- Local ML inference (Bumblebee)
- Automatic caching
- No external API dependencies

### 2.2 Semantic Search: Find Math Operations

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "tools/call",
  "params": {
    "name": "semantic_search",
    "arguments": {
      "query": "mathematical operations with error handling",
      "k": 3
    }
  }
}
```

**Expected Results:**
1. `Calculator.divide/2` (highest similarity - handles errors)
2. `Calculator.multiply/2`
3. `Calculator.subtract/2`

**What This Demonstrates:**
- Semantic understanding (not just keyword matching)
- ML-powered relevance ranking
- Context-aware search (found `divide` first due to error handling mention)

### 2.3 Hybrid Search: Combine Symbolic + Semantic

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "tools/call",
  "params": {
    "name": "hybrid_search",
    "arguments": {
      "query": "safe numeric computation",
      "graph_filters": {
        "type": "function"
      },
      "strategy": "fusion",
      "k": 2
    }
  }
}
```

**Expected Results:**
- Combines graph structure + semantic similarity
- Uses Reciprocal Rank Fusion (RRF)
- Better results than either method alone

**What This Demonstrates:**
- Multi-modal retrieval
- Graph-aware search
- Sophisticated ranking algorithms

---

## Part 3: Graph Algorithms & Code Structure

### 3.1 Find All Functions

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "tools/call",
  "params": {
    "name": "find_nodes",
    "arguments": {
      "filters": {
        "type": "function"
      }
    }
  }
}
```

**Expected Output:**
```json
{
  "nodes": [
    {"name": "add", "arity": 2, "module": "Calculator"},
    {"name": "subtract", "arity": 2, "module": "Calculator"},
    {"name": "multiply", "arity": 2, "module": "Calculator"},
    {"name": "divide", "arity": 2, "module": "Calculator"}
  ]
}
```

### 3.2 PageRank: Find Most Important Functions

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "tools/call",
  "params": {
    "name": "pagerank",
    "arguments": {
      "damping": 0.85,
      "max_iterations": 100,
      "top_n": 5
    }
  }
}
```

**Expected Output:**
- All functions have equal rank (no internal calls in this simple example)
- Calculator module has highest rank (defines all functions)

**What This Demonstrates:**
- Graph algorithm application
- Importance scoring
- Foundation for more complex analysis

### 3.3 Export Graph Visualization

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "tools/call",
  "params": {
    "name": "export_graph",
    "arguments": {
      "format": "graphviz",
      "output_path": "/tmp/calculator_graph.dot"
    }
  }
}
```

**Then visualize:**
```bash
dot -Tpng /tmp/calculator_graph.dot -o /tmp/calculator_graph.png
xdg-open /tmp/calculator_graph.png
```

**What This Demonstrates:**
- Graph visualization
- Multiple export formats
- Integration with external tools

---

## Part 4: Code Quality Analysis

### 4.1 Check for Code Duplication

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "tools/call",
  "params": {
    "name": "find_duplicates",
    "arguments": {
      "min_similarity": 0.6,
      "clone_types": ["type1", "type2", "type3"]
    }
  }
}
```

**Expected Results:**
- All 4 functions have similar structure (guards, single expression)
- Type 2 clones detected (same structure, different identifiers)

**What This Demonstrates:**
- AST-based clone detection (via Metastatic)
- Multiple clone types (Type I-IV)
- Similarity scoring

### 4.2 Detect Dead Code

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tools/call",
  "params": {
    "name": "find_dead_code",
    "arguments": {}
  }
}
```

**Expected Results:**
- No dead code (all functions are public API)
- All functions are entry points

**What This Demonstrates:**
- Intraprocedural analysis
- Graph-based reachability
- Public API detection

### 4.3 Quality Report

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "tools/call",
  "params": {
    "name": "quality_report",
    "arguments": {
      "output_path": "/tmp/calculator_quality.md"
    }
  }
}
```

**Expected Report Sections:**
- Code duplication metrics
- Dead code analysis
- Complexity scores (low - simple functions)
- Recommendations

**What This Demonstrates:**
- Comprehensive quality analysis
- Multiple metrics in one report
- Actionable recommendations

---

## Part 5: Safe Code Editing

Now let's add a new feature: power function (exponentiation).

### 5.1 Preview Edit (Dry Run)

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "tools/call",
  "params": {
    "name": "edit_file",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib/calculator.ex",
      "changes": [
        {
          "type": "insert",
          "line": 75,
          "content": "\n  @doc \"\"\"\n  Raises the first number to the power of the second.\n\n  ## Examples\n\n      iex> Calculator.power(2, 3)\n      8.0\n\n      iex> Calculator.power(5, 0)\n      1.0\n\n  \"\"\"\n  def power(a, b) when is_number(a) and is_number(b) do\n    :math.pow(a, b)\n  end"
        }
      ],
      "validate": true,
      "format": true,
      "backup": true
    }
  }
}
```

**What Happens:**
1. Backup created in `~/.ragex/backups/`
2. Content inserted at line 75
3. Syntax validated (Elixir parser)
4. Code formatted (`mix format`)
5. Atomic write (temp file → rename)

**What This Demonstrates:**
- Safe editing with multiple safety nets
- Validation before applying
- Format integration
- Rollback capability

### 5.2 Verify Edit

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 13,
  "method": "tools/call",
  "params": {
    "name": "validate_edit",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib/calculator.ex"
    }
  }
}
```

**Expected Output:**
```json
{
  "valid": true,
  "language": "elixir"
}
```

### 5.3 View Edit History

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 14,
  "method": "tools/call",
  "params": {
    "name": "edit_history",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib/calculator.ex"
    }
  }
}
```

**Expected Output:**
- List of backups with timestamps
- File sizes
- Ability to rollback to any version

### 5.4 Re-analyze to Update Knowledge Graph

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 15,
  "method": "tools/call",
  "params": {
    "name": "analyze_directory",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib",
      "language": "elixir"
    }
  }
}
```

**Expected Output:**
- 5 entities now (added `power/2`)
- Incremental update (only changed file re-analyzed)

**What This Demonstrates:**
- Knowledge graph stays in sync with code
- Incremental analysis
- File tracking with SHA256 hashing

---

## Part 6: Semantic Refactoring

Let's refactor: rename `add` to `sum` throughout the codebase.

### 6.1 Find All Call Sites (Preparation)

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "method": "tools/call",
  "params": {
    "name": "find_callers",
    "arguments": {
      "module": "Calculator",
      "function": "add",
      "arity": 2
    }
  }
}
```

**Expected Output:**
- Call sites listed (if any exist in tests or other modules)

### 6.2 Rename Function (AST-aware)

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "method": "tools/call",
  "params": {
    "name": "advanced_refactor",
    "arguments": {
      "operation": "rename_function",
      "params": {
        "module": "Calculator",
        "old_name": "add",
        "new_name": "sum",
        "arity": 2,
        "scope": "project"
      },
      "validate": true,
      "format": true
    }
  }
}
```

**What Happens:**
1. AST parsed to find function definition
2. Knowledge graph queried for call sites
3. All references updated (definition + calls)
4. Each file validated
5. Transaction committed atomically

**What This Demonstrates:**
- Semantic refactoring (not regex)
- Cross-file updates
- Arity-aware renaming
- Atomic transactions

### 6.3 Change Function Signature

Let's add an optional `opts` parameter to `divide/2`:

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 18,
  "method": "tools/call",
  "params": {
    "name": "advanced_refactor",
    "arguments": {
      "operation": "change_signature",
      "params": {
        "module": "Calculator",
        "function": "divide",
        "arity": 2,
        "changes": [
          {
            "type": "add",
            "name": "opts",
            "position": 2,
            "default_value": "[]"
          }
        ]
      },
      "validate": true,
      "format": true
    }
  }
}
```

**What Happens:**
1. Function signature updated: `divide(a, b, opts \\ [])`
2. All call sites updated with default argument
3. AST ensures correct syntax
4. Validation prevents breaking changes

**What This Demonstrates:**
- Signature evolution
- Automatic call site updates
- Backward compatibility preservation

---

## Part 7: Impact Analysis & Risk Assessment

Before making larger changes, let's assess risk.

### 7.1 Analyze Impact of Changing `divide/2`

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 19,
  "method": "tools/call",
  "params": {
    "name": "analyze_impact",
    "arguments": {
      "targets": [
        {
          "module": "Calculator",
          "function": "divide",
          "arity": 2
        }
      ],
      "depth": 3
    }
  }
}
```

**Expected Output:**
```json
{
  "impact_analysis": {
    "Calculator.divide/2": {
      "direct_callers": [],
      "transitive_dependencies": [],
      "affected_modules": 1,
      "risk_score": 0.2,
      "reasons": ["Public API", "No internal callers"]
    }
  }
}
```

### 7.2 Estimate Refactoring Effort

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 20,
  "method": "tools/call",
  "params": {
    "name": "estimate_refactoring_effort",
    "arguments": {
      "operations": [
        {
          "type": "rename_function",
          "module": "Calculator",
          "function": "multiply",
          "new_name": "times"
        },
        {
          "type": "extract_function",
          "module": "Calculator",
          "function": "divide",
          "lines": [71, 74]
        }
      ]
    }
  }
}
```

**Expected Output:**
```json
{
  "total_effort_hours": 0.5,
  "breakdown": {
    "rename_function": {
      "effort_hours": 0.25,
      "complexity": "low",
      "files_affected": 1
    },
    "extract_function": {
      "effort_hours": 0.25,
      "complexity": "low",
      "files_affected": 1
    }
  }
}
```

### 7.3 Risk Assessment Report

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "method": "tools/call",
  "params": {
    "name": "risk_assessment",
    "arguments": {
      "operations": [
        {
          "type": "inline_function",
          "module": "Calculator",
          "function": "power"
        }
      ],
      "output_path": "/tmp/calculator_risk.md"
    }
  }
}
```

**Expected Report:**
- Risk level: LOW
- Reasons: Simple function, no dependencies
- Recommendations: Safe to inline
- Suggested precautions: Write tests first

**What This Demonstrates:**
- Proactive risk assessment
- Effort estimation
- Decision support for refactoring
- Multi-factor analysis (complexity, dependencies, impact)

---

## Part 8: Automated Refactoring Suggestions

### 8.1 Get Refactoring Suggestions

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 22,
  "method": "tools/call",
  "params": {
    "name": "suggest_refactorings",
    "arguments": {
      "module": "Calculator",
      "min_priority": 0.5,
      "max_suggestions": 5
    }
  }
}
```

**Expected Suggestions:**
1. **Extract Module** for guard validation logic
   - Priority: 0.7
   - Benefit: Code reuse
   - Effort: Low
   
2. **Add Type Specs** for all functions
   - Priority: 0.65
   - Benefit: Better documentation, Dialyzer support
   - Effort: Low

3. **Extract Error Handling** pattern
   - Priority: 0.6
   - Benefit: Consistency
   - Effort: Medium

**What This Demonstrates:**
- Pattern detection across codebase
- Priority ranking (benefit vs. cost)
- Actionable recommendations

### 8.2 Explain Suggestion

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 23,
  "method": "tools/call",
  "params": {
    "name": "explain_suggestion",
    "arguments": {
      "suggestion_id": "extract_module_001",
      "include_examples": true
    }
  }
}
```

**Expected Output:**
- Detailed explanation of the refactoring
- Code examples (before/after)
- Step-by-step action plan
- RAG-powered context-aware advice
- Related patterns and best practices

**What This Demonstrates:**
- RAG-powered explanations
- Context-aware guidance
- Integration of multiple Ragex capabilities

---

## Part 9: Advanced Scenarios

### 9.1 Multi-File Transaction

Let's split Calculator into two modules: `Calculator` (high-level) and `Calculator.Operations` (low-level).

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 24,
  "method": "tools/call",
  "params": {
    "name": "advanced_refactor",
    "arguments": {
      "operation": "extract_module",
      "params": {
        "source_module": "Calculator",
        "target_module": "Calculator.Operations",
        "functions": [
          {"name": "add", "arity": 2},
          {"name": "subtract", "arity": 2},
          {"name": "multiply", "arity": 2},
          {"name": "divide", "arity": 2},
          {"name": "power", "arity": 2}
        ]
      },
      "validate": true,
      "format": true
    }
  }
}
```

**What Happens:**
1. New file created: `lib/calculator/operations.ex`
2. Functions moved to new module
3. Original module updated with delegates
4. All imports/aliases updated
5. Transaction commits atomically (all or nothing)

**What This Demonstrates:**
- Multi-file refactoring
- Module extraction
- Atomic transactions
- File creation + editing

### 9.2 Rollback Failed Transaction

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 25,
  "method": "tools/call",
  "params": {
    "name": "rollback_edit",
    "arguments": {
      "path": "/opt/Proyectos/Elixir/calculator/lib/calculator.ex",
      "version": 0
    }
  }
}
```

**What This Demonstrates:**
- Rollback capability
- Version history
- Safety net for experimentation

### 9.3 Community Detection (for larger projects)

**Note:** Calculator is too small, but on a larger project:

**MCP Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 26,
  "method": "tools/call",
  "params": {
    "name": "detect_communities",
    "arguments": {
      "algorithm": "louvain",
      "hierarchical": true
    }
  }
}
```

**What It Would Show:**
- Architectural modules/clusters
- Code organization insights
- Coupling analysis

---

## Part 10: Integration Example

### 10.1 Full Workflow: Add Feature → Analyze → Refactor → Verify

**Step 1:** Add `modulo` function (edit)
**Step 2:** Re-analyze codebase (update graph)
**Step 3:** Check for duplication (quality)
**Step 4:** Get suggestions (automated advice)
**Step 5:** Apply refactoring (safe transform)
**Step 6:** Assess impact (risk analysis)
**Step 7:** Generate report (documentation)

**Script:**
```bash
#!/bin/bash
# Full Ragex workflow demonstration

# 1. Add modulo function
echo "Adding modulo function..."
# (MCP call to edit_file)

# 2. Re-analyze
echo "Re-analyzing codebase..."
# (MCP call to analyze_directory)

# 3. Check quality
echo "Running quality analysis..."
# (MCP call to quality_report)

# 4. Get suggestions
echo "Getting refactoring suggestions..."
# (MCP call to suggest_refactorings)

# 5. Apply top suggestion
echo "Applying refactoring..."
# (MCP call to advanced_refactor)

# 6. Assess impact
echo "Assessing impact..."
# (MCP call to analyze_impact)

# 7. Generate final report
echo "Generating report..."
# (MCP call to quality_report with updated code)
```

---

## Key Takeaways

### Ragex's Unique Value Propositions:

1. **Local-First**: No external APIs, runs entirely on your machine
2. **Multi-Modal**: Combines static analysis + ML + graph algorithms
3. **Safe**: Multiple safety nets (backups, validation, rollback, transactions)
4. **Semantic**: AST-aware, not regex-based
5. **Comprehensive**: 15 analysis tools covering quality, risk, suggestions
6. **Fast**: Incremental updates, intelligent caching
7. **Extensible**: Easy to add new languages/algorithms/tools
8. **Production-Ready**: Robust error handling, tested extensively

### Demonstrated Capabilities:

- Static code analysis (AST parsing)
- Knowledge graph construction
- Semantic search (ML embeddings)
- Hybrid retrieval (symbolic + semantic)
- Graph algorithms (PageRank, centrality, communities)
- Safe editing (atomic operations, validation)
- Semantic refactoring (rename, signature changes)
- Code quality (duplication, dead code)
- Impact analysis (risk, effort estimation)
- Automated suggestions (pattern detection, RAG-powered)

### Performance Characteristics:

- **Analysis**: ~10-50ms per file
- **Semantic search**: ~100-200ms (includes embedding generation)
- **Graph queries**: ~1-10ms for typical operations
- **Refactoring**: ~50-100ms per file affected
- **Quality analysis**: ~200-500ms for full report

### Comparison to Existing Tools:

| Feature | Ragex | GitHub Copilot | SonarQube | Sourcegraph |
|---------|-------|----------------|-----------|-------------|
| Local-first | ✅ | ❌ | ✅ | ❌ |
| Semantic search | ✅ | ✅ | ❌ | ✅ |
| Safe refactoring | ✅ | ❌ | ❌ | ❌ |
| Graph algorithms | ✅ | ❌ | ❌ | ✅ |
| Code quality | ✅ | ⚠️ | ✅ | ⚠️ |
| Impact analysis | ✅ | ❌ | ❌ | ⚠️ |
| Multi-language | ✅ | ✅ | ✅ | ✅ |
| Automated suggestions | ✅ | ✅ | ✅ | ❌ |

---

## Next Steps

### For Further Exploration:

1. **Try with real projects**: Analyze your actual codebases
2. **Custom embedding models**: Configure domain-specific models
3. **Multi-language**: Test with Erlang, Python, JavaScript
4. **Large-scale**: Analyze projects with 10,000+ entities
5. **Integration**: Build tools on top of Ragex MCP API
6. **Custom algorithms**: Add project-specific graph algorithms

### Extending the Demo:

- Add more complex functions (recursive, higher-order)
- Create a test suite and analyze test coverage
- Build a CLI wrapper around Calculator
- Add module attributes and analyze them
- Create circular dependencies and detect them
- Introduce technical debt and get suggestions
- Simulate legacy code and refactor it

---

## Resources

- Ragex Documentation: `WARP.md`, `ALGORITHMS.md`, `ANALYSIS.md`
- MCP Specification: https://spec.modelcontextprotocol.io/
- Example Projects: `test/fixtures/` in Ragex repo

## Conclusion

This demo guide shows Ragex operating on a simple project, but its true power emerges with:
- **Larger codebases** (10,000+ entities)
- **Complex architectures** (microservices, distributed systems)
- **Multi-language projects** (Elixir + Erlang + Python + JS)
- **Legacy refactoring** (technical debt, dead code)
- **Team collaboration** (impact analysis, risk assessment)

Ragex bridges the gap between static analysis tools and AI code assistants by providing:
- The precision of static analysis
- The understanding of semantic search
- The safety of validated refactoring
- The intelligence of AI-powered suggestions

All running locally, with no external dependencies, in real-time.
