param(
  
  [switch]$NoSound,
  [switch]$Debug

)

if(-not $NoSound) 
{
vasmz80_oldstyle.exe .\sound.z80.asm -Fbin -L .\linkfiles\sound.txt -o sound.bin
}
vasmm68k_mot.exe main.asm -Fbin -ldots -L .\linkfiles\game.txt -o game.bin
#Start-Process game.bin
