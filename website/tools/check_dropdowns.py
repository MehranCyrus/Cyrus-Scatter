"""Exercise the shared dropdown with real headless pointer/keyboard input."""
from pathlib import Path
import argparse
import json
import subprocess
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--browser', required=True)
    parser.add_argument('--url', default='http://127.0.0.1:5180/')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    target = Path(args.output)
    target.parent.mkdir(parents=True, exist_ok=True)
    session = 'cyrus-dropdowns-' + str(int(time.time()))
    checks = []
    number = 0

    def run(*command):
        nonlocal number
        number += 1
        log = target.parent / f'dropdown-cli-{number:03}.log'
        with log.open('w', encoding='utf-8') as stream:
            result = subprocess.run([args.browser, '--session', session, *command], stdout=stream, stderr=subprocess.STDOUT, timeout=30)
        output = log.read_text(encoding='utf-8').strip()
        if result.returncode:
            raise RuntimeError(output)
        return output

    def dom(expression):
        return json.loads(json.loads(run('eval', 'JSON.stringify(' + expression + ')')))

    def check(name, expression):
        evidence = dom(expression)
        checks.append({'name': name, 'passed': evidence})
        assert evidence, name

    def open_page(route):
        run('open', args.url + '?review=dropdown-' + session + '#' + route)
        run('wait', '--fn', "document.querySelector('main h1')!==null")

    def key(selector, key):
        run('scrollintoview', selector)
        run('focus', selector)
        run('press', key)

    def bounds():
        return "(()=>{const r=document.querySelector('.select-menu').getBoundingClientRect();return r.left>=0&&r.right<=innerWidth&&r.top>=0&&r.bottom<=innerHeight})()"

    try:
        run('set', 'viewport', '1440', '1000')
        open_page('/visuals/viewport')
        key('#lesson-viewport-mode', 'Enter')
        check('Open / accessible active option', "document.activeElement.id==='lesson-viewport-mode'&&document.querySelector('[role=combobox]').getAttribute('aria-expanded')==='true'&&document.getElementById(document.activeElement.getAttribute('aria-activedescendant')).textContent==='Plant centres'")
        check('Desktop popup fits viewport', bounds())
        run('press', 'ArrowDown')
        check('Exploration does not commit', "document.querySelector('#lesson-viewport-mode').dataset.value==='Plant centres'&&document.querySelector('.select-menu__option.is-active').textContent==='Point Cloud'")
        run('press', 'Enter')
        check('Keyboard commits connected value', "document.querySelector('#lesson-viewport-mode').dataset.value==='Point Cloud'&&!document.querySelector('.select-menu')")
        key('#lesson-viewport-mode', 'm')
        check('Typeahead finds Mesh', "document.querySelector('.select-menu__option.is-active').textContent==='Mesh'")
        run('press', 'Escape')
        check('Escape cancels without changing value', "!document.querySelector('.select-menu')&&document.activeElement.id==='lesson-viewport-mode'&&document.activeElement.dataset.value==='Point Cloud'")
        key('#lesson-viewport-mode', 'Enter')
        run('click', '[role=option][data-value="Proxy"]')
        check('Pointer commits and retains focus', "document.querySelector('#lesson-viewport-mode').dataset.value==='Proxy'&&document.activeElement.id==='lesson-viewport-mode'")
        key('#lesson-viewport-mode', 'Enter')
        run('press', 'Tab')
        check('Tab closes and moves focus', "!document.querySelector('.select-menu')&&document.activeElement.id!=='lesson-viewport-mode'")
        key('#lesson-viewport-mode', 'Enter')
        run('click', '.lab-header h2')
        check('Outside click dismisses', "!document.querySelector('.select-menu')")
        key('#lesson-viewport-mode', 'Home')
        run('press', 'Enter')
        check('Home chooses first option', "document.querySelector('#lesson-viewport-mode').dataset.value==='Plant centres'")
        key('#lesson-viewport-mode', 'End')
        run('press', 'Enter')
        check('End chooses last option', "document.querySelector('#lesson-viewport-mode').dataset.value==='Mesh'")
        key('#lesson-viewport-mode', 'Enter')
        run('screenshot', str((target.parent / 'lesson-desktop.png').resolve()))
        for selector, param in [('control-group', 'group'), ('control-section', 'section'), ('control-owner', 'owner'), ('control-feature', 'feature')]:
            open_page('/controls')
            key('#' + selector, 'Enter')
            check(selector + ' fits viewport', bounds())
            value = dom("document.querySelectorAll('[role=option]')[1].dataset.value")
            run('click', '[role=option][data-value=' + json.dumps(value) + ']')
            check(selector + ' updates filter and URL', "document.querySelector('#" + selector + "').dataset.value===" + json.dumps(value) + "&&new URLSearchParams(location.hash.split('?')[1]).get('" + param + "')===" + json.dumps(value) + "&&document.querySelectorAll('.control-entry').length>0")
        open_page('/controls')
        key('#control-feature', 'End')
        check('Long list active option scrolls into view', "(()=>{const a=document.querySelector('.select-menu__option.is-active').getBoundingClientRect(),b=document.querySelector('.select-menu__list').getBoundingClientRect();return a.top>=b.top&&a.bottom<=b.bottom+1&&document.querySelector('.select-menu__list').scrollTop>0})()")
        run('screenshot', str((target.parent / 'catalog-desktop.png').resolve()))
        run('press', 'Escape')
        run('click', '.reset-filters')
        check('Reset restores all dropdowns', "Array.from(document.querySelectorAll('.select-field [role=combobox]')).every(e=>e.dataset.value==='')")
        run('set', 'viewport', '390', '844')
        open_page('/controls')
        key('#control-feature', 'Enter')
        check('Mobile catalog menu stays inside screen', bounds())
        check('Mobile catalog has no horizontal overflow', 'document.documentElement.scrollWidth<=innerWidth')
        check('Mobile labels stay paired with their dropdowns', "Array.from(document.querySelectorAll('.control-filter-field')).every(field=>{const label=field.querySelector('label').getBoundingClientRect(),button=field.querySelector('button').getBoundingClientRect();return button.top>=label.bottom&&button.top-label.bottom<12&&Math.abs(label.left-button.left)<1})")
        run('screenshot', str((target.parent / 'catalog-mobile.png').resolve()))
        run('press', 'Escape')
        open_page('/visuals/spacing')
        key('#lesson-spacing-scope', 'End')
        run('press', 'Enter')
        check('Mobile spacing choice connected', "document.querySelector('#lesson-spacing-scope').dataset.value==='layers'")
        key('#lesson-spacing-scope', 'Enter')
        check('Mobile lesson popup fits viewport', bounds())
        run('screenshot', str((target.parent / 'lesson-mobile.png').resolve()))
        run('press', 'Escape')
        open_page('/visuals/updates')
        key('#lesson-update-mode', 'End')
        run('press', 'Enter')
        check('Mobile update choice connected', "document.querySelector('#lesson-update-mode').dataset.value==='Live'")
        key('#lesson-update-mode', 'Enter')
        run('set', 'viewport', '360', '640')
        check('Open popup follows resize', bounds())
        run('press', 'Escape')
        check('No native select controls left', "!document.querySelector('select')")
        check('Accessible names include label and current value', "document.querySelector('[role=combobox]').getAttribute('aria-labelledby')==='lesson-update-mode-label lesson-update-mode-value'")
        errors = run('errors')
        checks.append({'name': 'No browser exceptions', 'passed': not errors, 'evidence': errors})
        assert not errors, errors
        target.write_text(json.dumps({'status': 'PASS', 'count': len(checks), 'checks': checks}, indent=2) + '\n', encoding='utf-8')
        print(f'PASS: {len(checks)} dropdown assertions')
    finally:
        run('close')


if __name__ == '__main__':
    main()
