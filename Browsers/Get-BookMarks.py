import os
import json
import sqlite3
import sys
from pathlib import Path

def get_brave_bookmarks():
    if sys.platform == "win32":
        bookmarks_path = os.path.join(os.getenv('LOCALAPPDATA'), 'BraveSoftware', 'Brave-Browser', 'User Data', 'Default', 'Bookmarks')
    elif sys.platform == "darwin":
        bookmarks_path = os.path.expanduser('~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks')
    else:  # Linux
        bookmarks_path = os.path.expanduser('~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks')
    
    with open(bookmarks_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    def extract_bookmarks(node):
        bookmarks = []
        if node['type'] == 'url':
            bookmarks.append((node['name'], node['url']))
        elif 'children' in node:
            for child in node['children']:
                bookmarks.extend(extract_bookmarks(child))
        return bookmarks
    
    return extract_bookmarks(data['roots']['bookmark_bar'])

def get_chrome_bookmarks():
    if sys.platform == "win32":
        bookmarks_path = os.path.join(os.getenv('LOCALAPPDATA'), 'Google', 'Chrome', 'User Data', 'Default', 'Bookmarks')
    elif sys.platform == "darwin":
        bookmarks_path = os.path.expanduser('~/Library/Application Support/Google/Chrome/Default/Bookmarks')
    else:  # Linux
        bookmarks_path = os.path.expanduser('~/.config/google-chrome/Default/Bookmarks')
    
    with open(bookmarks_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    def extract_bookmarks(node):
        bookmarks = []
        if node['type'] == 'url':
            bookmarks.append((node['name'], node['url']))
        elif 'children' in node:
            for child in node['children']:
                bookmarks.extend(extract_bookmarks(child))
        return bookmarks
    
    return extract_bookmarks(data['roots']['bookmark_bar'])

def get_firefox_bookmarks():
    if sys.platform == "win32":
        profile_path = os.path.join(os.getenv('APPDATA'), 'Mozilla', 'Firefox', 'Profiles')
    elif sys.platform == "darwin":
        profile_path = os.path.expanduser('~/Library/Application Support/Firefox/Profiles')
    else:  # Linux
        profile_path = os.path.expanduser('~/.mozilla/firefox')
    
    profiles = [f for f in os.listdir(profile_path) if f.endswith('.default') or f.endswith('.default-release')]
    if not profiles:
        raise Exception("No Firefox profile found")
    
    places_path = os.path.join(profile_path, profiles[0], 'places.sqlite')
    
    conn = sqlite3.connect(places_path)
    cursor = conn.cursor()
    cursor.execute("SELECT moz_bookmarks.title, moz_places.url FROM moz_bookmarks JOIN moz_places ON moz_bookmarks.fk = moz_places.id WHERE moz_bookmarks.type = 1 AND moz_bookmarks.title IS NOT NULL")
    bookmarks = cursor.fetchall()
    conn.close()
    
    return bookmarks

def export_bookmarks(bookmarks, filename):
    with open(filename, 'w', encoding='utf-8') as f:
        for title, url in bookmarks:
            f.write(f"{title}\t{url}\n")

def main():
    print("Choose a browser to export bookmarks from:")
    print("1. Brave")
    print("2. Chrome")
    print("3. Firefox")
    choice = input("Enter your choice (1, 2, or 3): ")
    
    if choice == '1':
        bookmarks = get_brave_bookmarks()
        filename = "brave_bookmarks.txt"
    elif choice == '2':
        bookmarks = get_chrome_bookmarks()
        filename = "chrome_bookmarks.txt"
    elif choice == '3':
        bookmarks = get_firefox_bookmarks()
        filename = "firefox_bookmarks.txt"
    else:
        print("Invalid choice. Exiting.")
        return
    
    export_bookmarks(bookmarks, filename)
    print(f"Bookmarks exported to {filename}")

if __name__ == "__main__":
    main()
