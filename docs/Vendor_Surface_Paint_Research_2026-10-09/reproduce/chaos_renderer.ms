RSAssert()
(
    RSWrite "stage.txt" "Set disposable scene renderer to installed Corona"
    RSWrite "renderer-before.txt" (classof renderers.current as string)
    renderers.current=CoronaRenderer()
    RSWrite "renderer-after.txt" (classof renderers.current as string)
    RSWrite "stage.txt" "Read natural Chaos enabled state"
    RSWrite "chaos-enabled-after-renderer.txt" (VChaos.enabled as string)
    VCapture "fixed_three_corona"
)
