(() => {
    const header = document.querySelector('.site-header');
    const toggle = document.querySelector('.menu-toggle');
    const navigation = document.querySelector('#site-navigation');

    if (!header || !toggle || !navigation) return;

    const setMenu = (open, returnFocus = false) => {
        toggle.setAttribute('aria-expanded', String(open));
        toggle.setAttribute('aria-label', open ? 'Menü schließen' : 'Menü öffnen');
        navigation.classList.toggle('is-open', open);
        if (returnFocus) toggle.focus();
    };

    toggle.addEventListener('click', () => {
        setMenu(toggle.getAttribute('aria-expanded') !== 'true');
    });

    navigation.addEventListener('click', (event) => {
        if (event.target.closest('a')) setMenu(false);
    });

    document.addEventListener('click', (event) => {
        if (!header.contains(event.target)) setMenu(false);
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
            setMenu(false, true);
        }
    });

    window.matchMedia('(min-width: 721px)').addEventListener('change', () => setMenu(false));
})();
