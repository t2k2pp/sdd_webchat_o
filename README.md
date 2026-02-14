# sdd_webchat_o

A sophisticated Flutter-based chat application with Agentic Search capabilities, Multi-LLM support, and advanced context management.

## Key Features

### 🧠 Advanced AI & Search
- **Multi-LLM Support**: Switch between Gemini, Azure OpenAI, OpenAI-compatible endpoints, and local models.
- **Agentic Search**: 
  - Integrates with SearXNG for privacy-respecting web searches.
  - **Context-Aware Queries**: Automatically generates search queries based on conversation history.
  - **Conditional Execution**: Intelligently decides when to search vs. when to answer directly (e.g., skips search for greetings).
  - **Freshness Guard**: Prevents hallucination on time-sensitive topics by enforcing search verification.

### 📚 Knowledge Management
- **Project-based Context**: Manage separate workspaces with specific prompts and attached files.
- **RAG (Retrieval-Augmented Generation)**: 
  - Hybrid search (Keyword + Vector) for attached documents.
  - Local embedding caching for performance.

### 🛠️ Developer & Power User Tools
- **Traceability**: View detailed "Search Traces" to see exactly what queries were run and what results were found.
- **Cost Tracking**: Monitor token usage and estimated costs per model.
- **Privacy Focused**: API keys stored in Secure Storage; history stored locally in SQLite.
- **Markdown Support**: Full Markdown rendering including code blocks and tables.
- **Text-to-Speech**: Built-in TTS with configurable speed, pitch, and language.

## Getting Started

1.  **Configure Settings**: 
    - Set up your LLM API keys in the Settings menu.
    - Configure your SearXNG instance URL if using web search features.
2.  **Create a Project**: 
    - Define a system prompt and attach relevant documents.
3.  **Start Chatting**: 
    - Toggle "Web Search" to enable agentic capabilities.

## Documentation

- [Implementation Status](docs/IMPLEMENTATION_STATUS.md): Detailed feature tracking.
- [Plan and Design](docs/PLAN_AND_DESIGN.md): Architecture and design decisions.
