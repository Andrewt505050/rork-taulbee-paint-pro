import { useEffect } from "react";

const removeHostingBadge = (): void => {
  const candidates = document.querySelectorAll<HTMLElement>("a, button, div");
  for (const element of candidates) {
    const text = element.textContent?.trim().toLowerCase() ?? "";
    if (text === "built with rork" || text === "made with rork") {
      const target = element.closest<HTMLElement>("a") ?? element;
      const style = window.getComputedStyle(target);
      if (style.position === "fixed" || target.parentElement === document.body) target.remove();
    }
  }
};

/** Removes only the host-injected Rork attribution badge when present. */
const HostingBadgeHider = () => {
  useEffect((): (() => void) => {
    removeHostingBadge();
    const observer = new MutationObserver(removeHostingBadge);
    observer.observe(document.body, { childList: true, subtree: true });
    return (): void => observer.disconnect();
  }, []);
  return null;
};

export default HostingBadgeHider;
