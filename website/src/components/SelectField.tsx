import { useLayoutEffect, useRef, useState } from 'react'
import type { CSSProperties, KeyboardEvent } from 'react'
import { createPortal } from 'react-dom'
import './SelectField.css'

type Option = { value: string; label: string }
type Props = { id: string; label: string; value: string; options: Option[]; onChange: (value: string) => void }
type MenuPosition = CSSProperties & { '--select-list-height'?: string }

/** Select-only combobox: focus stays on the trigger while arrows explore the list. */
export function SelectField({ id, label, value, options, onChange }: Props) {
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const [position, setPosition] = useState<MenuPosition>({})
  const trigger = useRef<HTMLButtonElement>(null)
  const menu = useRef<HTMLDivElement>(null)
  const typed = useRef({ text: '', time: 0 })
  const selected = Math.max(0, options.findIndex(o => o.value === value))
  const listId = `${id}-list`
  const show = (index = selected) => { setActive(index); setOpen(true) }
  const choose = (index: number) => {
    const option = options[index]
    if (option) onChange(option.value)
    setOpen(false)
  }

  useLayoutEffect(() => {
    if (!open) return
    const place = () => {
      const rect = trigger.current!.getBoundingClientRect()
      const width = Math.min(Math.max(rect.width, options.length > 8 ? 320 : 240), window.innerWidth - 24)
      const below = window.innerHeight - rect.bottom - 12
      const above = rect.top - 12
      const upward = below < Math.min(210, options.length * 43 + 43) && above > below
      setPosition({
        width, left: Math.max(12, Math.min(rect.left, window.innerWidth - width - 12)),
        ...(upward ? { bottom: window.innerHeight - rect.top + 7 } : { top: rect.bottom + 7 }),
        '--select-list-height': `${Math.max(44, Math.min(304, (upward ? above : below) - 50))}px`,
      })
    }
    place()
    const outside = (event: Event) => {
      if (!trigger.current?.contains(event.target as Node) && !menu.current?.contains(event.target as Node)) setOpen(false)
    }
    window.addEventListener('resize', place)
    window.addEventListener('scroll', place, true)
    document.addEventListener('pointerdown', outside)
    document.addEventListener('focusin', outside)
    return () => {
      window.removeEventListener('resize', place)
      window.removeEventListener('scroll', place, true)
      document.removeEventListener('pointerdown', outside)
      document.removeEventListener('focusin', outside)
    }
  }, [open, options.length])

  useLayoutEffect(() => {
    if (!open) return
    const list = menu.current?.querySelector<HTMLElement>('[role=listbox]')
    const option = document.getElementById(`${id}-option-${active}`)
    if (!list || !option) return
    const item = option.getBoundingClientRect(), frame = list.getBoundingClientRect()
    // Scroll only the options, never the document underneath the floating menu.
    if (item.bottom > frame.bottom) list.scrollTop += item.bottom - frame.bottom + 4
    else if (item.top < frame.top) list.scrollTop -= frame.top - item.top + 4
  }, [open, active, id, position])

  const keyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
    const last = options.length - 1
    switch (event.key) {
      case 'ArrowDown': case 'ArrowUp':
        event.preventDefault()
        if (event.altKey && event.key === 'ArrowUp') { setOpen(false); return }
        if (!open) show()
        else setActive(i => Math.max(0, Math.min(last, i + (event.key === 'ArrowDown' ? 1 : -1))))
        return
      case 'Home': case 'End':
        event.preventDefault(); show(event.key === 'Home' ? 0 : last); return
      case 'Enter': case ' ':
        event.preventDefault()
        if (open) choose(active)
        else show()
        return
      case 'Escape':
        if (open) { event.preventDefault(); event.stopPropagation(); setOpen(false) }
        return
      case 'Tab': setOpen(false); return
    }
    if (event.key.length !== 1 || event.ctrlKey || event.metaKey || event.altKey) return
    event.preventDefault()
    const now = Date.now()
    const text = (now - typed.current.time < 700 ? typed.current.text : '') + event.key.toLocaleLowerCase()
    typed.current = { text, time: now }
    const prefix = [...text].every(c => c === text[0]) ? text[0] : text
    const start = open ? active : selected
    const match = options.findIndex((_, offset) => options[(start + 1 + offset) % options.length].label.toLocaleLowerCase().startsWith(prefix))
    if (match !== -1) show((start + 1 + match) % options.length)
  }

  return <div className="select-field">
    <span id={`${id}-label`} className="select-field__label">{label}</span>
    <button ref={trigger} id={id} type="button" role="combobox" className="select-field__trigger"
      aria-labelledby={`${id}-label ${id}-value`} aria-expanded={open} aria-haspopup="listbox" aria-controls={open ? listId : undefined}
      aria-activedescendant={open ? `${id}-option-${active}` : undefined}
      data-value={value} title={options[selected]?.label} onKeyDown={keyDown} onClick={() => open ? setOpen(false) : show()}>
      <span id={`${id}-value`} className="select-field__value">{options[selected]?.label}</span>
      <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="m4 6 4 4 4-4"/></svg>
    </button>
    {open && createPortal(<div ref={menu} className="select-menu" style={position}>
      <div className="select-menu__heading" aria-hidden="true"><span>{label}</span><span>{options.length.toString().padStart(2, '0')}</span></div>
      <div id={listId} role="listbox" aria-label={label} className="select-menu__list">
        {options.map((option, index) => <div key={option.value} id={`${id}-option-${index}`} role="option"
          aria-selected={option.value === value} className={`select-menu__option${active === index ? ' is-active' : ''}`}
          data-value={option.value} onMouseDown={e => e.preventDefault()} onPointerMove={e => { if (e.pointerType === 'mouse') setActive(index) }} onClick={() => choose(index)}>
          <span>{option.label}</span><svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="m3.5 8 3 3 6-6"/></svg>
        </div>)}
      </div>
    </div>, document.body)}
  </div>
}
