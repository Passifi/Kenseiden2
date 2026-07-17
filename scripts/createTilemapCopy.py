horizontalTiles = 30 
verticalTiles = 32  
startValue = 0xc000
#copyTilemapDynamic 32*2,TilemapData,$C000
for i in range(32):
    value = hex(i*88).replace("0x","$")
    print(f"copyTilemapDynamic 22*2,TilemapData+{22*2*(i)},$C000+{value}")
