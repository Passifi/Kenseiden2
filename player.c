#define State int
#define Ticks unsigned int
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
