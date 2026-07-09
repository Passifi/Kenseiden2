from mido import MidiFile, merge_tracks
from sys import argv

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
        self.startTime = time
        if event == "note_on" and extrValue==15:
            event = 'note_off'
        self.eventData = self.convertToPSGEvent(channel,value,event,extrValue)
        self.waitTime = 0

        
    def getPitchValue(self,channel,value):
        bytes = bytearray() 
        firstByte =  (value & 0x0f) | 0x80 | (channel << 4)
        secondByte = (value & 0X3f0)>>4 
        bytes.append(firstByte) 
        bytes.append(secondByte) 
        return bytes
    def getVolumeValue(self,channel,value):
        bytes = bytearray()
        result = 0x90 | (channel>>5) | (value&0x0f) 
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
        return self.startTime - previous.startTime
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

time = 0 
psgEvents =  []
for msg in events:
    time += msg.time 
    if msg.type == 'note_on':
        velocity = int((1 - msg.velocity/127)*15)
        if msg.note in psg_pitch_table:
            current = PSGEvent(msg.channel,msg.note,time,msg.type,velocity)
            if len(psgEvents) >0: 
                lastElement = psgEvents[-1] 
                lastElement.waitTime = int(current.calculateWaitTime(lastElement)/ticksPerFrame)
            psgEvents.append(current)
    if msg.type == 'note_off':
            current = PSGEvent(msg.channel,msg.note,time,msg.type)
            if len(psgEvents) >0: 
                lastElement = psgEvents[-1] 
                lastElement.waitTime = int(current.calculateWaitTime(lastElement)/ticksPerFrame)
            psgEvents.append(current)

pgString = ",".join(str(el) for el in psgEvents)

result = "dw " + pgString
print(f"Total Number of Elements: {len(psgEvents)}")
print(result) 
with open(targetFilepath,"wb") as f:
    for el in psgEvents:
        f.write(el.eventData)
        f.write(el.waitTime.to_bytes(2,"little"))