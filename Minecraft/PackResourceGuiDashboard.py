#!/usr/bin/env python3
"""
Minecraft Java Resource Pack Dashboard (Tkinter)

- Lists vanilla block textures from a selected Minecraft version .jar
- Shows whether your pack overrides each texture (✅/❌)
- Preview selected texture
- Create override PNGs into your pack (optionally integer scale: 1x/2x/4x/8x)
- Open selected override in external editor
- Zip the pack

No external libraries (no Pillow). Uses Tkinter PhotoImage zoom for integer scaling.
"""

import os
import sys
import shutil
import zipfile
import tempfile
import platform
import subprocess
from pathlib import Path
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

JAR_BLOCK_PREFIX = "assets/minecraft/textures/block/"
PACK_BLOCK_PREFIX = Path("assets/minecraft/textures/block")

# -------------------------
# Path helpers
# -------------------------
def default_minecraft_dir() -> Path:
    system = platform.system().lower()
    home = Path.home()

    if "windows" in system:
        appdata = os.environ.get("APPDATA")
        if appdata:
            return Path(appdata) / ".minecraft"
        return home / "AppData" / "Roaming" / ".minecraft"

    if "darwin" in system or "mac" in system:
        return home / "Library" / "Application Support" / "minecraft"

    # Linux
    return home / ".minecraft"


def guess_latest_version_folder(mcdir: Path) -> str | None:
    versions_dir = mcdir / "versions"
    if not versions_dir.exists():
        return None
    # Pick most recently modified version folder that contains a matching .jar
    candidates = []
    for p in versions_dir.iterdir():
        if p.is_dir():
            jar = p / f"{p.name}.jar"
            if jar.exists():
                candidates.append((jar.stat().st_mtime, p.name))
    if not candidates:
        return None
    candidates.sort(reverse=True)
    return candidates[0][1]


def open_in_file_manager(path: Path):
    system = platform.system().lower()
    try:
        if "windows" in system:
            os.startfile(str(path))  # type: ignore[attr-defined]
        elif "darwin" in system or "mac" in system:
            subprocess.run(["open", str(path)], check=False)
        else:
            subprocess.run(["xdg-open", str(path)], check=False)
    except Exception:
        pass


def open_file_in_default_app(path: Path):
    open_in_file_manager(path)


# -------------------------
# Core logic
# -------------------------
def list_vanilla_block_pngs(jar_path: Path) -> list[str]:
    with zipfile.ZipFile(jar_path, "r") as z:
        names = z.namelist()
    pngs = [
        n[len(JAR_BLOCK_PREFIX):]
        for n in names
        if n.startswith(JAR_BLOCK_PREFIX) and n.endswith(".png")
    ]
    pngs.sort()
    return pngs


def extract_vanilla_png(jar_path: Path, rel_png: str, dest_file: Path) -> None:
    member = JAR_BLOCK_PREFIX + rel_png
    dest_file.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(jar_path, "r") as z:
        with z.open(member) as src, open(dest_file, "wb") as dst:
            shutil.copyfileobj(src, dst)


def pack_override_path(pack_root: Path, rel_png: str) -> Path:
    return pack_root / PACK_BLOCK_PREFIX / rel_png


def ensure_pack_skeleton(pack_root: Path, pack_format: str, description: str) -> None:
    pack_root.mkdir(parents=True, exist_ok=True)
    assets_dir = pack_root / "assets" / "minecraft" / "textures" / "block"
    assets_dir.mkdir(parents=True, exist_ok=True)

    mcmeta = pack_root / "pack.mcmeta"
    if not mcmeta.exists():
        # Simple JSON; escape quotes minimally
        safe_desc = description.replace('"', '\\"')
        mcmeta.write_text(
            '{\n'
            '  "pack": {\n'
            f'    "pack_format": {pack_format},\n'
            f'    "description": "{safe_desc}"\n'
            "  }\n"
            "}\n",
            encoding="utf-8",
        )


def zip_pack(pack_root: Path, out_zip: Path) -> None:
    if out_zip.exists():
        out_zip.unlink()

    with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for p in pack_root.rglob("*"):
            if p.is_file():
                rel = p.relative_to(pack_root)
                z.write(p, arcname=str(rel))


