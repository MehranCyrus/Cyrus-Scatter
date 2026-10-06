"""Agent workflows describe existing boundaries; they do not expand dispatch."""

WORKFLOWS = {
    "schema": "cyrus.agent-workflows/1.0",
    "inspect_existing": [
        "The artist selects a controller and connects read-only inspection locally.",
        "Read connection_get_status, scene_get_context, cyrus://feature-catalog and scatter_get_configuration.",
        "For policy 3, get_publication then read_publication_page for its exact ID. These are cached reads; pending inputs may differ. Respect expiry, page and byte budgets.",
        "Use each page's offset/count/digest and stable (set_id, instance_id), not array position, for analysis. A new publication requires a new manifest; never merge epochs.",
        "Read cached diagnostics. Request viewport capture only if explicitly shared; it performs a deliberate redraw and can expose a pending Live result.",
    ],
    "design_supported_scope": [
        "The artist enrolls a bounded horizontal static site, sources and convex regions.",
        "Use closed schema 1.0 or 2.0 only. Normalize and validate the full proposal, then wait for its local approval.",
        "Apply with the returned digest, scene epoch/revision and one stable idempotency key. Poll the operation with backoff; timeout does not mean failure or permission to replay.",
        "Inspect actual publication/counts and export the matching owned execution record. Preserve underfill and failure outcomes.",
        "Changing an existing policy-3 controller, Brush history, model containers, Edit or renderer is outside these apply schemas.",
    ],
    "investigate_ir_refresh": [
        "The artist starts a bounded engineering recording locally, reproduces idle and one real edit, then stops recording.",
        "Only read trace pages if that exact process-wide session was explicitly shared. Otherwise use a report exported locally by the artist.",
        "Compare input.received, input.classified, container.notification, prepare/solve/publication and bridge/IR request events in order.",
        "Distinguish explicit bridge stop/start requests from renderer reactions; a correlation alone does not prove the initiating cause.",
        "Inspect eviction/lock-drop/truncation/failure counters. Receipt times are not action latency or presented FPS. Record build identities and unresolved host qualification.",
    ],
    "learning": [
        "Operational exports and relative preference wins never grant dataset consent or final artistic approval.",
        "Rendering and batch scene mutation are not exposed through MCP. Future renderer jobs require separate local enrollment and qualification.",
        "Retain failed technical attempts separately from artist rejection, ties, neither, skip and approval. Do not label a failed render as poor composition.",
    ],
}

ERROR_GUIDE = {
    "schema": "cyrus.error-guide/1.0",
    "APPROVAL_REQUIRED": "Use the specified local enrollment/approval/sharing action. A tool cannot grant itself authority.",
    "STALE_CONTEXT": "Read the relevant current manifest/context. Re-enroll locally if scene inputs changed; do not transplant an old approval.",
    "PUBLICATION_UNAVAILABLE": "Ask for a local Update when appropriate. A read tool will not solve or fabricate results.",
    "BUDGET_EXCEEDED": "Reduce the requested work or page size. Do not repeatedly reconnect to turn the design scope into a batch authorization.",
    "OUTCOME_UNKNOWN": "Inspect the original operation and scene locally. Preserve the idempotency key; do not assume rollback or retry a new mutation.",
    "UNSUPPORTED_CAPABILITY": "Explain the documented boundary and use native artist workflow. Do not substitute arbitrary scripts or reinterpret a policy-3 recipe as plan 2.0.",
    "HOST_BUSY": "Wait with backoff or follow the explicit local action. Do not force a render/Undo transaction to end.",
}
