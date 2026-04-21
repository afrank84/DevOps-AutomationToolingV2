import base64
import json
import os
import re
import threading
from pathlib import Path
from urllib.parse import quote

import requests
import tkinter as tk
from tkinter import ttk, filedialog, messagebox


class ConfluenceClient:
    def __init__(self, base_url: str, username: str, secret: str):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()

        auth_string = f"{username}:{secret}"
        encoded_auth = base64.b64encode(auth_string.encode("ascii")).decode("ascii")

        self.session.headers.update({
            "Authorization": f"Basic {encoded_auth}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        })

    def get_pages(self, space_key: str, limit: int = 100):
        all_pages = []
        start = 0

        while True:
            url = (
                f"{self.base_url}/rest/api/content"
                f"?spaceKey={quote(space_key)}"
                f"&type=page"
                f"&limit={limit}"
                f"&start={start}"
                f"&expand=version,space,history"
            )
            response = self.session.get(url, timeout=60)
            response.raise_for_status()
            data = response.json()

            results = data.get("results", [])
            all_pages.extend(results)

            if len(results) < limit:
                break

            start += limit

        return all_pages

    def get_page(self, page_id: str):
        url = (
            f"{self.base_url}/rest/api/content/{quote(str(page_id))}"
            f"?expand=body.storage,body.view,version,space,history,ancestors"
        )
        response = self.session.get(url, timeout=60)
        response.raise_for_status()
        return response.json()

    def get_attachments(self, page_id: str, limit: int = 100):
        url = (
            f"{self.base_url}/rest/api/content/{quote(str(page_id))}"
            f"/child/attachment?limit={limit}"
        )
        response = self.session.get(url, timeout=60)
        response.raise_for_status()
        return response.json().get("results", [])

    def download_file(self, download_url: str, output_file: Path):
        with self.session.get(download_url, timeout=120, stream=True) as response:
            response.raise_for_status()
            with open(output_file, "wb") as file_handle:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        file_handle.write(chunk)


def sanitize_filename(name: str) -> str:
    return re.sub(r'[\\/:*?"<>|]', "_", name)


def fix_image_paths(html_content: str, page_id: str) -> str:
    if not html_content:
        return html_content

    def replace_src(match):
        filename = match.group(2)
        safe_name = sanitize_filename(filename)
        return f'src="attachments/{safe_name}"'

    def replace_data_image_src(match):
        filename = match.group(1)
        safe_name = sanitize_filename(filename)
        return f'data-image-src="attachments/{safe_name}"'

    def replace_href(match):
        filename = match.group(1)
        safe_name = sanitize_filename(filename)
        return f'href="attachments/{safe_name}"'

    html_content = re.sub(
        rf'src="[^"]*?/download/(attachments|thumbnails)/{re.escape(str(page_id))}/([^?"]+)(\?[^"]*)??"',
        replace_src,
        html_content,
    )

    html_content = re.sub(
        rf'data-image-src="[^"]*?/download/attachments/{re.escape(str(page_id))}/([^?"]+)(\?[^"]*)??"',
        replace_data_image_src,
        html_content,
    )

    html_content = re.sub(
        rf'href="[^"]*?/download/attachments/{re.escape(str(page_id))}/([^?"]+)(\?[^"]*)??"',
        replace_href,
        html_content,
    )

    html_content = html_content.replace("\u00C2 ", " ")
    html_content = html_content.replace("\u00C2&nbsp;", "&nbsp;")
    html_content = html_content.replace("\u00C2", " ")

    return html_content


class ConfluenceBackupApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Confluence Page Backup Tool")
        self.root.geometry("980x720")

        self.create_widgets()

    def create_widgets(self):
        main = ttk.Frame(self.root, padding=12)
        main.pack(fill="both", expand=True)

        form = ttk.LabelFrame(main, text="Connection and Backup Settings", padding=12)
        form.pack(fill="x")

        self.url_var = tk.StringVar()
        self.user_var = tk.StringVar()
        self.secret_var = tk.StringVar()
        self.space_var = tk.StringVar()
        self.output_var = tk.StringVar(value=str(Path.cwd() / "confluence-backup"))
        self.page_id_var = tk.StringVar()
        self.list_only_var = tk.BooleanVar(value=False)

        row = 0
        self._add_label_entry(form, "Confluence URL", self.url_var, row)
        row += 1
        self._add_label_entry(form, "Username", self.user_var, row)
        row += 1
        self._add_label_entry(form, "Password / API Token", self.secret_var, row, show="*")
        row += 1
        self._add_label_entry(form, "Space Key", self.space_var, row)
        row += 1
        self._add_output_row(form, row)
        row += 1
        self._add_label_entry(form, "Page ID (optional)", self.page_id_var, row)
        row += 1

        ttk.Checkbutton(form, text="List only (do not download content)", variable=self.list_only_var).grid(
            row=row, column=1, sticky="w", pady=6
        )

        button_bar = ttk.Frame(main)
        button_bar.pack(fill="x", pady=(12, 8))

        self.run_button = ttk.Button(button_bar, text="Run", command=self.start_backup)
        self.run_button.pack(side="left")

        self.clear_button = ttk.Button(button_bar, text="Clear Log", command=self.clear_log)
        self.clear_button.pack(side="left", padx=(8, 0))

        log_frame = ttk.LabelFrame(main, text="Log", padding=8)
        log_frame.pack(fill="both", expand=True)

        self.log_text = tk.Text(log_frame, wrap="word", height=25)
        self.log_text.pack(side="left", fill="both", expand=True)

        scrollbar = ttk.Scrollbar(log_frame, orient="vertical", command=self.log_text.yview)
        scrollbar.pack(side="right", fill="y")
        self.log_text.configure(yscrollcommand=scrollbar.set)

    def _add_label_entry(self, parent, label, text_var, row, show=None):
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 10), pady=6)
        entry = ttk.Entry(parent, textvariable=text_var, width=80, show=show)
        entry.grid(row=row, column=1, sticky="ew", pady=6)
        parent.columnconfigure(1, weight=1)

    def _add_output_row(self, parent, row):
        ttk.Label(parent, text="Output Folder").grid(row=row, column=0, sticky="w", padx=(0, 10), pady=6)
        output_frame = ttk.Frame(parent)
        output_frame.grid(row=row, column=1, sticky="ew", pady=6)
        output_frame.columnconfigure(0, weight=1)

        ttk.Entry(output_frame, textvariable=self.output_var, width=65).grid(row=0, column=0, sticky="ew")
        ttk.Button(output_frame, text="Browse", command=self.browse_output).grid(row=0, column=1, padx=(8, 0))

    def browse_output(self):
        folder = filedialog.askdirectory()
        if folder:
            self.output_var.set(folder)

    def clear_log(self):
        self.log_text.delete("1.0", tk.END)

    def log(self, message: str):
        self.root.after(0, self._append_log, message)

    def _append_log(self, message: str):
        self.log_text.insert(tk.END, message + "\n")
        self.log_text.see(tk.END)

    def validate_inputs(self):
        if not self.url_var.get().strip():
            messagebox.showerror("Missing input", "Confluence URL is required.")
            return False
        if not self.user_var.get().strip():
            messagebox.showerror("Missing input", "Username is required.")
            return False
        if not self.secret_var.get().strip():
            messagebox.showerror("Missing input", "Password or API token is required.")
            return False
        if not self.page_id_var.get().strip() and not self.space_var.get().strip():
            messagebox.showerror("Missing input", "Space Key is required when Page ID is not specified.")
            return False
        return True

    def start_backup(self):
        if not self.validate_inputs():
            return

        self.run_button.config(state="disabled")
        worker = threading.Thread(target=self.run_backup, daemon=True)
        worker.start()

    def run_backup(self):
        try:
            self.log("=== Confluence Page Backup Tool ===")
            self.log("")

            base_url = self.url_var.get().strip()
            username = self.user_var.get().strip()
            secret = self.secret_var.get().strip()
            space_key = self.space_var.get().strip()
            output_path = Path(self.output_var.get().strip())
            page_id = self.page_id_var.get().strip()
            list_only = self.list_only_var.get()

            output_path.mkdir(parents=True, exist_ok=True)

            client = ConfluenceClient(base_url, username, secret)

            if page_id:
                self.log(f"Fetching page ID: {page_id}")
                page = client.get_page(page_id)

                self.log("")
                self.log("Page Details:")
                self.log(f"  ID: {page.get('id', '')}")
                self.log(f"  Title: {page.get('title', '')}")

                space = page.get("space", {})
                version = page.get("version", {})
                version_by = version.get("by", {})
                self.log(f"  Space: {space.get('key', '')} - {space.get('name', '')}")
                self.log(f"  Version: {version.get('number', '')}")
                self.log(f"  Last Modified: {version.get('when', '')}")
                self.log(f"  Modified By: {version_by.get('displayName', '')}")
                self.log("")

                if not list_only:
                    saved_path = self.save_page_content(client, page, output_path)
                    self.log("")
                    self.log(f"Page saved to: {saved_path}")

            else:
                self.log(f"Fetching pages from space: {space_key}")
                pages = client.get_pages(space_key)

                self.log("")
                self.log(f"Found {len(pages)} pages in space '{space_key}'")
                self.log("")

                for page in pages:
                    page_id_value = page.get("id", "")
                    title = page.get("title", "")
                    version = page.get("version", {}).get("number", "")
                    created = page.get("history", {}).get("createdDate", "")
                    self.log(f"[{page_id_value}] {title}")
                    self.log(f"  Version: {version} | Created: {created}")

                if not list_only:
                    self.log("")
                    self.log("Downloading full content for all pages...")
                    self.log("")

                    for index, page in enumerate(pages, start=1):
                        title = page.get("title", "")
                        current_page_id = page.get("id", "")
                        self.log(f"[{index}/{len(pages)}] Processing: {title}")
                        full_page = client.get_page(current_page_id)
                        self.save_page_content(client, full_page, output_path)
                        self.log("")

                    self.log(f"Backup complete. All pages saved to: {output_path}")

            self.log("")
            self.log("Done.")

        except requests.HTTPError as exc:
            self.log(f"HTTP error: {exc}")
            messagebox.showerror("Error", f"HTTP error:\n{exc}")
        except Exception as exc:
            self.log(f"Error: {exc}")
            messagebox.showerror("Error", str(exc))
        finally:
            self.root.after(0, lambda: self.run_button.config(state="normal"))

    def save_page_content(self, client: ConfluenceClient, page: dict, output_directory: Path) -> Path:
        page_id = str(page.get("id", "unknown"))
        title = page.get("title", "untitled")
        safe_title = sanitize_filename(title)
        page_dir = output_directory / f"{page_id}_{safe_title}"
        page_dir.mkdir(parents=True, exist_ok=True)

        body = page.get("body", {})
        storage_value = body.get("storage", {}).get("value")
        view_value = body.get("view", {}).get("value")

        if storage_value:
            storage_path = page_dir / "content.html"
            fixed_storage = fix_image_paths(storage_value, page_id)
            storage_path.write_text(fixed_storage, encoding="utf-8")
            self.log(f"  Saved storage format to: {storage_path}")

        if view_value:
            view_path = page_dir / "content_view.html"
            fixed_view = fix_image_paths(view_value, page_id)
            view_path.write_text(fixed_view, encoding="utf-8")
            self.log(f"  Saved view format to: {view_path}")

        attachment_count = self.download_attachments(client, page_id, page_dir)

        metadata_path = page_dir / "metadata.json"
        version = page.get("version", {})
        version_by = version.get("by", {})
        history = page.get("history", {})
        created_by = history.get("createdBy", {})
        space = page.get("space", {})
        links = page.get("_links", {})

        metadata = {
            "id": page.get("id"),
            "title": page.get("title"),
            "type": page.get("type"),
            "status": page.get("status"),
            "version": version.get("number"),
            "spaceKey": space.get("key"),
            "spaceName": space.get("name"),
            "createdDate": history.get("createdDate"),
            "createdBy": created_by.get("displayName"),
            "lastModified": version.get("when"),
            "lastModifiedBy": version_by.get("displayName"),
            "webUrl": links.get("webui"),
            "attachmentCount": attachment_count,
        }

        metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
        self.log(f"  Saved metadata to: {metadata_path}")

        return page_dir

    def download_attachments(self, client: ConfluenceClient, page_id: str, page_dir: Path) -> int:
        self.log("  Checking for attachments...")
        try:
            attachments = client.get_attachments(page_id)
            if not attachments:
                return 0

            attachments_dir = page_dir / "attachments"
            attachments_dir.mkdir(parents=True, exist_ok=True)

            downloaded_count = 0
            for attachment in attachments:
                filename = attachment.get("title", "attachment")
                safe_filename = sanitize_filename(filename)
                links = attachment.get("_links", {})
                relative_download = links.get("download")

                if not relative_download:
                    continue

                download_url = f"{client.base_url}{relative_download}"
                output_file = attachments_dir / safe_filename

                self.log(f"    Downloading attachment: {filename}")
                try:
                    client.download_file(download_url, output_file)
                    downloaded_count += 1
                except Exception as exc:
                    self.log(f"    Warning: failed to download {filename}: {exc}")

            if downloaded_count > 0:
                self.log(f"  Downloaded {downloaded_count} attachment(s)")

            return downloaded_count

        except Exception as exc:
            self.log(f"  Warning: failed to fetch attachments for page {page_id}: {exc}")
            return 0


def main():
    root = tk.Tk()
    app = ConfluenceBackupApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
