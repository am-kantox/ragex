# Fish completion for Ragex Mix tasks
# Install: copy to ~/.config/fish/completions/ragex.fish

# Cache tasks
complete -c mix -n "__fish_seen_subcommand_from ragex.cache.clear" -l help -s h -d "Show help"
complete -c mix -n "__fish_seen_subcommand_from ragex.cache.stats" -l help -s h -d "Show help"
complete -c mix -n "__fish_seen_subcommand_from ragex.cache.refresh" -l path -s p -d "Path to analyze" -r -F
complete -c mix -n "__fish_seen_subcommand_from ragex.cache.refresh" -l force -s f -d "Force refresh"
complete -c mix -n "__fish_seen_subcommand_from ragex.cache.refresh" -l help -s h -d "Show help"

# Embeddings tasks
complete -c mix -n "__fish_seen_subcommand_from ragex.embeddings.migrate" -l check -s c -d "Check status"
complete -c mix -n "__fish_seen_subcommand_from ragex.embeddings.migrate" -l model -s m -d "Model to migrate to" -r -a "all_minilm_l6_v2 all_mpnet_base_v2 codebert_base paraphrase_multilingual"
complete -c mix -n "__fish_seen_subcommand_from ragex.embeddings.migrate" -l force -s f -d "Force migration"
complete -c mix -n "__fish_seen_subcommand_from ragex.embeddings.migrate" -l clear -d "Clear embeddings"
complete -c mix -n "__fish_seen_subcommand_from ragex.embeddings.migrate" -l help -s h -d "Show help"

# AI tasks
complete -c mix -n "__fish_seen_subcommand_from ragex.ai.usage.stats" -l provider -d "Filter by provider" -r -a "openai anthropic deepseek deepseek_r1 ollama"
complete -c mix -n "__fish_seen_subcommand_from ragex.ai.usage.stats" -l help -s h -d "Show help"
complete -c mix -n "__fish_seen_subcommand_from ragex.ai.cache.stats" -l help -s h -d "Show help"
complete -c mix -n "__fish_seen_subcommand_from ragex.ai.cache.clear" -l operation -d "Clear specific operation" -r -a "query explain analyze summarize"
complete -c mix -n "__fish_seen_subcommand_from ragex.ai.cache.clear" -l help -s h -d "Show help"

# Refactor task
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l operation -s o -d "Refactoring operation" -r -a "rename_function rename_module change_signature extract_function inline_function"
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l module -s m -d "Module name" -r
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l function -s f -d "Function name" -r
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l arity -s a -d "Function arity" -r -a "0 1 2 3 4 5"
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l new-name -s n -d "New name" -r
complete -c mix -n "__fish_seen_subcommand_from ragex.refactor" -l help -s h -d "Show help"

# Configure task
complete -c mix -n "__fish_seen_subcommand_from ragex.configure" -l show -s s -d "Show current configuration"
complete -c mix -n "__fish_seen_subcommand_from ragex.configure" -l help -s h -d "Show help"

# Dashboard task
complete -c mix -n "__fish_seen_subcommand_from ragex.dashboard" -l interval -s i -d "Refresh interval (ms)" -r -a "500 1000 2000 5000"
complete -c mix -n "__fish_seen_subcommand_from ragex.dashboard" -l help -s h -d "Show help"

# Task names - only complete if typing "ragex."
complete -c mix -n "__fish_use_subcommand" -a "ragex.cache.clear" -d "Clear all caches"
complete -c mix -n "__fish_use_subcommand" -a "ragex.cache.refresh" -d "Refresh embeddings cache"
complete -c mix -n "__fish_use_subcommand" -a "ragex.cache.stats" -d "Display cache statistics"
complete -c mix -n "__fish_use_subcommand" -a "ragex.embeddings.migrate" -d "Migrate embedding models"
complete -c mix -n "__fish_use_subcommand" -a "ragex.ai.usage.stats" -d "Display AI usage statistics"
complete -c mix -n "__fish_use_subcommand" -a "ragex.ai.cache.stats" -d "Display AI cache statistics"
complete -c mix -n "__fish_use_subcommand" -a "ragex.ai.cache.clear" -d "Clear AI response cache"
complete -c mix -n "__fish_use_subcommand" -a "ragex.refactor" -d "Interactive refactoring wizard"
complete -c mix -n "__fish_use_subcommand" -a "ragex.configure" -d "Interactive configuration wizard"
complete -c mix -n "__fish_use_subcommand" -a "ragex.dashboard" -d "Live monitoring dashboard"
