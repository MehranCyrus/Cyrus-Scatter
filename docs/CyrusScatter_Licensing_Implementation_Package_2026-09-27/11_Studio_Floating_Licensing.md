# 11 — Studio Floating Licensing

## Hosted floating

Best for internet-connected studios:
- seat leased on authoring use/start;
- renewed in background;
- explicitly released on clean exit;
- lease expiry recovers crashed/zombie seats.

Do not lease a seat merely because Max loaded the plugin if the customer is only rendering/opening a scene. Acquire on first authoring capability or on an explicit Studio activation/login policy.

## Lease state

```text
NoLease -> Acquiring -> Leased -> Renewing
                    \-> Denied
Leased -> Grace -> Lost
Leased -> Releasing -> NoLease
```

## UX

Status should show:
- Studio license name;
- seat acquired/not acquired;
- lease/grace state;
- server type;
- last refresh;
- actionable “all seats in use” message.

## Crash behavior

Lease duration balances:
- fast zombie-seat recovery;
- tolerance of brief network outages;
- provider API volume.

Use provider recommendations and measure with real studio sessions.

## On-prem

Treat on-prem floating as a separate deployment/support product. It introduces:
- server installation;
- firewall/port requirements;
- offline server activation;
- version/support responsibilities;
- studio admin documentation.

Do not promise it at launch unless you can support it operationally.
