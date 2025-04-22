from pythonosc.udp_client import SimpleUDPClient
client = SimpleUDPClient("127.0.0.1", 57120)
client.send_message("/set/sampleRate", 4000)
client.send_message("/set/bitDepth", 8)