# -------------------------
# Tkinter App
# -------------------------
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Minecraft Block Texture Pack Dashboard (Tkinter)")
        self.geometry("1000x650")

        self.mcdir = default_minecraft_dir()
        self.version = tk.StringVar()
        self.jar_path: Path | None = None
        self.pack_root: Path | None = None

        self.pack_format = tk.StringVar(value="15")  # user-editable; varies by MC version
        self.pack_desc = tk.StringVar(value="My Resource Pack")

        self.scale_choice = tk.StringVar(value="1x")

        # Cache dir for extracted vanilla PNGs
        self.cache_dir = Path(tempfile.mkdtemp(prefix="mc_pack_dash_"))
        self.protocol("WM_DELETE_WINDOW", self.on_close)

        # UI state
        self.texture_list: list[str] = []
        self.thumb_images: dict[str, tk.PhotoImage] = {}
        self.preview_image: tk.PhotoImage | None = None
        self.selected_rel_png: str | None = None

        self._build_ui()
        self._autofill_guess()

    def _build_ui(self):
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        # Top controls
        top = ttk.Frame(self, padding=8)
        top.grid(row=0, column=0, sticky="ew")
        for c in range(10):
            top.columnconfigure(c, weight=0)
        top.columnconfigure(5, weight=1)

        ttk.Label(top, text="Minecraft dir:").grid(row=0, column=0, sticky="w")
        self.mcdir_label = ttk.Label(top, text=str(self.mcdir))
        self.mcdir_label.grid(row=0, column=1, sticky="w", padx=(6, 12))
        ttk.Button(top, text="Change…", command=self.pick_mcdir).grid(row=0, column=2, padx=4)

        ttk.Label(top, text="Version:").grid(row=0, column=3, sticky="w", padx=(12, 4))
        self.version_entry = ttk.Entry(top, textvariable=self.version, width=14)
        self.version_entry.grid(row=0, column=4, sticky="w")
        ttk.Button(top, text="Load JAR", command=self.load_jar).grid(row=0, column=5, sticky="w", padx=6)

        ttk.Separator(top, orient="vertical").grid(row=0, column=6, sticky="ns", padx=10)

        ttk.Label(top, text="Pack folder:").grid(row=0, column=7, sticky="w")
        ttk.Button(top, text="Choose…", command=self.pick_pack_root).grid(row=0, column=8, padx=6)

        self.pack_label = ttk.Label(top, text="(not set)")
        self.pack_label.grid(row=0, column=9, sticky="w")

        # Middle: list + preview
        mid = ttk.Frame(self, padding=(8, 0, 8, 8))
        mid.grid(row=1, column=0, sticky="nsew")
        mid.columnconfigure(0, weight=2)
        mid.columnconfigure(1, weight=1)
        mid.rowconfigure(0, weight=1)

        # Tree list
        left = ttk.Frame(mid)
        left.grid(row=0, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)

        columns = ("status", "name")
        self.tree = ttk.Treeview(left, columns=columns, show="headings", height=20)
        self.tree.heading("status", text="Done")
        self.tree.heading("name", text="Texture filename")
        self.tree.column("status", width=60, anchor="center")
        self.tree.column("name", width=520, anchor="w")

        yscroll = ttk.Scrollbar(left, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=yscroll.set)

        self.tree.grid(row=0, column=0, sticky="nsew")
        yscroll.grid(row=0, column=1, sticky="ns")

        self.tree.bind("<<TreeviewSelect>>", self.on_select)

        # Preview panel
        right = ttk.Frame(mid)
        right.grid(row=0, column=1, sticky="nsew")
        right.columnconfigure(0, weight=1)
        right.rowconfigure(2, weight=1)

        ttk.Label(right, text="Preview (vanilla):").grid(row=0, column=0, sticky="w")
        self.preview_label = ttk.Label(right, text="(select a texture)")
        self.preview_label.grid(row=1, column=0, sticky="w", pady=(0, 6))

        self.preview_canvas = tk.Label(right, relief="solid", borderwidth=1)
        self.preview_canvas.grid(row=2, column=0, sticky="nsew")

        # Bottom actions
        bottom = ttk.Frame(self, padding=8)
        bottom.grid(row=2, column=0, sticky="ew")
        bottom.columnconfigure(10, weight=1)

        ttk.Label(bottom, text="Scale:").grid(row=0, column=0, sticky="w")
        scale_combo = ttk.Combobox(bottom, textvariable=self.scale_choice, values=["1x", "2x", "4x", "8x"], width=5, state="readonly")
        scale_combo.grid(row=0, column=1, sticky="w", padx=(6, 12))

        ttk.Label(bottom, text="pack_format:").grid(row=0, column=2, sticky="w")
        ttk.Entry(bottom, textvariable=self.pack_format, width=6).grid(row=0, column=3, sticky="w", padx=(6, 12))

        ttk.Label(bottom, text="Description:").grid(row=0, column=4, sticky="w")
        ttk.Entry(bottom, textvariable=self.pack_desc, width=28).grid(row=0, column=5, sticky="w", padx=(6, 12))

        ttk.Button(bottom, text="Create/Update override", command=self.create_override).grid(row=0, column=6, padx=4)
        ttk.Button(bottom, text="Open override", command=self.open_override).grid(row=0, column=7, padx=4)
        ttk.Button(bottom, text="Refresh status", command=self.refresh_status).grid(row=0, column=8, padx=4)
        ttk.Button(bottom, text="Zip pack…", command=self.zip_pack_action).grid(row=0, column=9, padx=4)

        ttk.Label(bottom, text="Tip: pack overrides go to assets/minecraft/textures/block/").grid(row=1, column=0, columnspan=11, sticky="w", pady=(8, 0))

    def _autofill_guess(self):
        # try to guess latest version folder
        v = guess_latest_version_folder(self.mcdir)
        if v:
            self.version.set(v)

    def pick_mcdir(self):
        d = filedialog.askdirectory(title="Select .minecraft folder")
        if not d:
            return
        self.mcdir = Path(d)
        self.mcdir_label.config(text=str(self.mcdir))
        self._autofill_guess()

    def load_jar(self):
        version = self.version.get().strip()
        if not version:
            messagebox.showerror("Missing version", "Enter a version folder name (e.g. 1.20.4).")
            return

        jar = self.mcdir / "versions" / version / f"{version}.jar"
        if not jar.exists():
            messagebox.showerror("JAR not found", f"Could not find:\n{jar}")
            return

        self.jar_path = jar
        try:
            self.texture_list = list_vanilla_block_pngs(jar)
        except Exception as e:
            messagebox.showerror("Failed to read jar", str(e))
            return

        self.populate_tree()
        self.refresh_status()
        messagebox.showinfo("Loaded", f"Loaded {len(self.texture_list)} block textures from:\n{jar}")

    def pick_pack_root(self):
        d = filedialog.askdirectory(title="Select your resource pack folder (root)")
        if not d:
            return
        self.pack_root = Path(d)
        self.pack_label.config(text=str(self.pack_root))
        self.refresh_status()

    def populate_tree(self):
        # Clear
        for item in self.tree.get_children():
            self.tree.delete(item)

        for rel_png in self.texture_list:
            self.tree.insert("", "end", iid=rel_png, values=("❌", rel_png))

    def refresh_status(self):
        if not self.texture_list:
            return

        for rel_png in self.texture_list:
            status = "❌"
            if self.pack_root:
                ov = pack_override_path(self.pack_root, rel_png)
                if ov.exists():
                    status = "✅"
            # update row
            try:
                self.tree.set(rel_png, "status", status)
            except tk.TclError:
                pass

    def on_select(self, _evt=None):
        sel = self.tree.selection()
        if not sel:
            self.selected_rel_png = None
            return

        rel_png = sel[0]
        self.selected_rel_png = rel_png
        self.preview_label.config(text=rel_png)

        if not self.jar_path:
            return

        # Extract vanilla png into cache for PhotoImage to load
        cached_file = self.cache_dir / "vanilla_block" / rel_png
        if not cached_file.exists():
            try:
                extract_vanilla_png(self.jar_path, rel_png, cached_file)
            except Exception as e:
                messagebox.showerror("Extract failed", f"Could not extract {rel_png}:\n{e}")
                return

        # Load and show a larger preview using integer zoom
        try:
            img = tk.PhotoImage(file=str(cached_file))
            # show at 8x in preview if it's a 16x16; still fine if bigger
            img = img.zoom(8, 8)
            self.preview_image = img  # keep ref
            self.preview_canvas.config(image=self.preview_image)
        except Exception as e:
            messagebox.showerror("Preview failed", f"Could not preview {rel_png}:\n{e}")

    def _scale_factor(self) -> int:
        s = self.scale_choice.get().strip().lower()
        return {"1x": 1, "2x": 2, "4x": 4, "8x": 8}.get(s, 1)

    def create_override(self):
        if not self.jar_path:
            messagebox.showerror("No jar loaded", "Click 'Load JAR' first.")
            return
        if not self.pack_root:
            messagebox.showerror("No pack folder", "Choose your pack folder first.")
            return
        if not self.selected_rel_png:
            messagebox.showerror("No selection", "Select a texture first.")
            return

        # Ensure pack skeleton
        pf = self.pack_format.get().strip()
        if not pf.isdigit():
            messagebox.showerror("pack_format invalid", "pack_format must be a number (example: 15).")
            return
        ensure_pack_skeleton(self.pack_root, pf, self.pack_desc.get().strip() or "My Resource Pack")

        rel_png = self.selected_rel_png
        vanilla_file = self.cache_dir / "vanilla_block" / rel_png
        if not vanilla_file.exists():
            try:
                extract_vanilla_png(self.jar_path, rel_png, vanilla_file)
            except Exception as e:
                messagebox.showerror("Extract failed", f"Could not extract {rel_png}:\n{e}")
                return

        out_file = pack_override_path(self.pack_root, rel_png)
        out_file.parent.mkdir(parents=True, exist_ok=True)

        factor = self._scale_factor()
        if factor == 1:
            shutil.copy2(vanilla_file, out_file)
        else:
            # Tkinter-only scaling via PhotoImage.zoom (integer)
            try:
                img = tk.PhotoImage(file=str(vanilla_file))
                scaled = img.zoom(factor, factor)
                # write as PNG
                scaled.write(str(out_file), format="png")
            except Exception as e:
                messagebox.showerror(
                    "Scale failed",
                    "Scaling requires Tkinter to load and write the PNG.\n"
                    f"File: {rel_png}\nError: {e}"
                )
                return

        self.refresh_status()
        open_in_file_manager(out_file.parent)

    def open_override(self):
        if not self.pack_root or not self.selected_rel_png:
            return
        ov = pack_override_path(self.pack_root, self.selected_rel_png)
        if not ov.exists():
            messagebox.showinfo("No override yet", "That texture is not overridden yet. Use 'Create/Update override' first.")
            return
        open_file_in_default_app(ov)

    def zip_pack_action(self):
        if not self.pack_root:
            messagebox.showerror("No pack folder", "Choose your pack folder first.")
            return

        # Ensure mcmeta exists
        pf = self.pack_format.get().strip()
        if not pf.isdigit():
            messagebox.showerror("pack_format invalid", "pack_format must be a number (example: 15).")
            return
        ensure_pack_skeleton(self.pack_root, pf, self.pack_desc.get().strip() or "My Resource Pack")

        out = filedialog.asksaveasfilename(
            title="Save resource pack zip",
            defaultextension=".zip",
            filetypes=[("Zip files", "*.zip")]
        )
        if not out:
            return

        out_zip = Path(out)
        try:
            zip_pack(self.pack_root, out_zip)
        except Exception as e:
            messagebox.showerror("Zip failed", str(e))
            return

        messagebox.showinfo("Done", f"Zipped pack to:\n{out_zip}")
        open_in_file_manager(out_zip.parent)

    def on_close(self):
        try:
            shutil.rmtree(self.cache_dir, ignore_errors=True)
        except Exception:
            pass
        self.destroy()


if __name__ == "__main__":
    # Use themed widgets where possible
    try:
        import tkinter.font  # noqa
    except Exception:
        pass

    app = App()
    app.mainloop()
