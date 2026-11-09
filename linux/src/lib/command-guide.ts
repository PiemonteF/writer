import { commandRows, type CommandAction, type CommandItem } from "./commands";

export type GuideHandlers = {
  run: (action: CommandAction) => void;
};

export function mountCommandGuide(
  dialog: HTMLDialogElement,
  handlers: GuideHandlers,
): {
  open: () => void;
  close: () => void;
  toggle: () => void;
  isOpen: () => boolean;
} {
  const search = dialog.querySelector<HTMLInputElement>("#commands-search")!;
  const list = dialog.querySelector<HTMLElement>("#commands-list")!;
  const empty = dialog.querySelector<HTMLElement>("#commands-empty")!;

  let selectedIndex = -1;
  let visible: CommandItem[] = [];

  function commandItemsFromRows(query: string): CommandItem[] {
    return commandRows(query)
      .filter((row): row is { kind: "command"; item: CommandItem } => row.kind === "command")
      .map((row) => row.item);
  }

  function render(query: string) {
    const rows = commandRows(query);
    visible = commandItemsFromRows(query);
    list.innerHTML = "";
    empty.hidden = visible.length > 0;

    for (const row of rows) {
      if (row.kind === "group") {
        const heading = document.createElement("li");
        heading.className = "commands-group";
        heading.textContent = row.title;
        heading.setAttribute("role", "presentation");
        list.append(heading);
        continue;
      }

      const item = row.item;
      const li = document.createElement("li");
      li.className = "commands-item";
      li.tabIndex = -1;
      li.dataset.action = item.action ?? "";
      li.setAttribute("role", "option");

      const text = document.createElement("div");
      text.className = "commands-item-text";
      const title = document.createElement("span");
      title.className = "commands-item-title";
      title.textContent = item.title;
      const summary = document.createElement("span");
      summary.className = "commands-item-summary";
      summary.textContent = item.summary;
      text.append(title, summary);

      const kbd = document.createElement("kbd");
      kbd.textContent = item.shortcut || "—";

      li.append(text, kbd);
      if (item.action) {
        li.addEventListener("click", () => {
          handlers.run(item.action!);
          if (item.action !== "commands") dialog.close();
        });
      }
      list.append(li);
    }

    selectedIndex = visible.length > 0 ? 0 : -1;
    syncSelection();
  }

  function itemElements(): HTMLLIElement[] {
    return Array.from(list.querySelectorAll<HTMLLIElement>(".commands-item"));
  }

  function syncSelection() {
    const els = itemElements();
    els.forEach((el, i) => {
      el.classList.toggle("selected", i === selectedIndex);
      el.setAttribute("aria-selected", i === selectedIndex ? "true" : "false");
    });
    els[selectedIndex]?.scrollIntoView({ block: "nearest" });
  }

  function open() {
    render(search.value);
    if (!dialog.open) dialog.showModal();
    search.focus();
    search.select();
  }

  function close() {
    dialog.close();
  }

  function toggle() {
    if (dialog.open) close();
    else open();
  }

  search.addEventListener("input", () => {
    render(search.value);
  });

  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) close();
  });

  dialog.addEventListener("close", () => {
    search.value = "";
    selectedIndex = -1;
  });

  dialog.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      event.preventDefault();
      close();
      return;
    }

    const els = itemElements();
    if (event.key === "ArrowDown") {
      event.preventDefault();
      if (els.length === 0) return;
      selectedIndex = (selectedIndex + 1) % els.length;
      syncSelection();
      return;
    }
    if (event.key === "ArrowUp") {
      event.preventDefault();
      if (els.length === 0) return;
      selectedIndex = (selectedIndex - 1 + els.length) % els.length;
      syncSelection();
      return;
    }
    if (event.key === "Enter") {
      const item = visible[selectedIndex];
      if (!item?.action) return;
      event.preventDefault();
      handlers.run(item.action);
      if (item.action !== "commands") close();
    }
  });

  return {
    open,
    close,
    toggle,
    isOpen: () => dialog.open,
  };
}
