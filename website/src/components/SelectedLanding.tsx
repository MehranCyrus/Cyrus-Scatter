import { useEffect, useRef } from 'react'
import template from './selected-landing.html?raw'
import { reference } from '../content'
import { mountLanding } from './landing-controller'
import '../landing.css'

const markup=template.replaceAll('{{developmentVersion}}',reference.developmentVersion)

/** The selected composition, rendered inside one React-owned lifecycle boundary. */
export default function SelectedLanding() {
  const root = useRef<HTMLDivElement>(null)
  useEffect(() => root.current ? mountLanding(root.current) : undefined, [])
  return <div className="landing" ref={root} dangerouslySetInnerHTML={{ __html: markup }}/>
}
