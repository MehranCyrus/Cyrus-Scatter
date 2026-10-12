/** Shared editorial headings; route shells are SelectedLanding and DocsShell. */
export function Eyebrow({ children, number }: { children: React.ReactNode; number?: string }) { return <p className="eyebrow">{number && <span>{number}</span>}{children}</p> }
export function PageHeading({ eyebrow, title, emphasis, description }: { eyebrow: string; title: string; emphasis?: string; description: string }) { return <div className="page-heading wrap"><Eyebrow>{eyebrow}</Eyebrow><h1>{title}{emphasis && <> <em>{emphasis}</em></>}</h1><p>{description}</p></div> }
