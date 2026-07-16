horizontalTiles = 30 
verticalTiles = 32  
startValue = 0xc000
#copyTilemapDynamic 32*2,TilemapData,$C000
for i in range(32):
    value = hex(i*128).replace("0x","$")
    print(f"copyTilemapDynamic 32*2,TilemapData+{32*2*(i)},$C000+{value}")
