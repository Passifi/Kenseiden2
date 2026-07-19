#include <string.h>
#define State int
#define Ticks unsigned int
#include <stdint.h>
struct AnimationData {
  int maxFrames; 
  Ticks frameLength;
};
struct Animation {
  int dataIndex;
  int currentFrame;
  Ticks timeRemaining;
};
struct Player {
  int x;
  int y;
  int xAccu; 
  int yAccu;
  State playerState; 
  int stateDirty;
  struct Animation* animation; 
};

void animate(struct Animation* animation);

struct AnimationData playerAnimations[16];
void animatePlayer(struct Player* player) {
  if(player->stateDirty) {
    player->animation->timeRemaining = playerAnimations[player->playerState].frameLength;
    player->animation->currentFrame = 0;
    player->animation->dataIndex = player->playerState;
  }
  animate(player->animation);
}

void animate( struct Animation* animation) {
  animation->timeRemaining -= 1;
  if(animation->timeRemaining <= 0) {
    animation->currentFrame++;
    if(animation->currentFrame == playerAnimations[animation->dataIndex].maxFrames) {
      animation->currentFrame =0;
    }
    animation->timeRemaining=playerAnimations[animation->dataIndex].frameLength;
  }
}
#define VDP_BASE 0xff0000
#define sizeOfBlock 32
#define VDP_CTRL_WORD (*(volatile uint16_t*)0xc00004u)
#define VDP_CTRL_LONG (*(volatile uint32_t*)0xc00004u)
#define VDP_DATA (*(volatile uint16_t*)0xc00000u)
void loadSprite(int block, char* sourceAddress, char* scrollPlaneAddress)
{
  setVDPRAMWrite(scrollPlaneAddress,block*sizeOfBlock); 
  for(int i= 0; i < 8;i++) {
    uint16_t value= 0;
    value = ((uint16_t)sourceAddress[0])<<8|(uint16_t)sourceAddress[1];
    VDP_DATA = value;
    sourceAddress+=2;
  }  
}
