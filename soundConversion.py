from mido import MidiFile, merge_tracks
from sys import argv
from math import floor
from queue import Queue
def getPSGVelocity(value):
    return floor((1 - value/127)*15)
def extractTargetName(path):
    return path.split(".")[0] + ".bin"

Note_On = 0x00
Note_Off = 0x01
ChangeVolume = 0x02
ChangePitch = 0x03

class PSGEvent:
   
    def __init__(self,channel, value,time,event,extrValue=0):
        self.eventSwitch = {
            'note_on': self.createNoteOn,
        'note_off': self.createNoteOff,
        'channel_pressure': self.createVolume,
        'pitch_change': self.createPitch

        }
        self.time = time
        if event == "note_on" and extrValue==15:
            event = 'note_off'
        self.eventData = self.convertToPSGEvent(channel,value,event,extrValue)
        self.waitTime = 0

        
    def getPitchValue(self,channel,value):
        bytes = bytearray() 
        firstByte =  (value & 0x0f) | 0x80 | (channel << 5)
        secondByte = (value & 0X3f0)>>4 
        bytes.append(firstByte) 
        bytes.append(secondByte) 
        return bytes
    def getVolumeValue(self,channel,value):
        bytes = bytearray()
        result = 0x90 | (channel<<5) | (value&0x0f) 
        bytes.append(result)
        return bytes
 
    def createNoteOn(self,channel,value,volume):
        bytes = bytearray()
        bytes.append(Note_On)
        bytes += self.getPitchValue(channel,value) 
        bytes += self.getVolumeValue(channel,volume)
        return bytes
    def createNoteOff(self,channel,value):
        bytes = bytearray()
        bytes.append(Note_Off)
        bytes += self.getVolumeValue(channel,0xff)
        return bytes
    def createVolume(self,channel,value):
        bytes = bytearray()
        bytes.append(ChangeVolume)
        bytes += self.getVolumeValue(channel,value)
        return bytes
    def createPitch(self,channel,value):
        bytes = bytearray() 
        bytes.append(ChangePitch)
        bytes += self.getPitchValue(channel,value) 
        return bytes

    def convertToPSGEvent(self,channel,value: int,event, extraValue=0):
        if channel > 3: 
            print("Caution! Maximum Channel number has been exceeded. File is corrupted!")
            exit()
        if(event == "note_on"):
            return self.createNoteOn(channel,value,extraValue)
        else:
            return self.createNoteOff(channel,value)
         
    def calculateWaitTime(self, previous: 'PSGEvent'):
        return self.time - previous.time
    def __str__(self):
        result  = "".join([str(x) for x in self.eventData])
        return f"&{result}, &{self.waitTime:04x}"
if len(argv)< 2:
    print("Please provide a source filename on the command line. Format:\n python soundConversion.py filename")
    filepath = "test.mid"
else:  
    filepath = argv[1]
targetFilepath = filepath.split(".")[0] + ".bin" 
print(targetFilepath)
pitches = [
    851,803,758,715,675,637,601,568,536,506,477,450 
]

pitches += [x>>1 for x in pitches] + [x>>2 for x in pitches]
pitches.append(pitches[0]>>3)
pitchIndex = 0
psg_pitch_table = {
    note: pitch
    for note,pitch in zip(range(48,85),pitches)
}

midiEvents = ['note_on','note_off','pitch_change','channel_pressure']

try: 
    mid = MidiFile(filepath)
except:
    print("File does not exist. Please provide a proper filepath")
    exit()
print(f"Ticks per beat: {mid.ticks_per_beat}")
events = merge_tracks(mid.tracks)
bpm = 120 
quarterLength = bpm/60
ticksPerSecondPerQuarter = mid.ticks_per_beat*quarterLength
ticksPerFrame = ticksPerSecondPerQuarter/60

times = [0 for _ in mid.tracks]
trackEvents = [Queue() for _ in mid.tracks]

for channel,track in enumerate(mid.tracks): 

    psgEvents =  trackEvents[channel]
    for msg in track:
        times[channel] += msg.time 
        if msg.type == 'note_on':
            velocity = getPSGVelocity(msg.velocity) 
            if msg.note in psg_pitch_table:
                current = PSGEvent(channel,msg.note,times[channel],msg.type,velocity)
                if not psgEvents.empty(): 
                    lastElement = psgEvents.queue[0]
                    lastElement.waitTime = int(current.calculateWaitTime(lastElement)/ticksPerFrame)
                psgEvents.put(current)

# interleave tracks 

finalEvents = []
moreToGo = False
while any(not track.empty() for track in trackEvents):
    smallest = 4000000
    candidate =  0
    for i,track in enumerate(trackEvents):
        if not track.empty() and track.queue[0].time < smallest:
            candidate = i 
            smallest = track.queue[0].time
    finalEvents.append(trackEvents[candidate].get())




pgString = ",".join(str(el) for el in finalEvents)

result = "dw " + pgString
print(f"Total Number of Elements: {len(finalEvents)}")
print(result) 
with open(targetFilepath,"wb") as f:
    for el in finalEvents:
        f.write(el.eventData)
        f.write(el.waitTime.to_bytes(2,"little"))