import threading
import requests
import cv2
import numpy as np
import matplotlib.pyplot as plt
from collections import deque

# Configuration
STREAM_URL   = 'http://192.168.0.112/stream'  # ← change to your IP/hostname
AUDIO_URL    = 'http://192.168.0.112:81/audio'
SAMPLE_RATE  = 16000                          # must match the ESP define
BYTES_PER_FR = 2                              # 16-bit mono ⇒ 2 bytes / frame
CHUNK_FRAMES = SAMPLE_RATE // 10              # 200 ms = 1600 frames
CHUNK_BYTES  = BYTES_PER_FR * CHUNK_FRAMES
FIFO_LIMIT   = 50                             # number of chunks to keep

# rolling buffer for audio
audio_buffer = deque(maxlen=FIFO_LIMIT)

def audio_plot():
    """Continuously read audio chunks and update a live waveform plot."""
    plt.ion()
    fig, ax = plt.subplots()
    line, = ax.plot([], [], lw=1)
    ax.set_title("Live Audio Waveform")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Amplitude")
    ax.set_ylim(-32768, 32767)

    buf = b''
    for data in requests.get(AUDIO_URL, stream=True).iter_content(4096):
        buf += data
        while len(buf) >= CHUNK_BYTES:
            chunk, buf = buf[:CHUNK_BYTES], buf[CHUNK_BYTES:]
            samples = np.frombuffer(chunk, dtype=np.int16)
            audio_buffer.append(samples)

            # concatenate and plot
            all_samples = np.concatenate(audio_buffer)
            t = np.linspace(-len(all_samples)/SAMPLE_RATE, 0, len(all_samples))
            line.set_data(t, all_samples)
            ax.set_xlim(t[0], t[-1])
            fig.canvas.draw()
            fig.canvas.flush_events()

# start audio plotting in a background thread
threading.Thread(target=audio_plot, daemon=True).start()

# open and display the MJPEG video stream
cap = cv2.VideoCapture(STREAM_URL)
if not cap.isOpened():
    print(f"Failed to open video stream at {STREAM_URL}")
    exit(1)

while True:
    ret, frame = cap.read()
    if not ret:
        print("Stream ended or cannot fetch frame.")
        break
    cv2.imshow('Video Stream', frame)
    if cv2.waitKey(1) & 0xFF == 27:  # press Esc to exit
        break

cap.release()
cv2.destroyAllWindows()
