from elevenlabs.client import ElevenLabs
from elevenlabs import play

client = ElevenLabs(
    api_key="sk_f86ebb248c652ed221a97cea31aa78cacc1348db67e8617e"
)

audio = client.text_to_speech.convert(
    text="The first move is what sets everything in motion.",
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_v3_alpha",
    output_format="mp3_44100_128",
)

play(audio)