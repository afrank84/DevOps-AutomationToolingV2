sudo apt update && \
sudo apt install -y yt-dlp ffmpeg && \
mkdir -p ~/YouTube-Thumbnails && \
cd ~/YouTube-Thumbnails && \
for type in videos shorts streams; do
  yt-dlp \
    --skip-download \
    --write-thumbnail \
    --convert-thumbnails jpg \
    --ignore-errors \
    -o "%(title)s [%(id)s].%(ext)s" \
    "https://www.youtube.com/@YOURCHANNEL/$type"
done
