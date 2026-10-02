-- Reset only this launcher's disposable scene. Never use in the artist session.
(
    if RIDir==undefined or not matchPattern RIDir pattern:"*retained-integration-2026-10-02/run*/" do throw "Not the private fixture"
    resetMaxFile #noPrompt
    fileIn (RIRoot+"tools/performance/retained_integration/bootstrap.ms")
)
