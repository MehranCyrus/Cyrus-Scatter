import { useEffect, useRef } from 'react'
import template from './selected-landing.html?raw'
import { reference } from '../content'
import { showcasePlants } from '../content/plantShowcase'
import { currentRelease, decimalSize } from '../content/release'
import { mountLanding } from './landing-controller'
import '../landing.css'
import '../product-pages.css'

const landingSpecimens = ['A098', 'A086', 'A068', 'A023'].map(id => showcasePlants.find(plant => plant.id === id)!).map(plant => `<a class="landing-specimen" href="#/library"><span class="landing-specimen-image"><img src="${plant.image}" width="640" height="640" loading="lazy" alt="${plant.name}, individual Corona model preview"><span aria-hidden="true">↗</span></span><small>${plant.category}</small><strong>${plant.name}</strong></a>`).join('')
const markup=template.replaceAll('{{developmentVersion}}',reference.developmentVersion)
  .replaceAll('{{releaseVersion}}',currentRelease.version)
  .replaceAll('{{modelCount}}',String(currentRelease.models))
  .replaceAll('{{releaseHosts}}',currentRelease.maxYears.join(' / '))
  .replaceAll('{{installerSize}}',decimalSize(currentRelease.installerBytes))
  .replaceAll('{{contentSize}}',decimalSize(currentRelease.contentBytes))
  .replace('{{landingSpecimens}}',landingSpecimens)

/** The selected composition, rendered inside one React-owned lifecycle boundary. */
export default function SelectedLanding() {
  const root = useRef<HTMLDivElement>(null)
  useEffect(() => root.current ? mountLanding(root.current) : undefined, [])
  return <div className="landing" ref={root} dangerouslySetInnerHTML={{ __html: markup }}/>
}
