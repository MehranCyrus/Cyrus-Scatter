# 30 — Pre-Release Go/No-Go Checklist

## Go only if all critical items pass

### Product
- [ ] all existing CTests pass Release;
- [ ] representative old scenes match baseline;
- [ ] CS Edit old/current persistence works;
- [ ] Analyzer integration works;
- [ ] generated script reproducible.

### Licensing
- [ ] online activate/deactivate;
- [ ] trial;
- [ ] perpetual maintenance eligibility;
- [ ] offline request/response;
- [ ] floating if sold;
- [ ] provider outage grace;
- [ ] clock/device recovery;
- [ ] direct native primitive calls are gated.

### Render
- [ ] local production render;
- [ ] Corona IR if advertised;
- [ ] clean render worker;
- [ ] target farm workflow;
- [ ] render worker does not consume authoring seat;
- [ ] unlicensed interactive authoring remains denied.

### Packaging
- [ ] Max 2026 clean install;
- [ ] Max 2027 clean install if advertised;
- [ ] old installer migration;
- [ ] uninstall;
- [ ] all production binaries signed;
- [ ] signatures verified after packaging.

### Operations
- [ ] checkout/provisioning;
- [ ] refund;
- [ ] maintenance renewal;
- [ ] dead-machine reset;
- [ ] trial extension;
- [ ] offline support guide;
- [ ] status page/outage procedure;
- [ ] privacy/EULA reviewed.

Any critical failure is a no-go for public paid release.
