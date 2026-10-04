# Licensing source register

**Reviewed:** initial consolidation 2026-10-02; offline timing and device follow-up 2026-10-04. RFC 8725, RFC 9700 and PostgreSQL locking were reopened during consolidation; vendor sources were read in the preceding same-day validation. Microsoft DLL guidance was opened for the codebase audit. The October 4 review opened the Windows/network references below and reread Keygen's clock-tampering section. Companion to the [architecture](ARCHITECTURE.md) and [implementation roadmap](ROADMAP.md).

Sources are official vendor documentation or primary standards. Access date is not publication date. Claims describe the documented model only; they do not establish Cyrus implementation quality or disclose proprietary security internals. No vendor pricing or commercial contract was selected.

## Vendor behavior

| Source | Supported claim | Limit and use |
| --- | --- | --- |
| [Autodesk user authentication](https://www.autodesk.com/support/account/admin/licensing-faq/authorization) | Named-user sign-in, refresh and offline allowance for the described subscription | Full page opened. Do not generalize its 30-day rule to every Autodesk product or infer cryptography. |
| [Autodesk assign product access](https://www.autodesk.com/support/account/admin/users/assign-access) | Administrators manage user/group assignments and team seat availability | Full page opened. Assignment pools do not establish concurrent floating licensing. |
| [SideFX license management FAQ](https://www.sidefx.com/faq/license-management/) | Client helper and license server roles | Relevant system sections read. Product-specific rules elsewhere in the FAQ are not adopted. |
| [SideFX login licensing](https://www.sidefx.com/docs/houdini/licensing/login_licensing.html) | Hosted licensing requires an active connection and has documented audience distinctions | Full page opened. Does not establish offline login leases or blanket commercial availability. |
| [SideFX studio licensing](https://www.sidefx.com/docs/houdini/licensing/studio_licensing.html) | Studio manages the server and configures clients | Full page opened. No inference about unpublished enforcement code. |
| [Chaos named and floating comparison](https://support.chaos.com/hc/en-us/articles/35342660398225-What-is-the-difference-between-named-and-floating-licenses) | Dedicated named users versus a concurrent shared pool | Full page opened; says updated 2025-05-20. Limited to documented offers. |
| [Chaos combined setup](https://support.chaos.com/hc/en-us/articles/35342476069905-I-have-both-named-and-floating-licenses-What-is-the-recommended-setup) | Organizations and common sign-in support named/floating access | Full page opened; says updated 2025-11-14. No claim about internal architecture. |
| [ITOOSOFT network licensing](https://docs.itoosoft.com/installation/installing-a-network-license) | Server-managed concurrency, increased purchased quantities and network dependency | Full page opened. Its unlicensed object behavior differs from proposed Cyrus continuity. |

## Security and implementation standards

| Source | Supported claim | Application and limit |
| --- | --- | --- |
| [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252) | External-browser native authorization and PKCE for public clients | Use maintained authentication components; not a complete licensing protocol. |
| [RFC 9700](https://www.rfc-editor.org/rfc/rfc9700) | OAuth security practice including refresh-token replay protection | Relevant sections read; test rotation or supported sender constraints across processes. |
| [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation) | Identity-token validation, including issuer/audience and nonce rules | Validation sections read during the cleanup. Identity proof remains separate from product entitlement. |
| [RFC 8725](https://www.rfc-editor.org/rfc/rfc8725) | Algorithm restrictions, claim validation and separation of token kinds | Strict profile if JWS/JWT is chosen; does not supply our seat policy or implementation. |
| [OWASP authorization](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) | Explicit permissions, default denial, server enforcement and tests | Tenant isolation and operation coverage; local checks do not secure server records. |
| [PostgreSQL locking](https://www.postgresql.org/docs/current/explicit-locking.html) | Conflicting row locks serialize transactions until release | Candidate allocation primitive; our full design still requires race/retry/restore tests. |
| [Stripe webhooks](https://docs.stripe.com/webhooks) | Raw-body signatures, duplicate delivery and unordered events | Evidence for idempotent provisioning; Stripe is not selected. |
| [Microsoft cryptography tools](https://learn.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools) | Signing and verification establish publisher/integrity information | Separate release authenticity from licensing; final Max packages need actual qualification. |
| [Microsoft DLL best practices](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices) | Minimal `DllMain` work and loader-lock constraints | Full page opened for C09. Keep networking/complex initialization and worker joins outside loader callbacks; the correct Max lifecycle still needs qualification. |
| [Microsoft DLL security](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security) | Uncontrolled dynamic-library search can load an unintended library | Full page opened for C09. Qualify deliberate runtime/dependency paths without changing host-global search policy; no exploited defect is claimed. |
| [Keygen security](https://keygen.sh/docs/api/security/) | Desktop cracking and offline clock-tampering limitations | Clock section reread 2026-10-04. Supports the limitation of offline local time, not a guaranteed countermeasure. No Keygen service or SDK is being adopted. |

## Offline timing and device evidence

These references were opened on 2026-10-04. The Cyrus design is an engineering proposal using the documented platform properties; it has not been implemented or security-tested.

| Source | Supported fact | Design consequence and limit |
| --- | --- | --- |
| [Microsoft CryptProtectData](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata) | DPAPI ordinarily ties decryption to user/computer context; roaming and machine-scope exceptions are documented | Candidate secret storage with explicit scope. No entitlement authenticity, trusted time or rollback-proof storage follows from encryption. |
| [Microsoft GetTickCount64](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount64) | Reports elapsed milliseconds since system start | Useful timing evidence within its scope; not a trusted calendar across boots or powered-off periods. Clock API and sleep behavior still need qualification. |
| [Microsoft computer product UUID](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystemproduct) | WMI exposes the SMBIOS system UUID; unavailable UUID may be all zeros | Possible matching signal, not a secret, entitlement or universal device proof. Handle unavailable identity and recovery. |
| [Microsoft DHCP overview](https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/dhcp-top) | IP addresses can be leased and reassigned | An IP-based device lock would reject legitimate network changes; do not use IP as activation identity. |
| [RFC 3022](https://www.rfc-editor.org/rfc/rfc3022) | NAPT maps multiple local endpoints through one external network address | One observed public IP need not identify one computer. This is an informational networking RFC, not a licensing specification. |

The inability to instantly revoke authority on a disconnected device is a consequence of our proposed data flow: the old client has no new server information. A portal status change or generation counter cannot change that fact. Delayed reuse, accepted overlap and shorter offline grants are Cyrus policy alternatives, not vendor guarantees.

## Retrieval limits and excluded conclusions

- Autodesk's result “Can I have multiple users on one product subscription?” returned no body when opened. The accessible account-management pages support the claims used instead.
- Old Chaos `docs.chaos.com` licensing/borrowing URLs redirected to pages the research tool could not retrieve. Search indexing exposed an older official borrowing article, a weaker freshness source. The comparison uses opened Help Center articles and does not prescribe a current Chaos borrowing duration for Cyrus.
- Old Autodesk PDFs and community/forum posts appeared in searches but were excluded as evidence for current behavior.
- Public sources do not establish vendors' signing algorithms, code protectors, heartbeat intervals, internal databases or anti-debug methods. No such implementation claims are made.
- No reverse engineering, bypass testing, provider purchase, cloud deployment, payment integration or vendor runtime experiment occurred.
- No full web pages/manuals were copied into the repository. This register records concise claims and links; revisit them before customer-facing policy or compatibility claims.

## Local design inputs

- [Original licensing package](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md): architecture, permissions, threat model, signing, integration and tests.
- [Policy reconciliation](../Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md): perpetual/offline conflict, scene fidelity, runtime identity and operation lifetime.
- [Technical preparation](../Product_Commercialization_Playbook_2026-09-30/10_Licensing_Technical_Preparation.md): source boundaries and distinction between preparation and delivered behavior.
- [Commercial worksheet](../Product_Commercialization_Playbook_2026-09-30/09_Commercial_and_Licensing_Decisions.md): unapproved business terms and continuity choices.
- [Codebase integration audit](CODEBASE_AUDIT.md): ten findings traced through current generation, preview, CS Edit, Analyzer, bake/PFlow, startup and packaging paths. The [37-file snapshot and 38 native declarations](evidence/codebase_snapshot_2026-10-02.json) identify the reviewed dirty working tree; no build or runtime licensing qualification occurred.

The numbered September licensing chapters and diagrams remain preserved. Their entry page and manifest are updated only to route readers to the current plan; see [document audit](DOCUMENT_AUDIT.md). The October 2 cleanup also replaces the active strategy/playbook licensing instructions. Detailed seat, pricing and duration choices still require the decisions and validation recorded here.
