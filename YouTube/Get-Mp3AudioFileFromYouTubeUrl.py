from yt_dlp import YoutubeDL

audio_downloader = YoutubeDL({
    'format': 'bestaudio/best',
    'postprocessors': [{
        'key': 'FFmpegExtractAudio',
        'preferredcodec': 'mp3',
        'preferredquality': '192',
    }]
})

while True:
    try:
        print('Youtube Downloader'.center(40, '_'))
        URL = input('Enter youtube url : ')
        audio_downloader.extract_info(URL)
    except Exception:
        print("Couldn't download the audio")
    finally:
        option = int(input('\n 1.download again \n 2.Exit\n\n Option here :'))
        if option != 1:
            break
