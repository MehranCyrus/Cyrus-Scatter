import { asset } from '../content'

export function Arrow({ diagonal = false }: { diagonal?: boolean }) {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d={diagonal ? 'M6 18 18 6M6 6h12v12' : 'M4 12h15m-6-6 6 6-6 6'} stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" /></svg>
}
export function Mark({ small = false }: { small?: boolean }) {
  return <img className={small ? 'brand-logo small' : 'brand-logo'} src={asset('brand/logo-96.png')} srcSet={`${asset('brand/logo-192.png')} 2x`} width="40" height="40" alt="" aria-hidden="true"/>
}
export function SearchIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5" stroke="currentColor" strokeWidth="1.5"/><path d="m16 16 5 5" stroke="currentColor" strokeWidth="1.5"/></svg> }
